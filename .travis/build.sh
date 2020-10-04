#!/bin/sh
cd $(dirname $0)/..

echo ">> Configuring with $@"
if ! ./configure ac_cv_path_TPUT= "$@"; then
	cat config.log
	exit 1
fi

echo ">> Building (configured with $@)"
if ! make -j4 >/tmp/make_log 2>&1; then
	cat /tmp/make_log
	exit 1
fi

echo ">> Installing (configured with $@)"
if ! sudo PATH="$PATH" make install >/tmp/install_log 2>&1; then
	cat /tmp/install_log
	exit 1
fi
