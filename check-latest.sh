#!/bin/bash

URL=`svn info --xml "$1" | xpath -q -e '/info/entry/url/text()'`
CURREV=`svn info --xml "$1" | xpath -q -e '/info/entry/commit/@revision' | grep -o "[0-9]*"`
REMOTEREV=`svn info --xml "$URL" | xpath -q -e '/info/entry/commit/@revision' | grep -o "[0-9]*"`
if test "$CURREV" != "$REMOTEREV"; then
  echo $1 uses $CURREV but $REMOTEREV is available
fi
