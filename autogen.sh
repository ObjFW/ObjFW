#!/bin/sh
set -e
aclocal -I m4
autoconf
autoheader
