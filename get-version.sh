#!/bin/sh
# Gets the version of the library and its uses-annotations

if test $# -ne 5; then
  exit 1
fi
BUILD="$1"
MOS="get-version.$$.mos"
VER="get-version.$$.ver"
rm -f $MOS $VER
cat > $MOS <<EOF
loadFile("$2",encoding="$4");getErrorString();
version:=getVersion($3);getErrorString();
writeFile("$VER",version);getErrorString();
uses:=getUses($3);getErrorString();
str:=sum(uses[i,1] + " " + uses[i,2] + "\n" for i in 1:size(uses,1));
writeFile("$BUILD$3" + (if version <> "" then (" " + version) else "") + ".uses",str);getErrorString();
EOF
omc "+std=$5" $MOS > /dev/null 2>&1
VERSION=`test -f "$VER" && cat "$VER"`
rm -f $MOS $VER
if test -z "$VERSION"; then
  exit 1
fi
echo $VERSION
