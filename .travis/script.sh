#!/bin/sh
build() {
	if ! git clean -fxd >/tmp/clean_log 2>&1; then
		cat /tmp/clean_log
		exit 1
	fi

	./autogen.sh || exit 1
	.travis/build.sh "$@" || exit 1
}

if [ "$TRAVIS_OS_NAME" = "linux" -a -z "$config" ]; then
	build_32_64() {
		build OBJC="$CC" $@

		case "$TRAVIS_CPU_ARCH" in
			amd64)
				build OBJC="$CC -m32" \
					--host=i686-pc-linux-gnu $@
				;;
			s390x)
				build OBJC="$CC -m31" \
					--host=s390-pc-linux-gnu $@
				;;
		esac
	}

	build_32_64
	build_32_64 --enable-seluid24
	build_32_64 --disable-compiler-tls

	# The following are not CPU-dependent, so only run them on amd64
	if [ "$TRAVIS_CPU_ARCH" = "amd64" ]; then
		build_32_64 --disable-threads
		build_32_64 --disable-threads --disable-sockets
		build_32_64 --disable-threads --disable-files
		build_32_64 --disable-threads --disable-sockets --disable-files
		build_32_64 --disable-sockets
		build_32_64 --disable-sockets --disable-files
		build_32_64 --disable-files
		build_32_64 --disable-shared
		build_32_64 --disable-shared --enable-seluid24
		build_32_64 --disable-compiler-tls --disable-threads
	fi
fi

if [ "$TRAVIS_OS_NAME" = "osx" -a -z "$config" ]; then
	build_mac_32_64() {
		build $@

		if [ -z "$no32bit" ]; then
			build OBJC="clang -m32" --host=i386-apple-darwin $@
		fi
	}

	if xcodebuild -version | grep 'Xcode 6' >/dev/null; then
		export CPPFLAGS="-D_Null_unspecified=__null_unspecified"
		export CPPFLAGS="$CPPFLAGS -D_Nullable=__nullable"
		export CPPFLAGS="$CPPFLAGS -D_Nonnull=__nonnull"
	fi

	build_mac_32_64
	build_mac_32_64 --disable-threads
	build_mac_32_64 --disable-threads --disable-sockets
	build_mac_32_64 --disable-threads --disable-files
	build_mac_32_64 --disable-threads --disable-sockets --disable-files
	build_mac_32_64 --disable-sockets
	build_mac_32_64 --disable-sockets --disable-files
	build_mac_32_64 --disable-files
	build_mac_32_64 --disable-shared

	if [ -z "$noruntime" ]; then
		build_mac_32_64 --enable-runtime
		build_mac_32_64 --enable-runtime --enable-seluid24
		build_mac_32_64 --enable-runtime --disable-threads
		build_mac_32_64 --enable-runtime --disable-threads \
				--disable-sockets
		build_mac_32_64 --enable-runtime --disable-threads \
				--disable-files
		build_mac_32_64 --enable-runtime --disable-threads \
				--disable-sockets --disable-files
		build_mac_32_64 --enable-runtime --disable-sockets
		build_mac_32_64 --enable-runtime --disable-sockets \
				--disable-files
		build_mac_32_64 --enable-runtime --disable-files
		build_mac_32_64 --enable-runtime --disable-shared
		build_mac_32_64 --enable-runtime --disable-shared \
				--enable-seluid24
	fi
fi

if [ "$config" = "ios" ]; then
	if xcodebuild -version | grep 'Xcode 6' >/dev/null; then
		export CPPFLAGS="-D_Null_unspecified=__null_unspecified"
		export CPPFLAGS="$CPPFLAGS -D_Nullable=__nullable"
		export CPPFLAGS="$CPPFLAGS -D_Nonnull=__nonnull"
	fi

	export IPHONEOS_DEPLOYMENT_TARGET="9.0"
	clang="clang -isysroot $(xcrun --sdk iphoneos --show-sdk-path)"
	export OBJC="$clang -arch armv7 -arch arm64"
	export OBJCPP="$clang -arch armv7 -E"
	build --host=arm-apple-darwin --enable-static

	sysroot="$(xcrun --sdk iphonesimulator --show-sdk-path)"
	clang="clang -isysroot $sysroot"
	export OBJC="$clang -arch i386 -arch x86_64"
	export OBJCPP="$clang -arch i386 -E"
	build WRAPPER=true --host=i386-apple-darwin --enable-static
fi

if [ "$config" = "amigaos" ]; then
	export PATH="/opt/amiga/bin:$PATH"

	build --host=m68k-amigaos
	build --host=m68k-amigaos --disable-amiga-lib
	build --host=m68k-amigaos --enable-static
fi

if [ "$config" = "nintendo_3ds" ]; then
	./autogen.sh
	docker run -e DEVKITPRO=/opt/devkitpro				\
		-e PATH="/opt/devkitpro/devkitARM/bin:$PATH"		\
		-v $TRAVIS_BUILD_DIR:/objfw devkitpro/devkitarm		\
		/objfw/.travis/build.sh --host=arm-none-eabi --with-3ds
fi

if [ "$config" = "nintendo_ds" ]; then
	./autogen.sh
	docker run -e DEVKITPRO=/opt/devkitpro				\
		-e PATH="/opt/devkitpro/devkitARM/bin:$PATH"		\
		-v $TRAVIS_BUILD_DIR:/objfw devkitpro/devkitarm		\
		/objfw/.travis/build.sh --host=arm-none-eabi --with-nds
fi

if [ "$config" = "wii" ]; then
	./autogen.sh
	docker run -e DEVKITPRO=/opt/devkitpro				\
		-e PATH="/opt/devkitpro/devkitPPC/bin:$PATH"		\
		-v $TRAVIS_BUILD_DIR:/objfw devkitpro/devkitppc		\
		/objfw/.travis/build.sh ac_cv_prog_wiiload=		\
		--host=powerpc-eabi --with-wii
fi
