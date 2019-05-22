#!/bin/sh

LIB=$1
shift
VERSION=`echo $* | tr -- '-[:upper:]_ ' '~[:lower:]--'`
echo "omlib-`echo $LIB | tr '[:upper:]_' '[:lower:]-'``test -z "$VERSION" || echo "-"`$VERSION"
