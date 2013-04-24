#!/bin/sh

if test $# -ne 3 || ! test -f "$3"; then
  echo "Usage: $0 omc build/dir path/file.mo"
  exit 1
fi

OMC=$1
BUILD=$2
FILE=$3
# Verify that all libraries parse
cat > test-valid.$$.mos <<EOF
b:=loadFile("$FILE");
s:=getErrorString();
if not b then
  writeFile("error.log","Failed to load $FILE:\n" + s + "\n",append=true);
end if;
EOF
LIB=`echo $FILE | sed s,/package.mo,, | sed s,.mo$,, | sed s,$BUILD/,,`
if test -f "$BUILD/$LIB.std"; then
  STD=`cat "$BUILD/$LIB.std"`
  STD="+std=$STD"
fi
"$OMC" $STD test-valid.$$.mos > /dev/null
echo $FILE turned to $LIB
# find "`echo $2 | sed s,/package.mo,,`" -type f -print0 | sort -z | xargs -0 cat | sha1sum > "$BUILD/$LIB.hash"
touch "$BUILD/$LIB.ok"
