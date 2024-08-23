Platforms
=========

ObjFW is known to work on the following platforms, but should run on many
others as well.

AmigaOS
-------

  * OS Versions: 3.1, 4.1 Final Edition Update 1
  * Architectures: m68k, PowerPC
  * Compilers: GCC 6.4.1b (amiga-gcc), GCC 8.3.0 (adtools)
  * Runtimes: ObjFW

Android
-------

  * OS Versions: 4.0.4, 4.1.2, 6.0.1
  * Architectures: ARMv6, ARMv7, ARM64
  * Compilers: Clang 3.3, Clang 3.8.0
  * Runtimes: ObjFW

Bare metal ARM Cortex-M4
------------------------

  * Architectures: ARMv7E-M
  * Compilers: Clang 3.5
  * Runtimes: ObjFW
  * Notes: Bootloader, libc (newlib) and possibly external RAM required

DOS
---

  * OS Versions: Windows XP DOS Emulation, DOSBox, MS-DOS 6.0, FreeDOS 1.2
  * Architectures: x86
  * Compilers: DJGPP GCC 4.7.3 (djdev204)
  * Runtimes: ObjFW

DragonFlyBSD
------------

  * OS Versions: 3.0, 3.3-DEVELOPMENT
  * Architectures: AMD64, x86
  * Compilers: GCC 4.4.7
  * Runtimes: ObjFW

FreeBSD
-------

  * OS Versions: 9.1-rc3, 10.0
  * Architectures: AMD64
  * Compilers: Clang 3.1, Clang 3.3
  * Runtimes: ObjFW

GNU/Hurd
--------

  * OS Versions: 0.9
  * Architectures: i686
  * Compilers: Clang 14.0.6
  * Runtimes: ObjFW

Haiku
-----

  * OS version: r1-alpha4
  * Architectures: x86
  * Compilers: Clang 3.2, GCC 4.6.3
  * Runtimes: ObjFW

HP-UX
-----

  * OS versions: 11i v1, 11i v3
  * Architectures: Itanium, PA-RISC 2.0
  * Compilers: GCC 4.7.2, GCC 7.5.0
  * Runtimes: ObjFW
  * Notes: Exception handling on Itanium in 32 bit mode is broken, you need to
           use 64 bit mode by passing `OBJC="gcc -mlp64"` to `configure`.

iOS
---

  * Architectures: ARMv7, ARM64
  * Compilers: Clang
  * Runtimes: Apple

Linux
-----

  * Architectures: Alpha, AMD64, ARMv5, ARMv6, ARMv7, ARM64, Itanium,
                   LoongArch 64, m68k, MIPS (O32), MIPS64 (N64), RISC-V 64,
                   PA-RISC, PowerPC, PowerPC 64, S390x, SuperH-4, x86
  * Compilers: Clang 3.0-18.1.1, GCC 4.6-14.1.1
  * C libraries: glibc, musl
  * Runtimes: ObjFW

macOS
-----

  * OS Versions: 10.5, 10.7-10.15, Darling
  * Architectures: AMD64, PowerPC, PowerPC64, x86
  * Compilers: Clang 3.1-10.0, Apple GCC 4.0.1 & 4.2.1
  * Runtimes: Apple, ObjFW

MiNT
----

  * OS Versions: FreeMiNT 1.19
  * Architectures: m68k
  * Runtimes: ObjFW
  * Compilers: GCC 4.6.4 (MiNT 20130415)
  * Limitations: No shared libraries, no threads

MorphOS
-------

  * OS Versions: 3.14
  * Architectures: PowerPC
  * Compilers: GCC 9.3.0
  * Runtimes: ObjFW

NetBSD
------

  * OS Versions: 5.1-9.0
  * Architectures: AMD64, ARM, ARM (big endian, BE8 mode), MIPS (O32), PowerPC,
                   SPARC, SPARC64, x86
  * Compilers: Clang 3.0-3.2, GCC 4.1.3 & 4.5.3 & 7.4.0
  * Runtimes: ObjFW

Nintendo 3DS
------------

  * OS Versions: 9.2.0-20E, 10.5.0-30E / Homebrew Channel 1.1.0
  * Architectures: ARM (EABI)
  * Compilers: GCC 5.3.0 (devkitARM release 45)
  * Runtimes: ObjFW
  * Limitations: No threads

Nintendo DS
-----------

  * Architectures: ARM (EABI)
  * Compilers: GCC 4.8.2 (devkitARM release 42)
  * Runtimes: ObjFW
  * Limitations: No threads, no sockets
  * Notes: File support requires an argv-compatible launcher (such as HBMenu)

Nintendo Switch
---------------

  * OS Versions: yuzu 1093
  * Architectures: AArch64
  * Compilers: GCC 12.1.0 (devkitA64 release 19) 
  * Runtimes: ObjFW
  * Limitations: No sockets, no shared libraries, not tested on real hardware

OpenBSD
-------

  * OS Versions: 5.2-6.7
  * Architectures: AMD64, MIPS64, PA-RISC, PowerPC, SPARC64
  * Compilers: GCC 6.3.0, Clang 4.0
  * Runtimes: ObjFW

PlayStation Portable
--------------------

  * OS Versions: 5.00 M33-4
  * Architectures: MIPS (EABI)
  * Compiler: GCC 4.6.2 (devkitPSP release 16)
  * Runtimes: ObjFW
  * Limitations: No threads, no sockets

QNX
---

  * OS Versions: 6.5.0
  * Architectures: x86
  * Compilers: GCC 4.6.1
  * Runtimes: ObjFW

Solaris
-------

  * OS Versions: OpenIndiana 2015.03, OpenIndiana 2023.04, Oracle Solaris 11.4
  * Architectures: AMD64, x86
  * Compilers: Clang 3.4.2, Clang 11.0.0, Clang 13.0.1, GCC 4.8.3, GCC 10.4.0
  * Runtimes: ObjFW

Wii
---

  * OS Versions: 4.3E / Homebrew Channel 1.1.0
  * Architectures: PowerPC
  * Compilers: GCC 4.6.3 (devkitPPC release 26)
  * Runtimes: ObjFW
  * Limitations: No threads

Wii U
-----

  * OS Versions: Cemu 12.26.2f
  * Architectures: PowerPC
  * Compilers: gcc version 12.1.0 (devkitPPC release 41)
  * Runtimes: ObjFW
  * Limitations: No files, no threads, no sockets, no shared libraries, not
                 tested on real hardware

Windows
-------

  * OS Versions: 98 SE, NT 4.0, XP, 7, 8, 8.1, 10, 11, Wine
  * Architectures: AArch64, AMD64, x86
  * Compilers: GCC 5.3.0 & 6.2.0 from msys2 (AMD64 & x86),
               Clang 3.9.0 from msys2 (x86),
               Clang 10.0 from msys2 (AMD64 & x86),
               Clang 14.0.4 from msys2 (AArch64)
  * Runtimes: ObjFW

Others
------

Basically, it should run on any POSIX system to which GCC >= 4.6 or a recent
Clang version has been ported. If not, please send an e-mail with a bug report.

If you successfully ran ObjFW on a platform not listed here, please send an
e-mail to js@nil.im so it can be added here!

If you have a platform on which ObjFW does not work, please contact me as well!

Forwarding
==========

As forwarding needs hand-written assembly for each combination of CPU
architecture, executable format and calling convention, it is only available
for the following platforms (except resolveClassMethod: and
resolveInstanceMethod:, which are always available):

  * AMD64 (SysV/ELF, Apple/Mach-O, Mach-O, Win64/PE)
  * ARM (EABI/ELF, Apple/Mach-O)
  * ARM64 (ARM64/ELF, Apple/Mach-O)
  * MIPS (O32/ELF, EABI/ELF)
  * PowerPC (SysV/ELF, EABI/ELF, Apple/Mach-O)
  * SPARC (SysV/ELF)
  * SPARC64 (SysV/ELF)
  * x86 (SysV/ELF, Apple/Mach-O, Win32/PE)

Apple/Mach-O means both, the Apple ABI and runtime, while Mach-O means the
ObjFW runtime on Mach-O.
