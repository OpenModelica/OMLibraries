#!/bin/sh

LIB=`echo $1 | sed "s,build/*\(.*\).ok,\1,"`
VERSION=`echo $LIB | grep " " | cut -d" " -f2-`
LIB=`echo $LIB | cut -d" " -f1`
NAME="$LIB`test -z "$VERSION" || echo " "`$VERSION"
LICENSE=`cat "build/$NAME.license"`
if test -f "build/$NAME.mo"; then
  EXT=".mo"
fi
DEBNAME=`./debian-name.sh "$LIB" $VERSION`
DEBREV=`cat "build/$NAME.last_change"`
FULLNAME="${DEBNAME}_${DEBREV}"
DIR="debian-build/$FULLNAME"
DEBIAN="$DIR/debian/"
DEPENDS=`test -f "build/$NAME.depends" && cat "build/$NAME.depends"`
ORIGURL=`cat "build/$NAME.url"`
if test -f "build/$NAME.breaks"; then
  BREAKS=`cat "build/$NAME.breaks"`
  BREAKCMD="s/@BREAKS@/Breaks: ${BREAKS}/"
else
  BREAKCMD="/@BREAKS@/d"
fi
if test -f "build/$NAME.provides"; then
  PROVIDES=`cat "build/$NAME.provides"`
  PROVIDESCMD="s/@PROVIDES@/Provides: ${PROVIDES}/"
else
  PROVIDESCMD="/@PROVIDES@/d"
fi

