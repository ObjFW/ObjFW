#!/bin/sh
set -e

if test x"$1" = x""; then
	echo "Usage: $0 destination"
	exit 1
fi

cd ..

prefix="$1"
export IPHONEOS_DEPLOYMENT_TARGET="9.0"

msg() {
	tput setaf 6
	tput bold
	echo "$@"
	tput sgr0
}

msg "This could take a while - you should probably grab a coffee."

msg "Running autogen.sh"
./autogen.sh

build() {
	objc="$(xcrun -f clang) --sysroot $(xcode-select -p)"
	objc="$objc/Platforms/$3.platform/Developer/SDKs/$3.sdk"

	msg "make distclean"
	test -f buildsys.mk && make distclean

	msg "Configuring for $1"
	./configure			\
		--host=$2		\
		--prefix=$prefix/$1	\
		--enable-static		\
		OBJC="$objc -arch $1"

	msg "Building for $1"
	make -C src libobjfw.a ObjFW.framework
	make -C src/bridge libobjfw_bridge.a ObjFW_Bridge.framework
	make -C src install
	mkdir -p $prefix/$1/Frameworks
	cp -R src/ObjFW.framework src/bridge/ObjFW_Bridge.framework \
		$prefix/$1/Frameworks
	make distclean
}

build armv7 arm-apple-darwin iPhoneOS
build arm64 arm64-apple-darwin iPhoneOS
build x86_64 x86_64-apple-darwin iPhoneSimulator

msg "Sanity checking"
diff -Nru $prefix/armv7/include $prefix/arm64/include
diff -Nru $prefix/armv7/Frameworks/ObjFW.framework/Headers \
	$prefix/arm64/Frameworks/ObjFW.framework/Headers
diff -Nru $prefix/armv7/Frameworks/ObjFW_Bridge.framework/Headers \
	$prefix/arm64/Frameworks/ObjFW_Bridge.framework/Headers

mv $prefix/armv7/include $prefix/
mkdir -p						\
	$prefix/lib					\
	$prefix/Frameworks/ObjFW.framework		\
	$prefix/Frameworks/ObjFW_Bridge.framework

combine() {
	msg "Combining $1"
	lipo \
		$prefix/armv7/$1 \
		$prefix/arm64/$1 \
		$prefix/x86_64/$1 \
		-create -output $prefix/$1
}

combine lib/libobjfw.a
combine lib/libobjfw_bridge.a
combine Frameworks/ObjFW.framework/ObjFW
combine Frameworks/ObjFW_Bridge.framework/ObjFW_Bridge
rm $prefix/armv7/Frameworks/ObjFW.framework/ObjFW
mv $prefix/armv7/Frameworks/ObjFW.framework/* \
	$prefix/Frameworks/ObjFW.framework/
rm $prefix/armv7/Frameworks/ObjFW_Bridge.framework/ObjFW_Bridge
mv $prefix/armv7/Frameworks/ObjFW_Bridge.framework/* \
	$prefix/Frameworks/ObjFW_Bridge.framework/

msg "Cleaning up"
rm -fr $prefix/armv7 $prefix/arm64 $prefix/x86_64
