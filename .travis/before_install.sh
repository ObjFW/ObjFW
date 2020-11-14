#!/bin/sh
if [ "$TRAVIS_OS_NAME" = "linux" -a -z "$config" ]; then
	case "$TRAVIS_CPU_ARCH" in
		amd64 | s390x)
			pkgs="gobjc-multilib"
			;;
		*)
			pkgs="gobjc"
			;;
	esac

	pkgs="$pkgs libsctp-dev"

	if grep precise /etc/lsb-release >/dev/null; then
		pkgs="$pkgs ipx"
	fi

	# We don't need any of them and they're often broken.
	sudo rm -f /etc/apt/sources.list.d/*

	if ! sudo apt-get -qq update >/tmp/apt_log 2>&1; then
		cat /tmp/apt_log
		exit 1
	fi

	if ! sudo apt-get -qq install -y $pkgs >>/tmp/apt_log 2>&1; then
		cat /tmp/apt_log
		exit 1
	fi

	if grep precise /etc/lsb-release >/dev/null; then
		sudo ipx_internal_net add 1234 123456
	fi
fi

if [ "$config" = "nintendo_3ds" -o "$config" = "nintendo_ds" ]; then
	docker pull devkitpro/devkitarm
fi

if [ "$config" = "wii" ]; then
	docker pull devkitpro/devkitppc
fi

if [ "$config" = "amigaos" ]; then
	wget -q https://franke.ms/download/amiga-gcc.tgz
	tar -C / -xzf amiga-gcc.tgz
fi
