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
  echo $LIB
  f1=`find "build/$LIB"*".mo" 2>/dev/null | awk '{print length"\t"$0}' | sort -n | cut -f2- | head -n1`
  f2=`find "build/$LIB"*"/package.mo" 2>/dev/null | awk '{print length"\t"$0}' | sort -n | cut -f2- | head -n1`
  if test -f "$f1"; then    
    ./debian-name.sh `echo $f1 | sed "s,build/\(.*\).mo,\1,"` >> $DEPS
  elif test -f "$f2"; then
    ./debian-name.sh `echo $f2 | sed "s,build/\(.*\)/package.mo,\1,"` >> $DEPS
  else
    echo "Could not find library $LIB, used by $1"
    exit 1
  fi
done
