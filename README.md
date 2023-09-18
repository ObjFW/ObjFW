There are three ways you are probably reading this right now:

 * On [ObjFW](https://objfw.nil.im/)'s homepage, via Fossil's web interface
 * On [GitHub](https://github.com/ObjFW/ObjFW)
 * Via an editor or pager, by opening `README.md` from a clone or tarball

ObjFW is developed using Fossil, so if you are reading this on GitHub or any
other place, you are most likely using a mirror.


<h1 id="table-of-contents">Table of Contents</h1>

 * [What is ObjFW?](#what)
 * [Installation](#installation)
 * [License](#license)
 * [Releases](#releases)
 * [Cloning the repository](#cloning)
 * [Building from source](#building-from-source)
   * [macOS and iOS](#macos-and-ios)
     * [Building as a framework](#building-framework)
     * [Using the macOS or iOS framework in Xcode](#framework-in-xcode)
     * [Broken Xcode versions](#broken-xcode-versions)
   * [Windows](#windows)
     * [Getting MSYS2](#getting-msys2)
     * [Setting up MSYS2](#setting-up-msys2)
     * [Getting, building and installing ObjFW](#steps-windows)
   * [Nintendo DS, Nintendo 3DS and Wii](#nintendo)
     * [Nintendo DS](#nintendo-ds)
     * [Nintendo 3DS](#nintendo-3ds)
     * [Wii](#wii)
   * [Amiga](#amiga)
 * [Writing your first application with ObjFW](#first-app)
 * [Documentation](#documentation)
 * [Bugs and feature requests](#bugs)
 * [Support and community](#support)
 * [Donating](#donating)
 * [Thanks](#thanks)
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


<h1 id="installation">Installation</h1>

  ObjFW packages are available for various operating systems and can be
  installed as following:

  Operating System  | Command
  ------------------|---------------------------------------------
  Alpine Linux Edge | `doas apk add objfw`
  CRUX              | `sudo prt-get depinst objfw`
  Fedora            | `sudo dnf install objfw`
  FreeBSD           | `sudo pkg install objfw`
  macOS (Homebrew)  | `brew install objfw`
  macOS (pkgsrc)    | `cd $PKGSRCDIR/devel/objfw && make install`
  NetBSD            | `cd /usr/pkgsrc/devel/objfw && make install`
  OpenBSD           | `doas pkg_add objfw`

  If your operating system is not listed, you can
  <a href="#building-from-source">build ObjFW from source</a>.  


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


<h1 id="releases">Releases</h1>

  Releases of ObjFW, as well as change logs and the accompanying documentation,
  can be found [here](https://objfw.nil.im/wiki?name=Releases).


<h1 id="cloning">Cloning the repository</h1>

  ObjFW is developed in a [Fossil](https://fossil-scm.org) repository, with
  automatic incremental exports to Git. This means you can either clone the
  Fossil repository or the Git repository - it does not make a huge difference.
  The main advantage of cloning the Fossil repository over cloning the Git
  repository is that you also get all the tickets, wiki pages, etc.

<h2 id="cloning-fossil">Fossil</h2>

  Clone the Fossil repository like this:

    $ fossil clone https://objfw.nil.im

  You can then use Fossil's web interface to browse the timeline, tickets,
  wiki pages, etc.:

    $ cd objfw
    $ fossil ui

  It's also possible to open the same local repository multiple times, so that
  you have multiple working directories all backed by the same local
  repository.

  In order to verify the signature of the currently checked out checkin, you
  can use:

    $ fossil artifact current | gpg --verify

  Please note that not all checkins are signed, as the signing key only resides
  on trusted systems. This means that checkins I perform on e.g. Windows are
  unsigned. However, usually it should not take long until there is another
  signed checkin. Alternatively, you can go back until the last signed checkin
  and review changes from there on.

<h2 id="cloning-git">Git</h2>

  To clone the Git repository, use the following:

    $ git clone https://github.com/ObjFW/ObjFW

  Git commits are not signed, so if you want to check the signature of an
  individual commit, branch head or tag, please use Fossil.

<h1 id="building-from-source">Building from source</h1>

  To build ObjFW from source and install it, just run the following commands:

    $ ./configure
    $ make
    $ make check
    $ sudo make install

  In case you checked out ObjFW from the Fossil or Git repository, you need to
  run the following command first:

    $ ./autogen.sh

<h2 id="macos-and-ios">macOS and iOS</h2>

<h3 id="building-framework">Building as a framework</h3>

  When building for macOS or iOS, everything is built as a `.framework` by
  default if `--disable-shared` has not been specified to `./configure`. The
  frameworks will end up in `$PREFIX/Library/Frameworks`.

  To build for macOS, just follow the
  <a href="#building-from-source">regular instructions</a> above.

  To build for iOS, follow the regular instructions, but instead of
  `./configure` do something like this:

    $ clang="xcrun --sdk iphoneos clang"
    $ export OBJC="$clang -arch arm64e -arch arm64"
    $ export OBJCPP="$clang -arch arm64e -E"
    $ export IPHONEOS_DEPLOYMENT_TARGET="10.0"
    $ ./configure --prefix=/usr/local/ios --host=arm64-apple-darwin

  To build for the iOS simulator, follow the regular instructions, but instead
  of `./configure` use something like this:

    $ clang="xcrun --sdk iphonesimulator clang"
    $ export OBJC="$clang -arch $(uname -m)"
    $ export IPHONEOS_DEPLOYMENT_TARGET="10.0"
    $ ./configure --prefix=/usr/local/iossim --host=$(uname -m)-apple-darwin

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
  Xcode 11.4.1 and was only fixed in Xcode 12 Beta 1.

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
  signed, so make sure you download it via HTTPS. However, packages you
  download and install via MSYS2 are cryptographically signed.

<h3 id="setting-up-msys2">Setting up MSYS2</h3>

  MSYS2 currently supports 7 different
  [environments](https://www.msys2.org/docs/environments/). All of them except
  for the one called just "MSYS" are supported, but which packages you need to
  install depends on the environment(s) you want to use. If you only want to
  target Windows 10 and newer, the CLANG64 and CLANG32 environments are the
  recommended ones.

  For CLANG64, use:

    $ pacman -Syu mingw-w64-clang-x86_64-clang mingw-w64-clang-x86_64-fossil

  For CLANG32, use:

    $ pacman -Syu mingw-w64-clang-i686-clang mingw-w64-clang-i686-fossil

  For CLANGARM64, use (you need to use Fossil via another environment):

    $ pacman -Syu mingw-w64-clang-aarch64-clang

  For MINGW64, use:

    $ pacman -Syu mingw-w64-x86_64-clang mingw-w64-x86_64-fossil

  For MINGW32, use:

    $ pacman -Syu mingw-w64-i686-clang mingw-w64-i686-fossil

  For UCRT64, use:

    $ pacman -Syu mingw-w64-ucrt-x86_64-clang mingw-w64-ucrt-x86_64-fossil

  When using `pacman` to install the packages, `pacman` might tell you to close
  the window. If it does so, close the window, restart MSYS2 and execute the
  `pacman` command again.

  There is nothing wrong with installing multiple environments, as MSYS2 has
  created shortcuts for each of them in your start menu. Just make sure to use
  the correct shortcut for the environment you want to use.

  Finally, install a few more things that are common between all environments:

    $ pacman -S autoconf automake make

<h3 id="steps-windows">Getting, building and installing ObjFW</h3>

  Start the MSYS2 using the shortcut for the environment you want to use and
  check out ObjFW:

    $ fossil clone https://objfw.nil.im

  You can also download a release tarball if you want. Now `cd` to the newly
  checked out repository and build and install it:

    $ ./autogen.sh && ./configure && make -j16 install

  If everything was successful, you can now build projects using ObjFW for
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

    $ objfw-new --app MyFirstApp

  This creates a file `MyFirstApp.m`. The `-[applicationDidFinishLaunching:]`
  method is called as soon as ObjFW finished all initialization. Use this as
  the entry point to your own code. For example, you could add the following
  line there to create a "Hello World":

    [OFStdOut writeLine: @"Hello World!"];

  You can compile your new app using `objfw-compile`:

    $ objfw-compile -o MyFirstApp MyFirstApp.m

  `objfw-compile` is a tool that allows building applications and libraries
  using ObjFW without needing a full-blown build system. If you want to use
  your own build system, you can get the necessary flags from `objfw-config`.


<h1 id="documentation">Documentation</h1>

  You can find the documentation for released versions of ObjFW
  [here](https://objfw.nil.im/docs/).

  In order to build the documentation yourself (necessary to have documentation
  for trunk / master), you need to have [Doxygen](https://www.doxygen.nl)
  installed. Once installed, you can build the documentation from the root
  directory of the repository:

    $ make docs


<h1 id="bugs">Bugs and feature requests</h1>

  If you find any bugs or have feature requests, please
  [file a new bug](https://objfw.nil.im/tktnew) in the
  [bug tracker](https://objfw.nil.im/reportlist).

  Alternatively, feel free to send a mail to js@nil.im!


<h1 id="support">Support and community</h1>

  If you have any questions about ObjFW or would like to talk to other ObjFW
  users, the following venues are available:

   * The [forum](https://objfw.nil.im/forum)
   * A [Matrix room](https://matrix.to/#/%23objfw:nil.im)
   * An IRC channel named `#objfw` on `irc.oftc.net`
     ([Web chat](https://webchat.oftc.net/?channels=%23objfw)), bridged to the
     Matrix room above
   * A [Slack channel](https://objfw.nil.im/slack), bridged to the Matrix room
     above
   * A [Discord channel](https://objfw.nil.im/discord), bridged to the Matrix
     room above
   * A [Telegram room](https://t.me/objfw), bridged to the Matrix room above
   * A [Gitter room](https://gitter.im/ObjFW/ObjFW), bridged to the Matrix room
     above

  Please don't hesitate to join any or all of those!


<h1 id="donating">Donating</h1>

  If you want to donate to ObjFW, you can read about possible ways to do so
  [here](https://objfw.nil.im/wiki?name=Donating).


<h1 id="thanks">Thanks</h1>

  * Thank you to [Jonathan Neuschäfer](https://github.com/neuschaefer) for
    reviewing the *entirety* (all 84k LoC at the time) of ObjFW's codebase in
    2017!
  * Thank you to [Hill Ma](https://github.com/mahiuchun) for donating an M1 Mac
    Mini to the project in 2022!


<h1 id="commercial-use">Commercial use</h1>

  If for whatever reason neither the terms of the QPL nor those of the GPL work
  for you, a proprietary license for ObjFW including support is available upon
  request. Just write a mail to js@nil.im and we can find a reasonable solution
  for both parties.
