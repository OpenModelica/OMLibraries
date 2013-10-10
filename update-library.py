#!/usr/bin/env python
import os
import requests
import sys
import simplejson
from optparse import OptionParser
import subprocess

def targets(r):
  if not r.has_key('targets'):
    return "all"
  return ' '.join(['"%s"' % t for t in r['targets']])
def opts(r):
  if not r.has_key('options'):
    return ""
  opts = r['options']
  return " ".join(['--%s "%s"' % (key,opts[key]) for key in opts.keys()])

with open("repos.json") as f:
  jsondata = simplejson.load(f)
repos = jsondata['repos']

def update():
  from joblib import Parallel, delayed
  for p in jsondata['provided']:
    open(options.build + "/%s.provided" % p,'w')
  for k in jsondata['provides'].keys():
    f = open(options.build + "/%s.provides" % k,'w')
    f.write(jsondata['provides'][k])
  commands = [
     'sh ./update-library.sh --omc "%s" --build-dir "%s" %s %s "%s" %s "%s" %s' %
     (options.omc,options.build,opts(r),"GIT" if r['url'].endswith(".git") else "SVN",r['url'],r['rev'],("git" if r['url'].endswith(".git") else "svn")+'/'+r['dest'],targets(r))
     for r in repos
   ]
  for cmd in commands: print cmd
  res = Parallel(n_jobs=n_jobs)(delayed(os.system)(cmd) for cmd in commands)
  exit = 0
  for (i,cmd) in zip(res,commands):
    if i<>0:
      print '*** Failed: %s' % cmd
      exit = 1
  return exit

def findPrefix(pre,strs):
  for s in strs:
    if s.startswith(pre):
      return True
  return False

def checkGithub(ghs,urls):
  res = []
  for gh in ghs:
    r = requests.get(gh)
    if(r.ok):
      for repo in simplejson.loads(r.text or r.content):
        if not findPrefix(repo['svn_url'],urls):
          res.append(repo)
    else:
      raise "GitHub request failed"
  return res

def checkLatest(repo):
  if repo['url'].endswith('git'):
    if repo['options'] is None:
      repo['options'] = {}
    branch = repo['options']['gitbranch']
    if branch is None:
      branch = 'release'
    os.system('cd "git/%s" && git fetch -q && git checkout -q %s' % (repo['dest'],branch))
    os.system('cd "git/%s" && git pull -q' % repo['dest'])
    cnt = int(subprocess.check_output('cd "git/%s" && git rev-list %s..HEAD --count' % (repo['dest'],repo['rev']), shell=True))
    if cnt <> 0:
      rev=subprocess.check_output('cd "git/%s" && git rev-list HEAD -n1' % repo['dest'], shell=True).strip()
      print '%s head is %d behind - latest hash %s' % (repo['dest'],cnt,rev)
  else:
    os.system('./check-latest.sh "svn/%s"' % repo['dest'])
if __name__ == '__main__':
  parser = OptionParser()
  parser.add_option("-n", type="int", help="number of threads", dest="n_jobs", default=1)
  parser.add_option("--check-latest", help="check for latest svn version", action="store_true", dest="check_latest")
  parser.add_option("--add-missing", help="add missing github svn repositories", action="store_true", dest="add_missing")
  parser.add_option("--build-dir", help="directory to put libraries", dest="build", type="string", default="build/")
  parser.add_option("--omc", help="path to the omc executable", dest="omc", type="string", default="omc")
  (options, args) = parser.parse_args()
  n_jobs = options.n_jobs
  if options.check_latest:
    from joblib import Parallel, delayed
    Parallel(n_jobs=n_jobs)(delayed(checkLatest)(repo) for repo in repos)
    urls = [repo['url'] for repo in repos] + jsondata['github-ignore']
    for repo in checkGithub(jsondata['github-repos'],urls): print "Repository not in database: %s" % repo['svn_url']
  elif options.add_missing:
    urls = [repo['url'] for repo in repos] + jsondata['github-ignore']
    for repo in checkGithub(jsondata['github-repos'],urls):
      url = repo['svn_url'] + "/trunk"
      rev = int(subprocess.check_output("svn info --xml '%s' | xpath -q -e '/info/entry/commit/@revision' | grep -o '[0-9]*'" % url, shell=True))
      entry = {'dest':repo['name'],'rev':rev,'url':url}
      print "Adding entry",entry
      jsondata['repos'].append(entry)
    f = open("repos.json","w")
    jsondata['repos'] = sorted(jsondata['repos'], key=lambda k: k['dest']) 
    simplejson.dump(jsondata, f, indent=2, sort_keys=True)
  else:
    sys.exit(update())
