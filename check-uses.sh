#!/bin/sh

if test $# -ne 2 || ! test -f "$2"; then
  echo "Usage: $0 build/dir path/file.uses"
  exit 1
fi

# Check that all used libraries exist and create a nice debified depends list
BUILD="$1"
DEPS=`echo $2 | sed s/uses/depends/`
rm -f "$DEPS"
for l in `cat "$2" | sed "s/ /%20/g"`; do
  LIB=`echo $l | sed "s/%20/ /g"`
  if echo "$LIB" | grep -q "^deb:"; then # Raw package name
    echo "$LIB" | sed "s/^deb://" >> $DEPS
  elif test -f "$BUILD/$LIB.license"; then
    ./debian-name.sh `echo "$LIB"` >> $DEPS
  elif test -f "$BUILD/$LIB.provided"; then
    ./debian-name.sh `echo "$LIB"` >> $DEPS
  else
    echo "Could not find library $LIB, used by $1"
    exit 1
  fi
done
