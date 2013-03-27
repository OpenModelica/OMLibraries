#!/bin/sh

if test $# -lt 3 || ! test "$1" = SVN || ! test "$1" = GIT; then
  echo "Usage: $0 [SVN|GIT] URL REVISION"
fi
