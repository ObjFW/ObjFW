ObjFW on Windows
================

  This file contains instructions on how to get a working build environment to
  compile and use ObjFW on Windows.


Getting MSYS2
-------------

  The first thing to install is [MSYS2](https://msys2.github.io) to provide a
  basic UNIX-like environment for Windows. Unfortunately, the binaries are not
  signed and there is no way to verify their integrity, so only download this
  from a trusted connection. Everything else you will download using MSYS2
  later will be cryptographically signed.


Updating MSYS2
--------------

  The first thing to do is updating MSYS2. It is important to update things in
  a certain order, as `pacman` (the package manager MSYS2 uses, which comes
  from ArchLinux) does not know about a few things that are special on Windows.

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


Installing MinGW-w64 using MSYS2
--------------------------------

  Now it's time to install MinGW-w64. If you want to build 32 bit binaries:

    $ pacman -S mingw-w64-i686-clang mingw-w64-i686-gcc-objc

  For 64 bit binaries:

    $ pacman -S mingw-w64-x86_64-clang mingw-w64-x86_64-gcc-objc

  There is nothing wrong with installing them both, as MSYS2 has created two
  entries in your start menu: `MinGW-w64 Win32 Shell` and
  `MinGW-w64 Win64 Shell`. So if you want to build for 32 or 64 bit, you just
  start the correct shell.

  Finally, install a few more things needed to build ObjFW:

    $ pacman -S autoconf automake git make


Getting, building and installing ObjFW
--------------------------------------

  Start the MinGW-w64 Win32 or Win64 Shell (depening on what version you want
  to build - do *not* use the MSYS2 Shell shortcut, but use the MinGW-w64 Win32
  or Win64 Shell shortcut instead!) and check out ObjFW:

    $ git clone https://heap.zone/git/objfw.git

  You can also download a release tarball if you want. Now go to the newly
  checked out repository and build and install it:

    $ ./autogen.sh && ./configure && make -j16 install

  If everything was successfully, you can now build projects using ObjFW for
  Windows using the normal `objfw-compile` and friends.
