#!/bin/sh
set -e

# Set a version for OpenBSD
if test x"$(uname -s)" = x"OpenBSD"; then
	: ${AUTOCONF_VERSION:=2.72}
	: ${AUTOMAKE_VERSION:=1.17}
	export AUTOCONF_VERSION AUTOMAKE_VERSION
fi

aclocal -I build-aux/m4
autoconf
autoheader
