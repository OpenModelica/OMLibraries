#!/bin/sh
find build "$1" -name "*.rej" -exec rm -f {} ";"
find build "$1" -name "*.orig" -exec rm -f {} ";"
diff --text -u -x .svn -r "$1" "build/$2" > "$3"
true
