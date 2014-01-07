#!/bin/sh

find *.ok -print0 | sed "s/[.]ok//g" | xargs -0 -n 1 sh -c 'echo -n "port:`../debian-name.sh $1` " ' sh
