#!/bin/sh

ENCODING=UTF-8
while echo $1 | grep "^--"; do
OPT="$1"
shift
case $OPT in
--encoding)
  ENCODING=$1
  shift
  ;;
*)
  echo "Unknown option $OPT"
  exit 1
  ;;
esac

done

if test $# -lt 5 || !(test "$1" = SVN || test "$1" = GIT); then
  echo "Usage: $0 [SVN|GIT] URL REVISION DEST [LIBRARIES]"
fi
TYPE="$1"
URL="$2"
REVISION="$3"
DEST="$4"
shift;shift;shift;shift

if test "$TYPE" = SVN; then

if ! test -d "$DEST"; then
  svn co "-r$REVISION" "$URL" "$DEST" || exit 1
  echo "$REVISION" > "$DEST.rev"
elif test -d "$DEST" && ! test "$URL" = "`svn info "$DEST" | grep ^URL: | sed "s/URL: //"`"; then
  echo "Not same URL... $URL and `svn info "$DEST" | grep ^URL: | sed "s/URL: //"`"
  rm -rf "$DEST"
  svn co "-r$REVISION" "$URL" "$DEST" || exit 1
  echo "$REVISION" > "$DEST.rev"
elif ! test `cat "$DEST.rev"` = $REVISION; then
  svn up "-r$REVISION" "$DEST" || exit 1
  echo "$REVISION" > "$DEST.rev"
else
  echo "$DEST is up to date"
fi

else # GIT
  exit 1
fi

mkdir -p build/
while test $# -gt 0; do
  LIB=`echo $1 | cut -d" " -f1`
  VER=`echo $1 | cut -d" " -f2`
  test -z "$VER" || VERSPACE=" $VER"
  NAME="$LIB$VERSPACE"
  shift
  rm -rf "build/$NAME" "build/$NAME.mo"
  echo Copy library $LIB version $VER
  if test -d "$DEST/$LIB $VER"; then
    cp -rp "$DEST/$LIB $VER" "build/$NAME" || exit 1
  elif test -f "$DEST/$LIB $VER.mo"; then
    cp -p "$DEST/$LIB $VER.mo" "build/$NAME.mo" || exit 1
  elif test -d "$DEST/$LIB"; then
    cp -rp "$DEST/$LIB" "build/$NAME" || exit 1
  elif test -f "$DEST/$LIB.mo"; then
    cp -p "$DEST/$LIB.mo" "build/$NAME.mo" || exit 1
  else
    echo "Did not find library $DEST/$LIB"
    exit 1
  fi
  if test -f "$NAME.patch"; then
    if ! patch -d build/ -p1 < "$NAME.patch"; then
      echo "Failed to apply $NAME.patch"
      exit 1
    fi
    echo "Applied $NAME.patch"
  fi
  if ! test "$ENCODING" = "UTF-8"; then
    echo "$ENCODING" > "build/$NAME/package.encoding"
  fi
done
