In order to build ObjFW from source, you first need to acquire the source code
first. You can do so either by using one of the
[releases](https://git.nil.im/ObjFW/ObjFW/releases) or you can clone the
repository using `git clone https://git.nil.im/ObjFW/ObjFW` to get the latest
development state.

In most cases, you can use the generic instructions, but there are some more
specific instructions for some operating systems further below.


Generic instructions
====================

To build ObjFW from source and install it, just run the following commands:

    ./configure
    make
    make check
    sudo make install

In case you checked out ObjFW from the repository, you need to run the
following command first:

    ./autogen.sh


macOS and iOS
=============

The generic instructions apply, but keep reading on for some macOS and iOS
specifics.

Building as a .framework
------------------------

When building for macOS or iOS, everything is built as a `.framework` by
default if `--disable-shared` has not been specified to `./configure`. The
frameworks will end up in `$PREFIX/Library/Frameworks`.

To build for macOS, just follow the generic instructions above.

To build for iOS, follow the generic instructions above, but instead of
`./configure` do something like this:

    clang="xcrun --sdk iphoneos clang"
    export OBJC="$clang -arch arm64e -arch arm64"
    export OBJCPP="$clang -arch arm64e -E"
    export IPHONEOS_DEPLOYMENT_TARGET="10.0"
    ./configure --prefix=/opt/ios --host=arm64-apple-darwin

To build for the iOS simulator, follow the generic instructions above, but
instead of `./configure` use something like this:

    clang="xcrun --sdk iphonesimulator clang"
    export OBJC="$clang -arch $(uname -m)"
    export IPHONEOS_DEPLOYMENT_TARGET="10.0"
    ./configure --prefix=/opt/iossim --host=$(uname -m)-apple-darwin

Using the macOS or iOS .framework in Xcode
------------------------------------------

To use the macOS or iOS framework in Xcode, you need to add the `.framework`s
to your project and add the following flags to `Other C Flags`:

    -fconstant-string-class=OFConstantString
    -fno-constant-cfstrings
    -fno-constant-nsnumber-literals
    -fno-constant-nsarray-literals
    -fno-constant-nsdictionary-literals


Windows
=======

Windows is only officially supported when following these instructions, as
there are many MinGW versions that behave slightly differently and often cause
problems.

Getting MSYS2
-------------

The first thing to install is [MSYS2](https://www.msys2.org) to provide a basic
UNIX-like environment for Windows. Unfortunately, the binaries are not signed,
so make sure you download it via HTTPS. However, packages you download and
install via MSYS2 are cryptographically signed.

Setting up MSYS2
----------------

MSYS2 currently supports 7 different
[environments](https://www.msys2.org/docs/environments/). All of them except
for the one called just "MSYS" are supported, but which packages you need to
install depends on the environment(s) you want to use. If you only want to
target Windows 10 and newer, the CLANG64 and CLANG32 environments are the
recommended ones.

For CLANG64, use:

    pacman -Syu mingw-w64-clang-x86_64-clang \
                mingw-w64-clang-x86_64-git \
                mingw-w64-clang-x86_64-openssl

For CLANG32, use:

    pacman -Syu mingw-w64-clang-i686-clang \
                mingw-w64-clang-i686-git \
                mingw-w64-clang-i686-openssl

For CLANGARM64, use (you need to use Git via another environment):

    pacman -Syu mingw-w64-clang-aarch64-clang mingw-w64-clang-aarch64-openssl

For MINGW64, use:

    pacman -Syu mingw-w64-x86_64-clang \
                mingw-w64-x86_64-git \
                mingw-w64-x86_64-openssl

For MINGW32, use:

    pacman -Syu mingw-w64-i686-clang \
                mingw-w64-i686-git \
                mingw-w64-i686-openssl

For UCRT64, use:

    pacman -Syu mingw-w64-ucrt-x86_64-clang \
                mingw-w64-ucrt-x86_64-git \
                mingw-w64-ucrt-x86_64-openssl

When using `pacman` to install the packages, `pacman` might tell you to close
the window. If it does so, close the window, restart MSYS2 and execute the
`pacman` command again.

There is nothing wrong with installing multiple environments, as MSYS2 has
created shortcuts for each of them in your start menu. Just make sure to use
the correct shortcut for the environment you want to use.

Finally, install a few more things that are common between all environments:

    pacman -S autoconf automake git make

Getting, building and installing ObjFW
--------------------------------------

Start the MSYS2 using the shortcut for the environment you want to use and
check out ObjFW:

    git clone https://git.nil.im/ObjFW/ObjFW

You can also download a release tarball if you want. Now `cd` to the newly
checked out repository and build and install it:

    ./autogen.sh && ./configure && make -j16 install

If everything was successful, you can now build projects using ObjFW for
Windows using the normal `objfw-compile` and friends.


Nintendo consoles
=================

Download and install [devkitPro](https://devkitpro.org/wiki/Getting_Started).

Nintendo DS
-----------

Follow the generic instructions, but instead of `./configure` run:

    ./configure --host=arm-none-eabi --with-nds

Nintendo 3DS
------------

  Follow the generic instructions, but instead of `./configure` run:

    ./configure --host=arm-none-eabi --with-3ds

Wii
---

  Follow the generic instructions, but instead of `./configure` run:

    ./configure --host=powerpc-eabi --with-wii

Wii U
-----

  Follow the generic instructions, but instead of `./configure` run:

    ./configure --host=powerpc-eabi --with-wii-u

Nintendo Switch
---------------

  Follow the generic instructions, but instead of `./configure` run:

    ./configure --host=aarch64-none-elf --with-nintendo-switch


Amiga
=====

Install [amiga-gcc](https://git.nil.im/amiga-gcc/amiga-gcc). Then follow the
generic instructions, but instead of `./configure` run:

    ./configure --host=m68k-amigaos
