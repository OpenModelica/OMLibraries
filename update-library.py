#!/usr/bin/env python
import os
import sys
import simplejson
from joblib import Parallel, delayed
from optparse import OptionParser

parser = OptionParser()
parser.add_option("-n", type="int", help="number of threads", dest="n_jobs", default=1)
(options, args) = parser.parse_args()
n_jobs = options.n_jobs

print options
print args

with open("repos.json") as f:
  jsondata = simplejson.load(f)
repos = jsondata['repos']
for p in jsondata['provided']:
  open("build/%s.provided" % p,'w')

def targets(r):
  if not r.has_key('targets'):
    return "all"
  return ' '.join(['"%s"' % t for t in r['targets']])
def opts(r):
  if not r.has_key('options'):
    return ""
  opts = r['options']
  return " ".join(['--%s "%s"' % (key,opts[key]) for key in opts.keys()])
    
commands = ['./update-library.sh %s SVN "%s" %d "%s" %s' % (opts(r),r['url'],r['rev'],r['dest'],targets(r)) for r in repos]
for cmd in commands: print cmd
res = Parallel(n_jobs=n_jobs)(delayed(os.system)(cmd) for cmd in commands)
for (i,cmd) in zip(res,commands):
  if i<>0:
    print '*** Failed: %s' % cmd
sys.exit(max(res))
