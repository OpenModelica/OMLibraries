#!/bin/sh

. ./build-common.sh
DEPENDS=`for f in $DEPENDS; do echo -n "port:$f "; done`

mkdir -p macports-build
cd macports-build

PORTFILE=../macports/lang/$DEBNAME/Portfile

if test -f "$PORTFILE" && grep -q "^version *$DEBREV"; then
  echo Up-to-date: $FULLNAME
  exit 0
fi

SOURCETARBALL=$FULLNAME.orig.tar.gz
if test ! -f $FULLNAME.orig.tar.gz; then
  wget -nv "https://build.openmodelica.org/apt/pool/libraries/$SOURCETARBALL" || exit 1
fi

MD5=`openssl md5 $SOURCETARBALL | cut -d \  -f 2`
SHA1=`openssl sha1 $SOURCETARBALL | cut -d \  -f 2`
RMD160=`openssl rmd160 $SOURCETARBALL | cut -d \  -f 2`

mkdir -p `dirname "$PORTFILE"`
SOURCE_ESCAPED=`echo $NAME$EXT | tr " " "*"`

cat ../templates/macports/Portfile.omlib.in \
  | sed "s,@URL@,$ORIGURL," \
  | sed "s,@MD5@,$MD5," \
  | sed "s,@SHA1@,$SHA1," \
  | sed "s,@RMD160@,$RMD160," \
  | sed "s,@LICENSE@,$LICENSE," \
  | sed "s,@REV@,$DEBREV," \
  | sed "s,@NAME@,$DEBNAME," \
  | sed "s,@SOURCE@,$SOURCE_ESCAPED," \
  | sed "s,@DEPENDS@,$DEPENDS," \
  > $PORTFILE
