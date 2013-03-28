#!/bin/sh

if test $# -ne 1 || ! test -f "$1"; then
  echo "Usage: $0 path/file.uses"
  exit 1
fi

# Check that all used libraries exist
for l in `cat "$1" | sed "s/ /%20/g"`; do
  LIB=`echo $l | sed "s/%20/ /g"`
  if ! (test -f "build/$LIB"*".mo" || test -f "build/$LIB"*"/package.mo"); then
    echo "Could not find library $LIB, used by $1"
    exit 1
  fi
done
