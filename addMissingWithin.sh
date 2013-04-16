#!/bin/sh
# You need to be placed in the directory just above the library
# $ ls
# Modelica 1.6
# $ addMissingWithin.sh
# Will then fix all mo-files visible from here (i.e. all in Modelica 1.6)

for f in `find . -name "*.mo"`; do
  WITHIN=`dirname $f | sed "s,./,within ," | tr / .| sed 's/$/;/'`
  if test "package.mo" = "`basename $f`"; then
    WITHIN=`echo $WITHIN | sed 's/[. ][^.]*;/;/'`
  fi
  if grep -q "^within" "$f"; then
    echo "Skipping $f; already has within"
  else
    echo $WITHIN | cat - $f > tmp.mo
    mv tmp.mo $f
    echo "Fixed $f"
  fi
done
