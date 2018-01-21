ObjFW is a portable, lightweight framework for the Objective C language.
It enables you to write an application in Objective C that will run on
any platform supported by ObjFW without having to worry about
differences between operating systems or various frameworks that you
would otherwise need if you want to be portable.

See https://heap.zone/objfw for more information.


Installation
============

  To install ObjFW, just run the following commands:

    $ ./configure
    $ make
    $ make install

  In case you checked out ObjFW from the Git repository, you need to run
  the following command first:

    $ ./autogen.sh


Building as a macOS or iOS framework
====================================

  When building for macOS or iOS, everything is built as a `.framework` by
  default if `--disable-shared` has not been specified to `configure`.

  To build for iOS, use something like this:

    $ clang="clang --sysroot $(xcrun --sdk iphoneos --show-sdk-path)"
    $ export OBJC="$clang -arch armv7 -arch arm64"
    $ export OBJCPP="$clang -arch armv7 -E"
    $ export IPHONEOS_DEPLOYMENT_TARGET="10.0"
    $ ./configure --prefix=/usr/local/ios --host=arm-apple-darwin

  To build for the iOS simulator, use something like this:

    $ clang="clang --sysroot $(xcrun --sdk iphonesimulator --show-sdk-path)"
    $ export OBJC="$clang -arch i386 -arch x86_64"
    $ export OBJCPP="$clang -arch i386 -E"
    $ export IPHONEOS_DEPLOYMENT_TARGET="10.0"
    $ ./configure --prefix=/usr/local/iossim --host=i386-apple-darwin


Using the macOS or iOS framework in Xcode
=========================================

  To use the macOS framework in Xcode, you need to add the `.framework`s to your
  project and add the following flags to `Other C Flags`:

    -fconstant-string-class=OFConstantString -fno-constant-cfstrings

  Optionally, if you want to use blocks, you also need to add:

    -fblocks


Bugs and feature requests
=========================

  If you find any bugs or have feature requests, feel free to send a
  mail to js@heap.zone!
