ObjFW is a portable, lightweight framework for the Objective C language.
It enables you to write an application in Objective C that will run on
any platform supported by ObjFW without having to worry about
differences between operating systems or various frameworks that you
would otherwise need if you want to be portable.

See https://webkeks.org/objfw for more information.


Installation
============

  To install ObjFW, just run the following commands:

    $ ./configure
    $ make
    $ make install

  In case you checked out ObjFW from the Git repository, you need to run
  the following command first:

    $ ./autogen.sh


Building as a Mac OS X framework
================================

  It is also possible to build ObjFW as a Mac OS X framework. To do so,
  just execute xcodebuild -target ObjFW in the root directory of ObjFW
  or open the .xcodeproj in Xcode and choose Build -> Build from the
  menu. Copy the resulting ObjFW.framework to `/Library/Frameworks` and
  you are done.


Using the Mac OS X framework in Xcode
=====================================

  To use the Mac OS X framework in Xcode, you need to add the .framework
  to your project and add the following flags to `Other C Flags`:

    -fconstant-string-class=OFConstantString -fno-constant-cfstrings

  Optionally, if you want to use blocks, you also need to add:

    -fblocks


Building with LLVM/Clang for ARM
================================

  When using LLVM/Clang older than 3.5 to compile for ARM, it is necessary to
  specify extra flags in order to enable ARM EHABI compliant exceptions. To do
  so, set `OBJCFLAGS` to this:

    -O2 -g -mllvm -arm-enable-ehabi -mllvm -arm-enable-ehabi-descriptors

  If you have a CPU supporting VFP or NEON, it is important to set the correct
  architecture, as otherwise VFP / NEON registers won't be saved and restored
  when forwarding. For example, if you have an ARMv6 that supports VFP, you
  need to set `OBJC` to this:

    clang -march=armv6 -mfpu=vfp

  Using these flags, ObjFW was compiled successfully for Android and the
  Raspberry Pi.


Bugs and feature requests
=========================

  If you find any bugs or have feature requests, feel free to send a
  mail to js@webkeks.org!
