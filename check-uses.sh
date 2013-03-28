#!/bin/sh

if test $# -ne 1 || ! test -f "$1"; then
  echo "Usage: $0 path/file.uses"
  exit 1
fi

# Check that all used libraries exist and create a nice debified depends list
DEPS=`echo $1 | sed s/uses/depends/`
rm -f "$DEPS"
for l in `cat "$1" | sed "s/ /%20/g"`; do
  LIB=`echo $l | sed "s/%20/ /g"`
  if test -f "build/$LIB"*".mo"; then
    f=`echo "build/$LIB"*".mo"`
    ./debian-name.sh `echo $f | sed "s,build/\(.*\).mo,\1,"` >> $DEPS
  elif test -f "build/$LIB"*"/package.mo"; then
    f=`echo "build/$LIB"*"/package.mo"`
    ./debian-name.sh `echo $f | sed "s,build/\(.*\)/package.mo,\1,"` >> $DEPS
  else
    echo "Could not find library $LIB, used by $1"
    exit 1
  fi
done
