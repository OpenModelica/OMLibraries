#!/bin/sh

if test "$#" -ne 4; then
  echo "Usage: $0 DESTINATION URL GITBRANCH HASH"
  exit 1
fi
DEST=$1
URL=$2
GITBRANCH=$3
REVISION=$4

if test -d "$DEST"; then
  # Clean out any old mess
  (cd "$DEST" && git reset --hard)
  (cd "$DEST" && git clean -f)
  (cd "$DEST" && git checkout -q "$REVISION" || git fetch -fq "$URL" "$GITBRANCH" || (sleep 10 && git fetch -fq "$URL" "$GITBRANCH") || (sleep 20 && git fetch -fq "$URL" "$GITBRANCH")) || rm -rf "$DEST"
fi
if ! test -d "$DEST"; then
  echo "[$DEST] does not exist: cloning [$URL]"
  (git clone --branch "$GITBRANCH" --single-branch "$URL" "$DEST" || (sleep 10 && git clone --branch "$GITBRANCH" --single-branch "$URL" "$DEST") || (sleep 30 && git clone --branch "$GITBRANCH" --single-branch "$URL" "$DEST")) || exit 1
  # In case of CRLF properties, etc
  (cd "$DEST" && git reset --hard)
  (cd "$DEST" && git clean -fdx)
fi

if ! (cd "$DEST" && git checkout -f "$REVISION" ); then
  echo "git checkout $REVISION failed for: $DEST"
  exit 1
fi

(cd "$DEST" && git reset --hard)
(cd "$DEST" && git clean -fdx)

echo "$REVISION" > "$DEST.rev"
