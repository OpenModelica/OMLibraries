#!/usr/bin/env python
import io
import os
import requests
import sys
import simplejson
import re
from optparse import OptionParser
from collections import defaultdict
import subprocess
import datetime

_ = lambda *args: args

def targets(r):
  if r.get('targets'):
    return ' '.join(['"%s"' % t for t in r['targets']])
  return "all"
def opts(r):
  if 'options' not in r:
    return ""
  opts = r['options']
  return " ".join(['--%s "%s"' % (key,opts[key]) for key in opts.keys()])

with open("repos.json") as f:
  jsondata = simplejson.load(f)
repos = jsondata['repos']

def updateCommand(r, customBuild=None):
  buildDir = customBuild or options.build
  if r.get('multitarget'):
    dest = 'git/'+r['dest']
    commands = ['sh ./update-library.sh --omc "%s" --build-dir "%s" %s %s "%s" %s "%s" %s' % (options.omc,buildDir,opts(multi),"GIT",r['url'],multi['rev'],dest,targets(multi)) for multi in r['multitarget']]
    cmd = " && ".join(commands)
  else:
    dest = ("git" if r['url'].endswith(".git") else "svn")+'/'+r['dest']
    cmd = 'sh ./update-library.sh --omc "%s" --build-dir "%s" %s %s "%s" %s "%s" %s' % (options.omc,buildDir,opts(r),"GIT" if r['url'].endswith(".git") else "SVN",r['url'],r['rev'],dest,targets(r))
  try:
    os.remove(dest+'.cmd')
  except:
    pass
  return cmd
def makeFileReplayCommand(r):
  return ("git" if r['url'].endswith(".git") else "svn") + "/" + r['dest'] + ".cmd"

def silentSystemOrException(cmd):
  try:
    subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT)
  except subprocess.CalledProcessError as e:
    print("*** Failed %s: %s" % (e.cmd, e.output))
    return True
  return False


def update():
  open("bad-uses.sh", "w").write("#!/bin/sh\nsed -i %s \"$1\"\n" % " ".join(["-e '/%s/d' " % use for use in jsondata['bad-uses']]))

  from joblib import Parallel, delayed
  provides = defaultdict(list)
  for p in jsondata['provided'].keys():
    f = open(options.build + "/%s.provided" % p,'w')
    pack = jsondata['provided'][p]
    f.write(pack)
    provides[pack] += [p]
  for k in provides.keys():
    f = open(options.build + "/%s.provides" % k,'w')
    f.write(','.join([str((subprocess.check_output("sh ./debian-name.sh %s" % item, shell=True)).decode('utf-8')).strip() for item in provides[k]]))
  commands = [updateCommand(r) for r in repos]
  for cmd in commands: print(cmd)
  try:
    os.remove('error.log')
  except OSError:
    pass
  cmdFailed = max(Parallel(n_jobs=n_jobs)(delayed(silentSystemOrException)(cmd) for cmd in commands))
  if cmdFailed:
    return 1

  commands = ['cd "git/%s" && git fetch "%s" && git fetch --tags "%s"' % (r['dest'],r['url'],r['url']) for r in repos if r['url'].endswith('.git')]
  cmdFailed = max(Parallel(n_jobs=n_jobs)(delayed(silentSystemOrException)(cmd) for cmd in commands))

  if cmdFailed:
    return 1
  core_lib=[]
  other_lib=[]
  lines=[]
  phony=".PHONY:"
  for r in sorted(repos,key=lambda r: r['dest']):
    if r.get("core"):
      core_lib.append(r['dest'])
    else:
      other_lib.append(r['dest'])
    phony += " %s" % r['dest']
    lines.append("%s:\n" % r['dest'])
    for line in open(makeFileReplayCommand(r),"r").readlines():
      lines.append("\t%s" % line)
  with open("Makefile.libs","w") as fout:
    fout.write(phony)
    stamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    fout.write("\nCORE_TARGET=$(BUILD_DIR)/%s.core" % stamp)
    fout.write("\nALL_TARGET=$(BUILD_DIR)/%s.all" % stamp)
    fout.write("\nCORE_LIBS=" + " ".join(core_lib))
    fout.write("\nOTHER_LIBS=" + " ".join(other_lib))
    fout.write("\nALL_LIBS=$(CORE_LIBS) $(OTHER_LIBS)\n")
    fout.write("\nTIMESTAMP=%s\n" % stamp)
    fout.writelines(lines)
  return 0

def findPrefix(pre,strs):
  for s in strs:
    if s.startswith(pre):
      return True
  return False

def checkGithub(ghs,urls):
  res = []
  access_token = ""
  for gh in ghs:
    r = requests.get(gh+"&"+access_token)
    if(r.ok):
      for repo in simplejson.loads(r.text or r.content):
        if sum(not (re.search("/%s([.]git)?$" % repo['name'], url) is None) for url in urls):
          continue
        if repo['fork']:
          r = requests.get(repo['url']+"?"+access_token)
          if not r.ok:
            raise Exception("GitHub request failed: "+repo['url'])
          repo = simplejson.loads(r.text or r.content)
        res.append(repo)
    else:
      raise Exception("GitHub request failed %s" % gh)
  return res

def checkLatest(repo, args):
  if args and repo["dest"] not in args:
    return (None,repo)
  msg = None
  if repo['url'].endswith('git'):
    for r in repo['multitarget'] if repo.get('multitarget') else [repo]:
      options = r.get('options') or {}
      if options.get('gittag'):
        continue
      branch = options.get('gitbranch') or 'release'
      oldrev = r['rev']
      newrev = subprocess.check_output('git ls-remote "%s" | grep \'refs/heads/%s$\' | cut -f1' % (repo['url'],branch), shell=True).strip()
      if oldrev == newrev:
        continue
      repo_no_multi = {'url':repo['url'], 'dest':repo['dest'], 'rev':r['rev'], 'options':options, 'targets':r.get('targets') or []}
      r['rev'] = newrev
      if "generate-patch-mos" in options:
        for f in options["patch-files"]:
          if os.path.exists(f+".bak"):
            os.unlink(f+".bak")
          if os.path.exists(f):
            os.rename(f, f+".bak")
      updateOK = False
      print(updateCommand(repo_no_multi))
      if 0 != os.system(updateCommand(repo_no_multi)):
        msg = '%s branch %s has FAILING head - latest is %s' % (repo['url'],branch,newrev)
      elif options.get('automatic-updates') == 'no':
        msg = '%s branch %s has working head %s. It was pinned to the old revision and will not be updated.' % (repo['url'],branch,newrev)
      else:
        if "generate-patch-mos" in options:
          cmd = "%s %s" % (parser_options.omc,options["generate-patch-mos"])
          print("Running command %s" % cmd)
          if 0 == os.system(cmd):
            updateOK = True
            for f in options["patch-files"]:
              if not os.path.exists(f):
                updateOK = False
                msg = "%s branch %s failed to generate new patch %s for %s." % (repo['url'],branch,f,newrev)
            if updateOK == False:
              pass
            elif 0 != os.system(updateCommand(repo_no_multi, customBuild=".customBuild/%s/%s" % (repo['dest'],r['rev']))):
              msg = "%s branch %s failed to run new patches for %s." % (repo['url'],branch,newrev)
              updateOK = False
          else:
            msg = "%s branch %s failed to create new patches for %s." % (repo['url'],branch,newrev)
            print(os.getcwd())
        else:
          updateOK = True
        if updateOK:
          msg = '%s branch %s updated to %s.' % (repo['url'],branch,newrev)

      if not updateOK:
        r['rev'] = oldrev
      if "generate-patch-mos" in options:
        for f in options["patch-files"]:
          if os.path.exists(f+".bak"):
            if updateOK:
              os.unlink(f+".bak")
            else:
              if os.path.exists(f):
                os.rename(f, f+".failed")
              os.rename(f+".bak",f)

      logmsg = ''
      if repo['url'].startswith('https://github.com/') and repo['url'].endswith('.git'):
        commiturl = repo['url'][:-4]
        cmd = 'cd "git/%s" && git fetch "%s" && git log %s..%s -n 15 --pretty=oneline --abbrev-commit | sed "s,^ *\\([a-z0-9]*\\),  * [%s/commit/\\1 \\1],"' % (repo['dest'],repo['url'],oldrev,newrev,commiturl)
        logmsg = subprocess.check_output(cmd, shell=True).strip()
      else:
        logmsg = subprocess.check_output('cd "git/%s" && git log %s..%s -n 15 --pretty=oneline --abbrev-commit | sed "s/^ */  * /"' % (repo['dest'],oldrev,newrev), shell=True).strip()
      logmsg = logmsg.decode('utf-8','ignore')
      msg = msg + "\n  " + logmsg + "\n"
  else:
    options = repo.get('options') or {}
    intertrac = options.get('intertrac') or ''
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
      if 0 != os.system(updateLibraryCmd):
        repo['rev'] = oldrev
        msg = "svn/%s uses %d but %d is available. It FAILED to update using %s" % (repo['dest'],oldrev,newrev,updateLibraryCmd)
      elif options.get('automatic-updates') == 'no':
        repo['rev'] = oldrev
        msg = "svn/%s uses %d but %d is available. It was pinned to the old revision and will not be updated." % (repo['dest'],oldrev,newrev)
      else:
        msg = "svn/%s has been updated to r%d." % (repo['dest'],newrev)
      logmsg = subprocess.check_output('svn log "svn/%s" -l15 -r%d:%d | ./svn-logoneline.sh | sed "s/^/  * %s/"' % (repo['dest'],newrev,oldrev+1,intertrac), shell=True).strip()
      logmsg = logmsg.decode('utf-8','ignore')
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
  parser_options = options
  n_jobs = options.n_jobs
  if options.check_latest:
    # update()
    os.system("rm -r build/")
    from joblib import Parallel, delayed
    res = Parallel(n_jobs=n_jobs)(delayed(checkLatest)(repo, args) for repo in repos)
    # res = [checkLatest(repo) for repo in repos]
    (msgs,repos) = zip(*list(res))
    os.system("rm -f test-valid*.mos")
    jsondata['repos'] = sorted(repos, key=lambda k: k['dest'])
    f = io.open("commit.log","w",encoding='utf-8')
    f.write(u"Bump libraries\n\n")
    for msg in msgs:
      if msg is not None:
        print(msg.encode('utf-8'))
        f.write("- %s\n" % msg)
    urls = [repo['url'] for repo in repos] + jsondata['github-ignore']
    for repo in checkGithub(jsondata['github-repos'],urls): print("Repository not in database: %s" % repo['svn_url'])
    f = open("repos.json","w")
    simplejson.dump(jsondata, f, indent=2, sort_keys=True)
  elif options.add_missing:
    urls = [repo['url'] for repo in repos] + jsondata['github-ignore']
    for repo in checkGithub(jsondata['github-repos'],urls):
      url = repo['clone_url']
      branch = repo['default_branch']
      rev = subprocess.check_output("git ls-remote '%s' refs/heads/%s | cut -f1" % (url,branch), shell=True).strip()
      entry = {'dest':repo['name'],'options':{'gitbranch':branch},'rev':rev,'url':url}
      print("Adding entry",entry)
      jsondata['repos'].append(entry)
    f = open("repos.json","w")
    jsondata['repos'] = sorted(jsondata['repos'], key=lambda k: k['dest'])
    simplejson.dump(jsondata, f, indent=2, sort_keys=True)
  else:
    sys.exit(update())
