#!/usr/bin/env python
import os
import requests
import sys
import simplejson
from joblib import Parallel, delayed
from optparse import OptionParser
import subprocess

parser = OptionParser()
parser.add_option("-n", type="int", help="number of threads", dest="n_jobs", default=1)
parser.add_option("--check-latest", help="check for latest svn version", action="store_true", dest="check_latest")
parser.add_option("--add-missing", help="add missing github svn repositories", action="store_true", dest="add_missing")
(options, args) = parser.parse_args()
n_jobs = options.n_jobs

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
  for p in jsondata['provided']:
    open("build/%s.provided" % p,'w')
  for k in jsondata['provides'].keys():
    f = open("build/%s.provides" % k,'w')
    f.write(jsondata['provides'][k])
  commands = ['./update-library.sh %s SVN "%s" %d "svn/%s" %s' % (opts(r),r['url'],r['rev'],r['dest'],targets(r)) for r in repos]
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

if options.check_latest:
  Parallel(n_jobs=n_jobs)(delayed(os.system)('./check-latest.sh "svn/%s"' % repo['dest']) for repo in repos)
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
  simplejson.dump(jsondata, f, indent=2, sort_keys=True)
else:
  sys.exit(update())
