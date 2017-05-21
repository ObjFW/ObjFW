#!/bin/sh
set -e
aclocal -I build-aux/m4
autoconf
autoheader
