#!/bin/bash

FILES=library-files
SOURCES=library-sources
rm -f "$FILES" "$SOURCES"
for f in build/*.last_change; do
  LIB=`echo $f | sed s/.last_change// | sed s,build/,,`
    NAME=`./debian-name.sh $LIB`
  REV=`cat "$f"`
  SRC=`echo ${NAME}_$REV-1.dsc`
  DEB=`echo ${NAME}_$REV-1_all.deb`
  if ! (test -f "debian-build/$DEB" && test -f "debian-build/$SRC"); then
    echo "Error: Could not find $DEB and $SRC"
  fi
  echo $DEB >> "$FILES"
  echo $SRC >> "$SOURCES"
done
echo "Created $FILES and $SOURCES"
