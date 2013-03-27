#!/bin/sh

mkdir -p debian-build
for f in build/Modelica*3.1/package.mo; do
  LIB=`echo $f | sed "s,build/\(.*\)/package.mo,\1,"`
  VERSION=`echo $LIB | grep " " | cut -d" " -f2`
  LIB=`echo $LIB | cut -d" " -f1`
  NAME="$LIB`test -z "$VERSION" || echo " "`$VERSION"
  LICENSE=`cat "build/$NAME.license"`
  if ! test "`basename "$f"`" = package.mo; then
    EXT=".mo"
  fi
  DEBNAME="omlibrary-`echo $LIB | tr '[:upper:]' '[:lower:]'``test -z "$VERSION" || echo "-"`$VERSION"
  DEBREV=`cat "build/$NAME.last_change"`
  FULLNAME="${DEBNAME}_${DEBREV}"
  DIR="debian-build/$FULLNAME"
  DEBIAN="$DIR/debian/"
  echo "Build debian package for $LIB of version $VERSION"
  echo "Debian package will be named $DEBNAME with revision $DEBREV"
  rm -rf "$DIR" "$DIR.*" "$DIR-*"
  mkdir -p "$DIR"
  cp -r "build/$NAME$EXT" "$DIR/" || exit 1
  (cd "debian-build" && tar czf "$FULLNAME.orig.tar.gz" "$FULLNAME") || exit 1
  #(cd "$DIR" && dh_make -p "$FULLNAME" --createorig --packageclass=i) || exit 1
  mkdir -p "$DEBIAN"
  echo "$DEBNAME has license $LICENSE"
  cp "templates/debian/copyright.$LICENSE" "$DEBIAN/copyright"
  cp "templates/debian/rules" "$DEBIAN/rules"
  echo 8 > "$DEBIAN/compat"
  sed "s/@DEBNAME@/$DEBNAME/" "templates/debian/control" | sed "s/@NAME@/$NAME/" > "$DEBIAN/control"
  sed "s/@DEBNAME@/$DEBNAME/" "templates/debian/changelog" | sed "s/@DEBREV@/$DEBREV/" | sed "s/@TIME@/`date -R`/" > "$DEBIAN/changelog"
  mkdir -p "$DEBIAN/source"
  echo "3.0 (quilt)" > "$DEBIAN/source/format"
  (cd "$DIR" && debuild -us -uc -S || exit 1)
done
