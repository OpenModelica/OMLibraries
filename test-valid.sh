#!/bin/sh

if test $# -ne 1 || ! test -f "$1"; then
  echo "Usage: $0 path/file.mo"
  exit 1
fi

# Verify that all libraries parse
cat > test-valid.$$.mos <<EOF
b:=loadFile("$1");
s:=getErrorString();
if not b then
  writeFile("error.log","Failed to load $1:\n" + s + "\n",append=true);
end if;
EOF
omc test-valid.$$.mos > /dev/null
LIB=`echo $1 | sed s,/package.mo,, | sed s,.mo$,, | sed s,build/,,`
echo $1 turned to $LIB
find "`echo $1 | sed s,/package.mo,,`" -type f -print0 | sort -z | xargs -0 cat | sha1sum > "build/$LIB.hash"
