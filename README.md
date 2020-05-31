There are three ways you are probably reading this right now:

 * On [ObjFW](https://objfw.nil.im/)'s homepage, via Fossil
 * On [GitHub](https://github.com/ObjFW/ObjFW)
 * Via an editor or pager, by opening `README.md` from a checkout or tarball

ObjFW is developed using Fossil, so if you are reading this on GitHub or any
other place, you are most likely using a mirror.


<h1 id="table-of-contents">Table of Contents</h1>

 * [What is ObjFW?](#what)
 * [License](#license)
 * [Installation](#installation)
   * [macOS and iOS](#macos-and-ios)
     * [Building as a framework](#building-framework)
     * [Using the macOS or iOS framework in Xcode](#framework-in-xcode)
     * [Broken Xcode versions](#broken-xcode-versions)
   * [Windows](#windows)
     * [Getting MSYS2](#getting-msys2)
     * [Updating MSYS2](#updating-msys2)
     * [Installing MinGW-w64 using MSYS2](#installing-mingw-w64)
     * [Getting, building and installing ObjFW](#steps-windows)
   * [Nintendo DS, Nintendo 3DS and Wii](#nintendo)
     * [Nintendo DS](#nintendo-ds)
     * [Nintendo 3DS](#nintendo-3ds)
     * [Wii](#wii)
   * [Amiga](#amiga)
 * [Writing your first application with ObjFW](#first-app)
 * [Bugs and feature requests](#bugs)
 * [Support and community](#support)
 * [Commercial use](#commercial-use)


<h1 id="what">What is ObjFW?</h1>

  ObjFW is a portable, lightweight framework for the Objective-C language. It
  enables you to write an application in Objective-C that will run on any
  [platform](PLATFORMS.md) supported by ObjFW without having to worry about
  differences between operating systems or various frameworks you would
  otherwise need if you want to be portable.

  It supports all modern Objective-C features when using Clang, but is also
  compatible with GCC ≥ 4.6 to allow maximum portability.

  ObjFW is intentionally incompatible with Foundation. This has two reasons:

   * GNUstep already provides a reimplementation of Foundation, which is only
     compatible to a certain degree. This means that a developer still needs to
     care about differences between frameworks if they want to be portable. The
     idea behind ObjFW is that a developer does not need to concern themselves
     with portablility and making sure their code works with multiple
     frameworks: Instead, if it works it ObjFW on one platform, they can
     reasonably expect it to also work with ObjFW on another platform. ObjFW
     behaving differently on different operating systems (unless inevitable
     because it is a platform-specific part, like the Windows Registry) is
     considered a bug and will be fixed.
   * Foundation predates a lot of modern Objective-C concepts. The most
     prominent one is exceptions, which are only used in Foundation as a
     replacement for `abort()`. This results in cumbersome error handling,
     especially in initializers, which in Foundation only return `nil` on error
     with no indication of what went wrong. It also means that the return of
     every `init` call needs to be checked against `nil`. But in the wild,
     nobody actually checks *each and every* return from `init` against `nil`,
     leading to bugs. ObjFW fixes this by making exceptions a first class
     citizen.

  ObjFW also comes with its own lightweight and extremely fast Objective-C
  runtime, which in real world use cases was found to be significantly faster
  than both GNU's and Apple's runtime.


<h1 id="license">License</h1>

  ObjFW is released under three licenses:

   * [QPL](LICENSE.QPL)
   * [GPLv2](LICENSE.GPLv2)
   * [GPLv3](LICENSE.GPLv3)

  The QPL allows you to use ObjFW in any open source project. Because the GPL
  does not allow using code under any other license, ObjFW is also available
  under the GPLv2 and GPLv3 to allow GPL-licensed projects to use ObjFW.

  You can pick under which of those three licenses you want to use ObjFW. If
  none of them work for you, contact me and we can find a solution.


<h1 id="installation">Installation</h1>

  To install ObjFW, just run the following commands:

    $ ./configure
    $ make
    $ make install

  In case you checked out ObjFW from the Fossil or Git repository, you need to
  run the following command first:

    $ ./autogen.sh

<h2 id="macos-and-ios">macOS and iOS</h2>

<h3 id="building-framework">Building as a framework</h3>

  When building for macOS or iOS, everything is built as a `.framework` by
  default if `--disable-shared` has not been specified to `configure`.

  To build for iOS, use something like this:

    $ clang="clang -isysroot $(xcrun --sdk iphoneos --show-sdk-path)"
    $ export OBJC="$clang -arch armv7 -arch arm64"
    $ export OBJCPP="$clang -arch armv7 -E"
    $ export IPHONEOS_DEPLOYMENT_TARGET="9.0"
    $ ./configure --prefix=/usr/local/ios --host=arm-apple-darwin

  To build for the iOS simulator, use something like this:

    $ clang="clang -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path)"
    $ export OBJC="$clang -arch i386 -arch x86_64"
    $ export OBJCPP="$clang -arch i386 -E"
    $ export IPHONEOS_DEPLOYMENT_TARGET="9.0"
    $ ./configure --prefix=/usr/local/iossim --host=i386-apple-darwin

<h3 id="framework-in-xcode">Using the macOS or iOS framework in Xcode</h3>

  To use the macOS framework in Xcode, you need to add the `.framework`s to
  your project and add the following flags to `Other C Flags`:

    -fconstant-string-class=OFConstantString -fno-constant-cfstrings

<h3 id="broken-xcode-versions">Broken Xcode versions</h3>

  Some versions of Xcode shipped with a version of Clang that ignores
  `-fconstant-string-class=OFConstantString`. This will manifest in an error
  like this:

    OFAllocFailedException.m:94:10: error: cannot find interface declaration for
          'NSConstantString'
            return @"Allocating an object failed!";
                    ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    1 error generated.

  Unfortunately, there is no workaround for this other than to
  upgrade/downgrade Xcode or to build upstream Clang yourself.

  In particular, Xcode 11 Beta 1 to Beta 3 are known to be affected. While
  Xcode 11 Beta 4 to Xcode 11.3 work, the bug was unfortunately reintroduced in
  Xcode 11.4.1 and a fix is not expected before Xcode 11.6.

  You can get older versions of Xcode
  [here](https://developer.apple.com/download) by clicking on "More" in the
  top-right corner.

<h2 id='windows'>Windows</h2>

  Windows is only officially supported when following these instructions, as
  there are many MinGW versions that behave slightly differently and often
  cause problems.

<h3 id="getting-msys2">Getting MSYS2</h3>

  The first thing to install is [MSYS2](https://www.msys2.org) to provide a
  basic UNIX-like environment for Windows. Unfortunately, the binaries are not
  signed and there is no way to verify their integrity, so only download this
  from a trusted connection. Everything else you will download using MSYS2
  later will be cryptographically signed.

<h3 id="updating-msys2">Updating MSYS2</h3>

  The first thing to do is updating MSYS2. It is important to update things in
  a certain order, as `pacman` (the package manager MSYS2 uses, which comes
  from Arch Linux) does not know about a few things that are special on
  Windows.

  First, update the mirror list:

    $ pacman -Sy pacman-mirrors

  Then proceed to update the `msys2-runtime` itself, `bash` and `pacman`:

    $ pacman -S msys2-runtime bash pacman mintty

  Now close the current window and restart MSYS2, as the current window is now
  defunct. In a new MSYS2 window, update the rest of MSYS2:

    $ pacman -Su

  Now you have a fully updated MSYS2. Whenever you want to update MSYS2,
  proceed in this order. Notice that the first `pacman` invocation includes
  `-y` to actually fetch a new list of packages.

<h3 id="installing-mingw-w64">Installing MinGW-w64 using MSYS2</h3>

  Now it's time to install MinGW-w64. If you want to build 32 bit binaries:

    $ pacman -S mingw-w64-i686-clang mingw-w64-i686-gcc-objc

  For 64 bit binaries:

    $ pacman -S mingw-w64-x86_64-clang mingw-w64-x86_64-gcc-objc

  There is nothing wrong with installing them both, as MSYS2 has created two
  entries in your start menu: `MinGW-w64 Win32 Shell` and `MinGW-w64 Win64
  Shell`. So if you want to build for 32 or 64 bit, you just start the correct
  shell.

  Finally, install a few more things needed to build ObjFW:

    $ pacman -S autoconf automake fossil make

<h3 id="steps-windows">Getting, building and installing ObjFW</h3>

  Start the MinGW-w64 Win32 or Win64 Shell (depening on what version you want
  to build - do *not* use the MSYS2 Shell shortcut, but use the MinGW-w64 Win32
  or Win64 Shell shortcut instead!) and check out ObjFW:

    $ fossil clone https://objfw.nil.im objfw.fossil
    $ mkdir objfw && cd objfw
    $ fossil open ../objfw.fossil

  You can also download a release tarball if you want. Now go to the newly
  checked out repository and build and install it:

    $ ./autogen.sh && ./configure && make -j16 install

  If everything was successfully, you can now build projects using ObjFW for
  Windows using the normal `objfw-compile` and friends.

<h2 id="nintendo">Nintendo DS, Nintendo 3DS and Wii</h2>

  Download and install [devkitPro](https://devkitpro.org/wiki/Getting_Started).

<h3 id="nintendo-ds">Nintendo DS</h3>

  Follow the normal process, but instead of `./configure` run:

    $ ./configure --host=arm-none-eabi --with-nds

<h3 id="nintendo-3ds">Nintendo 3DS</h3>

  Follow the normal process, but instead of `./configure` run:

    $ ./configure --host=arm-none-eabi --with-3ds

<h3 id="wii">Wii</h3>

  Follow the normal process, but instead of `./configure` run:

    $ ./configure --host=powerpc-eabi --with-wii

<h2 id="amiga">Amiga</h2>

  Install [amiga-gcc](https://github.com/bebbo/amiga-gcc). Then follow the
  normal process, but instead of `./configure` run:

    $ ./configure --host=m68k-amigaos


<h1 id="first-app">Writing your first application with ObjFW</h1>

  To create your first, empty application, you can use `objfw-new`:

    $ objfw-new app MyFirstApp

  This creates a file `MyFirstApp.m`. The `-[applicationDidFinishLaunching]`
  method is called as soon as ObjFW finished all initialization. Use this as
  the entry point to your own code. For example, you could add the following
  line there to create a "Hello World":

    [of_stdout writeLine: @"Hello World!"];

  You can compile your new app using `objfw-compile`:

    $ objfw-compile -o MyFirstApp MyFirstApp.m

  `objfw-compile` is a tool that allows building applications and libraries
  using ObjFW without needing a full-blown build system. If you want to use
  your own build system, you can get the necessary flags from `objfw-config`.


<h1 id="bugs">Bugs and feature requests</h1>

  If you find any bugs or have feature requests, feel free to send a mail to
  js@nil.im!


<h1 id="support">Support and community</h1>

  If you have any questions about ObjFW or would like to talk to other ObjFW
  users, the following venues are available:

   * The [forum](https://objfw.nil.im/forum)
   * A [Matrix](https://matrix.to/#/%23objfw:nil.im) room
   * An [IRC channel](irc://chat.freenode.net/#objfw) on Freenode (`#objfw`),
     bridged to the Matrix room above

  Please don't hesitate to join any or all of those!


<h1 id="commercial-use">Commercial use</h1>

  If for whatever reason neither the terms of the QPL nor those of the GPL work
  for you, a proprietary license for ObjFW including support is available upon
  request. Just write a mail to js@nil.im and we can find a reasonable solution
  for both parties.
