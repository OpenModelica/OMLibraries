#!/bin/sh
BUILD=build/

ENCODING=UTF-8
STD=3.3
LICENSE=modelica2
SVNOPTS="--non-interactive --username anonymous"
OMC=omc
OMC_PARAMS="+n=1"
GITBRANCH=release
while echo $1 | grep -q "^--"; do
OPT="$1"
shift
case $OPT in
--omc)
  OMC="$1"
  shift
  ;;
--build-dir)
  BUILD="$1"
  shift
  ;;
--encoding)
  ENCODING="$1"
  shift
  ;;
--std)
  STD="$1"
  shift
  ;;
--license)
  LICENSE="$1"
  shift
  ;;
--breaks)
  BREAKS="$1"
  shift
  ;;
--patchlevel)
  PATCHLEVEL="$1"
  shift
  ;;
--gitbranch)
  GITBRANCH="$1"
  shift
  ;;
--gittag)
  GITBRANCH="$1"
  shift
  ;;
--no-package)
  # $1 will be a comment
  NOPACKAGE="$1"
  shift
  ;;
--no-dependencies)
  NO_DEPENDENCY="$1"
  shift
  ;;
--remove-files)
  # Files that should be stripped from the package. Usually redundant binaries.
  REMOVE_FILES="$1"
  shift
  ;;
--automatic-updates)
  # Skip this; used in the python script
  shift
  ;;
--intertrac)
  # Skip this; used in the python script
  shift
  ;;
*)
  echo "Unknown option $OPT"
  exit 1
  ;;
esac

done

if test $# -lt 5 || !(test "$1" = SVN || test "$1" = GIT); then
  echo "Usage: $0 [flags] [SVN|GIT] URL REVISION DEST [LIBRARIES]"
  echo "   --encoding=[UTF-8]"
  echo "   --std=[3.3]"
  exit 1
fi
TYPE="$1"
URL="$2"
REVISION="$3"
DEST="$4"
shift;shift;shift;shift

CMD_REPLAY="$DEST.cmd"
echo "# Building $DEST" >> "$CMD_REPLAY"

if test "$TYPE" = SVN; then

  ./checkout-svn.sh "$DEST" "$URL" "$REVISION" || exit 1
  echo "./checkout-svn.sh '$DEST' '$URL' '$REVISION'" >> "$CMD_REPLAY"

elif test "$TYPE" = GIT; then

  ./checkout-git.sh "$DEST" "$URL" "$GITBRANCH" "$REVISION" || exit 1
  echo "./checkout-git.sh '$DEST' '$URL' '$GITBRANCH' '$REVISION'" >> "$CMD_REPLAY"

else
  echo "Unknown repository type: $TYPE" >&2
  exit 1
fi

mkdir -p "$BUILD"
if test "$*" = "all"; then
 shift
 CURWD=`pwd`
 cd "$DEST"
 for f in *.mo */package.mo; do
   if test "$f" != "package.mo"; then
     LIBS="$LIBS `echo $f | grep -v "[*]" | sed "s/ /%20/g" | sed "s,/package.mo,," | sed "s,.mo$,,"`"
   fi
 done
 cd "$CURWD"
elif test "$*" = "none"; then
 shift
fi
echo $LIBS
for f in $LIBS "$@"; do
  if test "$f" = "self"; then
    LIB=`./get-name.sh "$OMC" "$DEST/package.mo" "$ENCODING" "$STD"`
    VER=""
    if test -z "$LIB"; then
      echo "*** Error: Failed to read package name from $DEST/package.mo"
      exit 1
    fi
  else
    LIB=`echo $f | sed "s/%20/ /g" | cut -d" " -f1`
    VER=`echo $f | sed "s/%20/ /g" | grep " " | cut -d" " -f2-`
    echo Copy library [$LIB] version [$VER] from `pwd`
  fi
  if test "$f" = "self"; then
    SOURCE="$DEST"
    MOFILE="$DEST/package.mo"
    EXT=""
  elif [ ! -z "$VER" ] && [ -d "$DEST/$LIB $VER" ]; then
    SOURCE="$DEST/$LIB $VER"
    EXT=""
  elif [ ! -z "$VER" ] && [ -f "$DEST/$LIB $VER.mo" ]; then
    SOURCE="$DEST/$LIB $VER.mo"
    EXT=".mo"
  elif test -d "$DEST/$LIB"; then
    SOURCE="$DEST/$LIB"
    MOFILE="$DEST/$LIB/package.mo"
    EXT=""
  elif test -f "$DEST/$LIB.mo"; then
    SOURCE="$DEST/$LIB.mo"
    MOFILE="$SOURCE"
    EXT=".mo"
  else
    echo "Did not find library $DEST/$LIB :("
    exit 1
  fi
  if test -z "$VER"; then
    VER=`./get-version.sh "$OMC" "$BUILD" "$MOFILE" "$LIB" "$ENCODING" "$STD"`
    echo "Got version $VER for $LIB"
    if test -z "$VER"; then
      NAME="$LIB"
    else
      NAME="$LIB $VER"
    fi
  elif test "$VER" = "none"; then
    NAME="$LIB"
  else
    NAME="$LIB $VER"
  fi

  if test -z "$EXT"; then
    echo "test ! -d '$BUILD/$NAME'" >> "$CMD_REPLAY"
    if test -d "$BUILD/$NAME"; then
      echo "$BUILD/$NAME already exists; bailing out (multiple repositories could try creating the same library)"
      exit 1
    fi
  else
    echo "test ! -f '$BUILD/$NAME$EXT'" >> "$CMD_REPLAY"
    if test -f "$BUILD/$NAME$EXT"; then
      echo "$BUILD/$NAME$EXT already exists; bailing out (multiple repositories could try creating the same library)"
      exit 1
    fi
  fi
  rm -rf "$BUILD/$NAME" "$BUILD/$NAME.mo"
  # Link recursive... Fast, efficient
  echo Copy: cp -a "$SOURCE" "$BUILD/$NAME$EXT"
  cp -a "$SOURCE" "$BUILD/$NAME$EXT"
  echo "cp -a '$SOURCE' \"\$(BUILD_DIR)/$NAME$EXT\"" >> "$CMD_REPLAY"
  for FILES in $REMOVE_FILES; do
    echo Removing files: [$BUILD/$NAME$EXT/$FILES]
    # Need to check if the file exists, because OSX fails on /path/to/file/Dir
    if test -e "$BUILD/$NAME$EXT/$FILES"; then
      rm -rf "$BUILD/$NAME$EXT/$FILES"
      echo "rm -rf \"\$(BUILD_DIR)/$NAME$EXT/$FILES\"" >> "$CMD_REPLAY"
    fi
  done
  if test -f "$NAME.patch"; then
    echo "patch -d \"\$(BUILD_DIR)/\" -f -p1 < '$NAME.patch'" >> "$CMD_REPLAY"
    if ! patch -d "$BUILD/" -f -p1 < "$NAME.patch"; then
      echo "Failed to apply $NAME.patch"
      exit 1
    fi
    echo "Applied $NAME.patch"
    PATCHREV=`git rev-list HEAD --count "$NAME.patch" 2>/dev/null`
    if test -z "$PATCHREV"; then
      echo "Not a git repository. We need it to give patch revisions."
      exit 1
    fi
    PATCHREV=`echo -om$PATCHREV`
  else
    PATCHREV=""
  fi

  if echo "$NO_DEPENDENCY" | grep -q "^$LIB\$"; then
    # Avoid cyclic dependencies
    echo > "$BUILD/$NAME.uses"
    echo "echo > \"\$(BUILD_DIR)/$NAME.uses\"" >> "$CMD_REPLAY"
  else
    # Do this a second time after patching for updated uses-annotations... Yes, a bit weird
    if test -d "$BUILD/$NAME$EXT"; then
      ./get-version.sh "$OMC" "$BUILD" "$BUILD/$NAME$EXT/package.mo" "$LIB" "$ENCODING" "$STD"
    else
      ./get-version.sh "$OMC" "$BUILD" "$BUILD/$NAME$EXT" "$LIB" "$ENCODING" "$STD"
    fi

    test -f "$BUILD/$NAME.uses" || touch "$BUILD/$NAME.uses"
    bash bad-uses.sh "$BUILD/$NAME.uses"
    HAS_USES_LINE=0
    while read line
    do
      echo "echo '$line' >> \"\$(BUILD_DIR)/$NAME.uses\"" >> "$CMD_REPLAY"
      HAS_USES_LINE=1
    done < "$BUILD/$NAME.uses"
    if test "$HAS_USES_LINE" = 0; then
      echo "echo '' > \"\$(BUILD_DIR)/$NAME.uses\"" >> "$CMD_REPLAY"
    fi
  fi
  # Add custom patch levels
  if echo "$PATCHLEVEL" | grep -q ":"; then
    PATCHLEVELTHIS=`echo "$PATCHLEVEL" | grep -o "$LIB:[A-Za-z0-9_-]*" | cut -d: -f2`
  else
    PATCHLEVELTHIS="$PATCHLEVEL"
  fi
  if test ! -z "$PATCHLEVELTHIS"; then
    PATCHREV="$PATCHLEVELTHIS"
  fi
  echo $LICENSE > "$BUILD/$NAME.license"
  echo "echo '$LICENSE' > \"\$(BUILD_DIR)/$NAME.license\"" >> "$CMD_REPLAY"
  if test "$TYPE" = SVN; then
    CHANGED=`svn info $SVNOPTS --xml "$SOURCE" | xpath -q -e '/info/entry/commit/@revision' | grep -o "[0-9]*"`
    echo $CHANGED$PATCHREV > "$BUILD/$NAME.last_change"
    echo "echo '$CHANGED$PATCHREV' > \"\$(BUILD_DIR)/$NAME.last_change\"" >> "$CMD_REPLAY"
    # Skipping changelog. Was only used for debian packages, but it is not that useful and quite slow
    # svn log --xml --verbose "$SOURCE" | sed "s,<date>.*</date>,<date>1970-01-01</date>," | sed "s,<author>\(.*\)</author>,<author>none</author><author-svn>\1</author-svn>," | xsltproc svn2cl.xsl - > "$BUILD/$NAME.changes"
  else
    # CHANGED=`cd "$DEST" && git show -s --format="%ad" --date="iso" "$REVISION" | tr -d -- - | cut "-d " -f1-2 | tr -d : | tr " " -`
    if test ! -z "$VER"; then
      CHANGED=`cd "$DEST" && git describe --match "v$VER*" 2>/dev/null || git describe --tags --match "v$VER*" 2>/dev/null`
    fi
    if test -z "$CHANGED"; then
      CHANGED=`cd "$DEST" && git show -s --format="%ad" --date="iso" "$REVISION" | tr -d -- - | cut "-d " -f1-2`
      if test -z "$VER" || echo $VER | sed s,^v,, | grep -q [^0-9.]; then
        CHANGED="$CHANGED~git~$GITBRANCH"
      else
        CHANGED="$VER-$CHANGED~git~$GITBRANCH"
      fi
    fi
    CHANGED=`echo $CHANGED | tr -d : | tr " /" "--" | sed s,^v,,`
    CHANGED="$CHANGED$PATCHREV"
    echo "$CHANGED" > "$BUILD/$NAME.last_change"
    echo "echo '$CHANGED' > \"\$(BUILD_DIR)/$NAME.last_change\"" >> "$CMD_REPLAY"
    cat "$BUILD/$NAME.last_change"

    # Fix svn $Id::
    if test -d "$BUILD/$NAME$EXT"; then
      TOPLEVEL_FILE="$BUILD/$NAME$EXT/package.mo"
      TOPLEVEL_FILE_MAKEFILE="\$(BUILD_DIR)/$NAME$EXT/package.mo"
    else
      TOPLEVEL_FILE="$BUILD/$NAME$EXT"
      TOPLEVEL_FILE_MAKEFILE="\$(BUILD_DIR)/$NAME$EXT"
    fi
    # Skip fixing it. It makes the test suite harder to maintain, for very little gain
    if false && grep -q 'revisionId *= *"$Id:: *$"' "$TOPLEVEL_FILE"; then
      # sed -i on OSX requires the suffix
      REPLACE_CMD="s/revisionId *= *\"$Id:: *\$\"/revisionId = \"$CHANGED\"/"
      sed -i= "$REPLACE_CMD" "$TOPLEVEL_FILE" || exit 1
      echo "sed -i= '$REPLACE_CMD' \"$TOPLEVEL_FILE_MAKEFILE\"" >> "$CMD_REPLAY"
    fi
  fi

  if ! test -z "$BREAKS"; then
    echo "$BREAKS" > "$BUILD/$NAME.breaks"
    echo "echo '$BREAKS' > \"\$(BUILD_DIR)/$NAME.breaks\"" >> "$CMD_REPLAY"
  fi
  if ! test -z "$NOPACKAGE"; then
    echo "$NOPACKAGE" > "$BUILD/$NAME.nopackage"
    echo "echo '$NOPACKAGE' > \"\$(BUILD_DIR)/$NAME.nopackage\"" >> "$CMD_REPLAY"
  fi

  if test -e "$BUILD/$NAME$EXT/.svn"; then
    rm -rf "$BUILD/$NAME$EXT/.svn"
    echo "rm -rf \"\$(BUILD_DIR)/$NAME$EXT/.svn\"" >> "$CMD_REPLAY"
  elif test -e "$BUILD/$NAME$EXT/.git"; then
    rm -rf "$BUILD/$NAME$EXT/.git"*
    echo "rm -rf \"\$(BUILD_DIR)/$NAME$EXT/.git\"*" >> "$CMD_REPLAY"
  fi

  if ! test "$STD" = "3.3"; then
    echo "$STD" > "$BUILD/$NAME.std"
  fi
  if ! test "$ENCODING" = "UTF-8"; then
    echo "$ENCODING" > "$BUILD/$NAME/package.encoding"
    echo "echo '$ENCODING' > \"\$(BUILD_DIR)/$NAME/package.encoding\"" >> "$CMD_REPLAY"
  fi
  echo $URL > "$BUILD/$NAME.url"
  if test -d "$BUILD/$NAME$EXT"; then
    LIBTOTEST="$BUILD/$NAME$EXT/package.mo"
  else
    LIBTOTEST="$BUILD/$NAME$EXT"
  fi
  ./test-valid.sh "$OMC" "$BUILD" "$LIBTOTEST" || exit 1
done
