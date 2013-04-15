#!/usr/bin/env python
import os
import requests
import sys
import simplejson
from joblib import Parallel, delayed
from optparse import OptionParser

parser = OptionParser()
parser.add_option("-n", type="int", help="number of threads", dest="n_jobs", default=1)
parser.add_option("--check-latest", help="check for latest svn version", action="store_true", dest="check_latest")
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
  commands = ['./update-library.sh %s SVN "%s" %d "%s" %s' % (opts(r),r['url'],r['rev'],r['dest'],targets(r)) for r in repos]
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

if options.check_latest:
  Parallel(n_jobs=n_jobs)(delayed(os.system)('./check-latest.sh "%s"' % repo['dest']) for repo in repos)
  urls = [repo['url'] for repo in repos] + jsondata['github-ignore']
  for gh in jsondata['github-repos']:
    r = requests.get(gh)
    if(r.ok):
      for repo in simplejson.loads(r.text or r.content):
        if not findPrefix(repo['svn_url'],urls):
          print "Repository not in database: %s" % repo['svn_url']
    else:
      print "GitHub request failed"
else:
  sys.exit(update())
