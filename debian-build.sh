#!/bin/sh

if test $# -ne 1 || ! test -f "$1"; then
  echo "Error: *** Usage: $0 path/file.mo"
  exit 1
fi

mkdir -p debian-build
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
DEPENDS=`for f in $DEPENDS; do echo -n $f,; done`
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
if grep -q "$FULLNAME-1_all.deb" .remote/nightly-library-files; then
  echo "$FULLNAME-1_all.deb already built - skipping"
  exit 0
fi
echo "Build debian package for $LIB of version $VERSION"
echo "Debian package will be named $DEBNAME with revision $DEBREV"
echo "$DEBNAME has dependencies $DEPENDS"
rm -rf "$DIR" "$DIR.*" "$DIR-*"
mkdir -p "$DIR"
if ! cp -r "build/$NAME$EXT" "$DIR/"; then
  echo "Error: *** Failed to copy build/$NAME$EXT to $DIR/"
  exit 1
fi
sed "s/@EXT@/$EXT/" "templates/debian/Makefile" | sed "s/@NAME@/$NAME/" > "$DIR/Makefile"
if ! (cd "debian-build" && tar czf "$FULLNAME.orig.tar.gz" "$FULLNAME"); then
  echo "Error: *** Failed to create original tarball $FULLNAME.orig.tar.gz"
  exit 1
fi
#(cd "$DIR" && dh_make -p "$FULLNAME" --createorig --packageclass=i) || exit 1
mkdir -p "$DEBIAN"
echo "$DEBNAME has license $LICENSE"
cp "templates/debian/copyright.$LICENSE" "$DEBIAN/copyright"
cp "templates/debian/rules" "$DEBIAN/rules"
echo 8 > "$DEBIAN/compat"
sed "s/@DEBNAME@/$DEBNAME/" "templates/debian/control" | sed "s/@NAME@/$NAME/" | sed s"/@DEPENDS@/$DEPENDS/" | sed "$BREAKCMD" | sed "$PROVIDESCMD" > "$DEBIAN/control"
echo "$DEBNAME ($DEBREV-1) unstable; urgency=low" > "$DEBIAN/changelog"
echo "  * Automatic subversion build" >> "$DEBIAN/changelog"
test -f "build/$NAME.changes" && cat "build/$NAME.changes" >> "$DEBIAN/changelog"
echo " -- OpenModelica Build System <build@openmodelica.org>  `date -R`" >> "$DEBIAN/changelog"
mkdir -p "$DEBIAN/source"
echo "3.0 (quilt)" > "$DEBIAN/source/format"
# TODO: Change to xz when all distros support it
if ! (cd "$DIR" && debuild -us -uc -S); then
  echo "Error: *** Failed to build source package $FULLNAME"
  exit 1
fi
if ! (cd "$DIR" && dpkg-buildpackage -us -uc); then
  echo "Error: *** Failed to build package $FULLNAME"
  exit 1
fi
