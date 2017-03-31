#!/bin/sh

if test $# -ne 1; then
  echo "Error: *** Usage: $0 path/file.mo, got $@"
  exit 1
fi

mkdir -p debian-build

DEPENDS=`for f in $DEPENDS; do echo -n $f,; done`

if ! echo $1 | grep -q "^.*_.*-1_all[.]deb"; then
  echo "Couldn't extract the version..."
fi

DIRECTORY=`echo $1 | sed 's/^\(.*\)_\(.*\)-1_all[.]deb$/\1-\2/'`
VERSION=`echo $1 | sed 's/^.*_\(.*\)-1_all[.]deb$/\1/'`
RPMVERSION=`echo $VERSION | tr '-' '_'`
FULLRPMNAME=`echo $1 | sed "s/^\(.*\)_\(.*\)\(-1_all[.]deb\)$/\1-$RPMVERSION-1.noarch.rpm/"`

if rsync `cat .remote/rpmpool`/"$FULLRPMNAME" rpm-build/ >/dev/null 2>&1; then
  echo "$FULLRPMNAME-1.noarch.rpm already built"
  exit 0
elif test -f "build/$NAME.nopackage"; then
  CONTENT=`cat "build/$NAME.nopackage"`
  echo "$FULLNAME $CONTENT - skipping"
  exit 0
fi

echo "Build RPM package $FULLRPMNAME using alien"

rsync `cat .remote/pool`/$1 rpm-build/ || exit 1
cp .rpmmacros ~/.rpmmacros || exit 1

cd rpm-build || exit 1
sudo alien -g -k --to-rpm $1 || exit 1
sed -e 's#%dir "/"##' -e 's#%dir "/usr/?"##' -e 's#%dir "/usr/lib/?"##' -e 's#%dir "/usr/share/?"##' -e 's#%dir "/usr/share/doc/?"##' "`pwd`/$DIRECTORY/"*.spec > tmp.spec || exit 1
sudo rpmbuild --buildroot="`pwd`/$DIRECTORY/" -bb --target noarch tmp.spec
mv ../"$FULLRPMNAME" . || exit 1
if ! test -f "$FULLRPMNAME"; then
  echo "Alien didn't produce $FULLRPMNAME"
  exit 1
fi
