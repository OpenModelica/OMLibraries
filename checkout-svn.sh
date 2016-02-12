#!/bin/sh

if test "$#" -ne 3; then
  echo "Usage: $0 DESTINATION URL HASH"
  exit 1
fi
DEST=$1
URL=$2
REVISION=$3

if test -d "$DEST"; then
  (svn cleanup "$DEST" && svn revert -R "$DEST") || rm -r "$DEST"
fi

if ! test -d "$DEST"; then
  svn co $SVNOPTS "-r$REVISION" "$URL" "$DEST" --trust-server-cert --non-interactive || exit 1
  echo "$REVISION" > "$DEST.rev"
elif test -d "$DEST" && ! test "$URL" = "`svn info "$DEST" | grep ^URL: | sed "s/URL: //"`"; then
  echo "Not same URL... $URL and `svn info "$DEST" | grep ^URL: | sed "s/URL: //"`"
  rm -rf "$DEST"
  svn co $SVNOPTS "-r$REVISION" "$URL" "$DEST" --trust-server-cert --non-interactive || exit 1
  echo "$REVISION" > "$DEST.rev"
else
  if test `svn info $SVNOPTS --xml "$DEST" | xpath -q -e '/info/entry/commit/@revision' | grep -o "[0-9]*"` = "$REVISION"; then
    echo "$DEST is up to date"
  elif ! svn up $SVNOPTS "-r$REVISION" "$DEST" --trust-server-cert --non-interactive; then
    echo "Failed to update $DEST"
    test -d "$DEST" && rm -r "$DEST"
    exit 1
  else
    # svn-clean is a nice extra; not needed
    svn-clean "$DEST" 2> /dev/null
  fi
  echo "$REVISION" > "$DEST.rev"
fi
