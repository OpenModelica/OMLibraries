#!/bin/bash

FILES=nightly-library-files
SOURCES=nightly-library-sources
rm -f "$FILES" "$SOURCES"
for f in build/*.last_change; do
  if test -f "`echo $f | sed s/last_change/nopackage/`"; then
    continue
  fi
  LIB=`echo $f | sed s/.last_change// | sed s,build/,,`
  NAME=`./debian-name.sh $LIB`
  REV=`cat "$f"`
  SRC=`echo ${NAME}_$REV-1.dsc`
  DEB=`echo ${NAME}_$REV-1_all.deb`
  if grep -q "$DEB" ".remote/nightly-library-files" && grep -q "$SRC" ".remote/nightly-library-sources"; then
    true
  elif ! (test -f "debian-build/$DEB" && test -f "debian-build/$SRC"); then
    echo "Error: Could not find $DEB and $SRC"
    exit 1
  fi
  echo $DEB >> "$FILES"
  echo $SRC >> "$SOURCES"
done
echo "Created $FILES and $SOURCES"
