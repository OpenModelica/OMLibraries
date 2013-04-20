#!/bin/bash

SVNOPTS="--non-interactive --username anonymous"
ROOT=`svn info $SVNOPTS --xml "$1" | xpath -q -e '/info/entry/repository/root/text()'`
URL=`svn info $SVNOPTS --xml "$1" | xpath -q -e '/info/entry/url/text()'`
# The following is not used because it only checks the revision of the checked out version - we want the repository revision...
# `svn info $SVNOPTS --xml "$1" | xpath -q -e '/info/entry/commit/@revision' | grep -o "[0-9]*"`
CURREV=`cat "$1.rev"`

if svn info $SVNOPTS --xml "$ROOT" >& /dev/null; then
  URL=$ROOT
fi

REMOTEREV=`svn info $SVNOPTS --xml "$URL" | xpath -q -e '/info/entry/commit/@revision' | grep -o "[0-9]*"`
if test "$CURREV" != "$REMOTEREV"; then
  echo $1 uses $CURREV but $REMOTEREV is available. Changed paths include `svn log -qv -r$CURREV:$REMOTEREV $URL | egrep -o "(/(tags|branches)/[^/]*/|/trunk/)" | sed "s, (from /,/," | sort -u`
fi
