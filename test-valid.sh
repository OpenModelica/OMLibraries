#!/bin/sh

# Check that all used libraries exist
for f in *.uses; do
  for l in `cat "$f" | sed "s/ /%20/g"`; do
    LIB=`echo $l | sed "s/%20/ /g"`
    if ! (test -f "build/$LIB"*".mo" || test -f "build/$LIB"*"/package.mo"); then
      echo "Could not find library $LIB, used by $f"
      exit 1
    fi
  done
done

# Verify that all libraries parse
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
