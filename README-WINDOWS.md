ObjFW on Windows
================

This file contains instructions on how to get a working build environment to
compile and use ObjFW on Windows.


Prerequisites
=============

The first thing you need to install is MinGW. If you already have MinGW
installed, please *remove* it! ObjFW needs a GCC that emits DWARF-2 exception
handling code. SjLj is *not* supported, and this is what most MinGW builds use.


Installation
============

TDM-GCC
-------

Instead of using the official MinGW builds, we're going to use the TDM-GCC
builds, as these contain a version emitting DWARF-2 exception handling code.
Even when using TDM-GCC, most builds will output SjLj exceptions. This is why
we are going to use this
[installer](http://sourceforge.net/projects/tdm-gcc/files/TDM-GCC%20Installer/tdm-gcc-webdl.exe/download).

After downloading and starting the installer, we choose to create a new
installation. In the next step, the installer asks whether we want a
`MinGW/TDM` installation or a `MinGW-w64/TDM64 Experimental` installation. It
is very important to choose the `MinGW/TDM` installation, as `MinGW-w64/TDM64`
does *not* include GCC versions that output DWARF-2 exceptions! When asked for
an installation path, it is recommended to keep the default of `C:\MinGW32`;
the selected mirror does not really matter. After that, the components to be
installed have to be selected. Select `TDM-GCC Recommended, C/C++` as
installation type, then expand `Components` → `gcc` → `Version` and select the
TDM-GCC version ending in -dw2 and enable the `objc` checkbox. In the next step
the installer will start downloading and installing the selected components.


MSys
----

Next, we're going to install MSys. To do so, we're going to use the official
MinGW installer, but we are *not* going to install MinGW with it, so follow
these steps carefully. First, go to the [SourceForge download page for the
MinGW installer](http://sourceforge.net/projects/mingw/files/Installer/mingw-get-inst/)
and select the latest version. Get the .exe file there. When you launch it,
select the same installation path you selected for TDM-GCC before. After
selecting the installation directory, *deselect* all compilers and select
*only* `MSYS Basic System` and `MinGW Developer ToolKit`. Make sure `MinGW
Compiler Suite` is white and not grey! The installation progress bar will be
completely filled after a short while and it will appear to hang - this is
*not* the case. When it reaches that step, it starts downloading the required
files and installs them. Just give it some time.


Building ObjFW
==============

Building ObjFW for Windows works pretty much the same way it works on any other
operating system. The only thing you need to pay attention to is that the
TDM-GCC binary is called gcc-dw2. So all you need to do is `export OBJC=gcc-dw2`
before executing the usual `./autogen.sh && ./configure && make install`.


Troubleshooting
===============

If you are getting errors about no threads being available when typing `make`,
you've hit a bug present in some versions of Git for Windows. If you delete
your checkout and get a
[tarball](https://webkeks.org/git/?p=objfw.git;a=snapshot;h=HEAD;sf=tgz), it
should work.
