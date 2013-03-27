#!/bin/sh
# Gets the version of the library and its uses-annotations

if test $# -ne 4; then
  exit 1
fi
MOS="get-version.$$.mos"
VER="get-version.$$.ver"
rm -f $MOS $VER
cat > $MOS <<EOF
loadFile("$1",encoding="$3");getErrorString();
version:=getVersion($2);getErrorString();
writeFile("$VER",version);getErrorString();
uses:=getUses($2);getErrorString();
str:=sum(uses[i,1] + " " + uses[i,2] + "\n" for i in 1:size(uses,1));
writeFile("$2" + (if version <> "" then (" " + version) else "") + ".uses",str);getErrorString();
EOF
omc "+std=$4" $MOS > /dev/null 2>&1
VERSION=`cat "$VER"`
rm -f $MOS $VER
if test -z "$VERSION"; then
  exit 1
fi
echo $VERSION
