#!/bin/sh
aclocal -I m4 || exit 1
autoconf || exit 1
./configure $@
