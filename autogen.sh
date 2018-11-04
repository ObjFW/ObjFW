#!/bin/sh
set -e

# Set a version for OpenBSD
: ${AUTOCONF_VERSION:=2.69}
: ${AUTOMAKE_VERSION:=1.16}
export AUTOCONF_VERSION AUTOMAKE_VERSION

aclocal -I build-aux/m4
autoconf
autoheader
