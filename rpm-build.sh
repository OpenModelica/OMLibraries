#!/bin/sh

if test $# -ne 1; then
  echo "Error: *** Usage: $0 path/file.mo, got $@"
  exit 1
fi

mkdir -p debian-build

DEPENDS=`for f in $DEPENDS; do echo -n $f,; done`

if ! echo $1 | grep -q "^.*_.*-1_all[.]deb"; then
  if ! echo $1 | grep -q '^[0-9]\{8\}_[0-9]\{6\}$'; then
    echo "Couldn't extract the version..."
    exit 1
  fi
  COLLECTION=1
  VERSION="$1"
  RPMVERSION="$VERSION"
  FULLRPMNAME="omlib-all-$RPMVERSION-1.noarch.rpm"
  DIRECTORY=omlib-all
else
  DIRECTORY=`echo $1 | sed 's/^\(.*\)_\(.*\)-1_all[.]deb$/\1-\2/'`
  VERSION=`echo $1 | sed 's/^.*_\(.*\)-1_all[.]deb$/\1/'`
  RPMVERSION=`echo $VERSION | tr '-' '_'`
  FULLRPMNAME=`echo $1 | sed "s/^\(.*\)_\(.*\)\(-1_all[.]deb\)$/\1-$RPMVERSION-1.noarch.rpm/"`
fi

if rsync `cat .remote/rpmpool`/"$FULLRPMNAME" rpm-build/ >/dev/null 2>&1; then
  echo "$FULLRPMNAME-1.noarch.rpm already built"
  exit 0
elif test -f "build/$NAME.nopackage"; then
  CONTENT=`cat "build/$NAME.nopackage"`
  echo "$FULLNAME $CONTENT - skipping"
  exit 0
fi

cp .rpmmacros ~/.rpmmacros || exit 1
cd rpm-build || exit 1

if test "$COLLECTION" = 1; then
  REQUIRES=`cat ../.remote/nightly-library-files | cut -d_ -f1`
  sed -e "s/VERSION/$VERSION/" -e "s/REQUIRES/`echo $REQUIRES`/" ../templates/rpm/omlib.spec > tmp.spec || exit 1
  mkdir -p omlib-all
else
  echo "Build RPM package $FULLRPMNAME using alien"
  rsync `cat ../.remote/pool`/$1 ./ || exit 1
  sudo alien -g -k --to-rpm $1 || exit 1
  REQUIRES="`dpkg -I $1 | grep "^ *Depends:" | cut -d: -f2`"
  echo $REQUIRES
  if test ! -z "$REQUIRES"; then
    REQUIRES="Requires: $REQUIRES"
  fi
  sed -e 's#%dir "/"##' -e 's#%dir "/usr/"##' -e 's#%dir "/usr/lib/"##' -e 's#%dir "/usr/share/"##' -e 's#%dir "/usr/share/doc/"##' -e  "s#Group: Converted/math#$REQUIRES#" "`pwd`/$DIRECTORY/"*.spec > tmp.spec || exit 1
fi
sudo rpmbuild --buildroot="`pwd`/$DIRECTORY/" --define "_rpmdir ../" --define "_rpmfilename %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm" -bb --target noarch tmp.spec
mv ../"$FULLRPMNAME" . || exit 1
if ! test -f "$FULLRPMNAME"; then
  echo "Alien didn't produce $FULLRPMNAME"
  exit 1
fi
