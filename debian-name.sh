#!/bin/sh

LIB=$1
VERSION=$2
echo "omlib-`echo $LIB | tr '[:upper:]_' '[:lower:]-'``test -z "$VERSION" || echo "-"`$VERSION"
