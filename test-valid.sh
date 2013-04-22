#!/bin/sh

if test $# -ne 2 || ! test -f "$2"; then
  echo "Usage: $0 build/dir path/file.mo"
  exit 1
fi

BUILD=$1
# Verify that all libraries parse
cat > test-valid.$$.mos <<EOF
b:=loadFile("$2");
s:=getErrorString();
if not b then
  writeFile("error.log","Failed to load $2:\n" + s + "\n",append=true);
end if;
EOF
LIB=`echo $2 | sed s,/package.mo,, | sed s,.mo$,, | sed s,$BUILD/,,`
if test -f "$BUILD/$LIB.std"; then
  STD=`cat "$BUILD/$LIB.std"`
  STD="+std=$STD"
fi
omc $STD test-valid.$$.mos > /dev/null
echo $2 turned to $LIB
find "`echo $2 | sed s,/package.mo,,`" -type f -print0 | sort -z | xargs -0 cat | sha1sum > "$BUILD/$LIB.hash"
