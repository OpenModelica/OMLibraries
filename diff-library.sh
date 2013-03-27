#!/bin/sh
! diff -u -x .svn -r "$1" "$2" > "$3"
