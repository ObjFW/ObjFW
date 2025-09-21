Packages
========

ObjFW packages are available for various operating systems and can be installed
as following:

Operating System           | Command
---------------------------|------------------------------------------------
Alpine Linux               | `doas apk add objfw`
CRUX                       | `sudo prt-get depinst objfw`
Debian                     | `sudo apt install objfw`
Fedora                     | `sudo dnf install objfw`
FreeBSD                    | `sudo pkg install objfw`
Haiku                      | `pkgman install objfw`
Haiku (gcc2h)              | `pkgman install objfw_x86`
macOS (Homebrew)           | `brew install objfw`
macOS (pkgsrc)             | `cd $PKGSRCDIR/devel/objfw && make install`
NetBSD                     | `cd /usr/pkgsrc/devel/objfw && make install`
OpenBSD                    | `doas pkg_add objfw`
OpenIndiana                | `sudo pkg install developer/objfw`
Ubuntu                     | `sudo apt install objfw`
Windows (MSYS2/CLANG64)    | `pacman -S mingw-w64-clang-x86_64-objfw`
Windows (MSYS2/CLANGARM64) | `pacman -S mingw-w64-clang-aarch64-objfw`
Windows (MSYS2/UCRT64)     | `pacman -S mingw-w64-ucrt-x86_64-{objfw,clang}`
Windows (MSYS2/MINGW64)    | `pacman -S mingw-w64-x86_64-{objfw,clang}`

If your operating system is not listed, you can
[build ObjFW from source](COMPILING.md).


Packaging Status
================

[![Packaging status](https://repology.org/badge/vertical-allrepos/objfw.svg)](https://repology.org/project/objfw/versions)
