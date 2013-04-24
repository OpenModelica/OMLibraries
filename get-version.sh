#!/bin/sh
# Gets the version of the library and its uses-annotations

if test $# -ne 5; then
  exit 1
fi
BUILD="$1"
FILE="$2"
LIB="$3"
ENCODING="$4"
STD="$5"
MOS="get-version.$$.mos"
VER="get-version.$$.ver"
rm -f $MOS $VER
cat > $MOS <<EOF
loadFile("$FILE",encoding="$ENCODING");getErrorString();
version:=getVersion($LIB);getErrorString();
writeFile("$VER",version);getErrorString();
uses:=getUses($LIB);getErrorString();
str:=sum(uses[i,1] + " " + uses[i,2] + "\n" for i in 1:size(uses,1));
writeFile("$BUILD/$LIB" + (if version <> "" then (" " + version) else "") + ".uses",str);getErrorString();
EOF
omc "+std=$STD" $MOS > /dev/null 2>&1
VERSION=`test -f "$VER" && cat "$VER"`
rm -f $MOS $VER
if test -z "$VERSION"; then
  exit 1
fi
echo $VERSION
