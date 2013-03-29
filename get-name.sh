#!/bin/sh

if test $# -ne 3; then
  echo "Usage: $0 package.mo encoding standard"
  exit 1
fi
MOS="get-name.$$.mos"
NAME="get-name.$$.name"
rm -f $MOS $NAME
cat > $MOS <<EOF
loadFile("$1",encoding="$2");getErrorString();
names:=getClassNames();getErrorString();
name:=names[1];getErrorString();
nameStr:=typeNameString(name);getErrorString();
writeFile("$NAME",nameStr);getErrorString();
EOF
omc "+std=$3" $MOS > /dev/null 2>&1
PACKAGE=`test -f "$NAME" && cat "$NAME"`
rm -f $MOS $NAME
if test -z "$PACKAGE"; then
  exit 1
fi
echo $PACKAGE
