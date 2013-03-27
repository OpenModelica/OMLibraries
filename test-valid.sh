#!/bin/sh

rm -f error.log
for f in build/*.mo build/*/package.mo; do
  cat > test-valid.mos <<EOF
b:=loadFile("$f");
s:=getErrorString();
if not b then
  writeFile("error.log","Failed to load $f:\n" + s + "\n");
end if;
EOF
  omc test-valid.mos > /dev/null
  if test -f error.log; then
    cat error.log
    exit 1
  fi
done
rm -f test-valid.mos
