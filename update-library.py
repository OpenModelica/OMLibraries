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

def updateCommand(r):
  return 'sh ./update-library.sh --omc "%s" --build-dir "%s" %s %s "%s" %s "%s" %s' % (options.omc,options.build,opts(r),"GIT" if r['url'].endswith(".git") else "SVN",r['url'],r['rev'],("git" if r['url'].endswith(".git") else "svn")+'/'+r['dest'],targets(r))
def update():
  from joblib import Parallel, delayed
  for p in jsondata['provided']:
    open(options.build + "/%s.provided" % p,'w')
  for k in jsondata['provides'].keys():
    f = open(options.build + "/%s.provides" % k,'w')
    f.write(jsondata['provides'][k])
  commands = [updateCommand(r) for r in repos]
  for cmd in commands: print cmd
  try:
    os.remove('error.log')
  except OSError:
    pass
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
  msg = None
  if repo['url'].endswith('git'):
    if repo['options'] is None:
      repo['options'] = {}
    branch = repo['options']['gitbranch']
    if branch is None:
      branch = 'release'
    oldrev = repo['rev']
    newrev = subprocess.check_output('git ls-remote "%s" | grep "refs/heads/%s" | cut -f1' % (repo['url'],branch), shell=True).strip()
    if oldrev <> newrev:
      repo['rev'] = newrev
      if 0<>os.system(updateCommand(repo)):
        repo['rev'] = oldrev
        msg = '%s branch %s has FAILING head - latest is %s' % (repo['url'],branch,newrev)
      elif repo.has_key('options') and repo['options'].has_key('automatic-updates') and repo['options']['automatic-updates'] == 'no':
        repo['rev'] = oldrev
        msg = '%s branch %s has working head %s. It was pinned to the old revision and will not be updated.' % (repo['url'],branch,newrev)
      else:
        msg = '%s branch %s updated to %s.' % (repo['url'],branch,newrev)
      logmsg = ''
      if repo['url'].startswith('https://github.com/') and repo['url'].endswith('.git'):
        commiturl = repo['url'][:-4]
        logmsg = subprocess.check_output('cd "git/%s" && git log %s..%s -n 15 --pretty=oneline --abbrev-commit | sed "s,^ *\\([a-z0-9]*\\),  * [%s/\\1 \\1],"' % (repo['dest'],oldrev,newrev,commiturl), shell=True).strip()
      else:
        logmsg = subprocess.check_output('cd "git/%s" && git log %s..%s -n 15 --pretty=oneline --abbrev-commit | sed "s/^ */  * /"' % (repo['dest'],oldrev,newrev), shell=True).strip()
      msg = msg + "\n  " + logmsg + "\n"
  else:
    svncmd = "svn --non-interactive --username anonymous"
    # remoteurl = subprocess.check_output('%s info --xml "svn/%s" | xpath -q -e "/info/entry/repository/root/text()"' % (svncmd,repo['dest']), shell=True).strip()
    remoteurl = repo['url']
    oldrev = int(repo['rev'])
    newrev = int(subprocess.check_output('%s info --xml "%s" | xpath -q -e "/info/entry/commit/@revision" | grep -o "[0-9]*"' % (svncmd,remoteurl), shell=True))
    repo['rev'] = newrev
    if oldrev < newrev:
      #changesCmd = '%s log -qv -r%s:%s %s | egrep -o "(/(tags|branches)/[^/]*/|/trunk/)" | sed "s, (from /,/," | sort -u' % (svncmd,oldrev,newrev,remoteurl)
      #changes = subprocess.check_output(changesCmd, shell=True).strip()
      updateLibraryCmd = updateCommand(repo)
      if 0<>os.system(updateLibraryCmd):
        repo['rev'] = oldrev
        msg = "svn/%s uses %d but %d is available. It FAILED to update using %s" % (repo['dest'],oldrev,newrev,updateLibraryCmd)
      elif repo.has_key('options') and repo['options'].has_key('automatic-updates') and repo['options']['automatic-updates'] == 'no':
        repo['rev'] = oldrev
        msg = "svn/%s uses %d but %d is available. It was pinned to the old revision and will not be updated." % (repo['dest'],oldrev,newrev)
      else:
        msg = "svn/%s uses %d but %d is available. It has been updated." % (repo['dest'],oldrev,newrev)
      logmsg = subprocess.check_output('svn log "svn/%s" -l15 -r%d:%d | ./svn-logoneline.sh | sed "s/^/  * /' % (repo['dest'],oldrev,newrev), shell=True).strip()
      msg = msg + "\n  " + logmsg + "\n"
  return (msg,repo)
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
    (msgs,repos) = zip(*list(Parallel(n_jobs=n_jobs)(delayed(checkLatest)(repo) for repo in repos)))
    os.system("rm -f test-valid*.mos")
    jsondata['repos'] = sorted(repos, key=lambda k: k['dest']) 
    f = open("commit.log","w")
    f.write("Bump libraries\n")
    for msg in msgs:
      if msg is not None:
        print msg
        f.write("- %s\n" % msg)
    urls = [repo['url'] for repo in repos] + jsondata['github-ignore']
    for repo in checkGithub(jsondata['github-repos'],urls): print "Repository not in database: %s" % repo['svn_url']
    f = open("repos.json","w")
    simplejson.dump(jsondata, f, indent=2, sort_keys=True)
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
