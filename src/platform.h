/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
 *   Jonathan Schleifer <js@heap.zone>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#include "objfw-defs.h"

/* Required to build universal binaries on OS X */
#ifdef OF_UNIVERSAL
# if __BIG_ENDIAN__
#  define OF_BIG_ENDIAN
#  define OF_FLOAT_BIG_ENDIAN
# elif !__LITTLE_ENDIAN__
#  error OF_UNIVERSAL defined, but neither __BIG_ENDIAN__ nor __LITTLE_ENDIAN__!
# endif
#endif

#if defined(__x86_64__) || defined(__amd64__)
# define OF_X86_64
#elif defined(__i386__)
# define OF_X86
#elif defined(__powerpc64__) || defined(__ppc64__) || defined(__PPC64__)
# define OF_POWERPC64
#elif defined(__powerpc__) || defined(__ppc__) || defined(__PPC__)
# define OF_POWERPC
#elif defined(__arm64__) || defined(__aarch64__) || defined(__ARM64_ARCH_8__)
# define OF_ARM64
#elif defined(__arm__) || defined(__ARM__)
# define OF_ARM
# if defined(__ARM_ARCH_7__) || defined(__ARM_ARCH_7A__) || \
    defined(__ARM_ARCH_7R__) || defined(__ARM_ARCH_7M__) || \
    defined(__ARM_ARCH_7EM__)
#  define OF_ARMV7
# endif
# if defined(OF_ARMV7) || defined(__ARM_ARCH_6__) || \
    defined(__ARM_ARCH_6J__) || defined(__ARM_ARCH_6K__) || \
    defined(__ARM_ARCH_6Z__) || defined(__ARM_ARCH_6ZK__) || \
    defined(__ARM_ARCH_6T2__)
#  define OF_ARMV6
# endif
#elif defined(_MIPS_SIM)
# if _MIPS_SIM == _ABI64
#  define OF_MIPS64
#  define OF_MIPS64_N64
# elif _MIPS_SIM == _ABIN32
#  define OF_MIPS64
#  define OF_MIPS64_N32
# elif _MIPS_SIM == _ABIO32
#  define OF_MIPS
#  define OF_MIPS_O32
# endif
#elif defined(__mips_eabi) && _MIPS_SZPTR == 32
# define OF_MIPS
# define OF_MIPS_EABI
#elif defined(__sparc64__) || (defined(__sparc__) && defined(__arch64__))
# define OF_SPARC64
#elif defined(__sparc__) && !defined(__arch64__)
# define OF_SPARC
#elif defined(__hppa__) || defined(__HPPA__) || \
    defined(_PA_RISC1_0) || defined(_PA_RISC1_1)
# define OF_PA_RISC
#elif defined(__ia64__) || defined(__IA64__)
# define OF_ITANIUM
#endif

#if defined(__APPLE__)
# include <TargetConditionals.h>
# if (defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE) || \
    (defined(TARGET_OS_SIMULATOR) && TARGET_OS_SIMULATOR)
#  define OF_IOS
# else
#  define OF_MACOS
# endif
#elif defined(__linux__)
# define OF_LINUX
#elif defined(_WIN32)
# define OF_WINDOWS
#elif defined(__FreeBSD__)
# define OF_FREEBSD
#elif defined(__NetBSD__)
# define OF_NETBSD
#elif defined(__OpenBSD__)
# define OF_OPENBSD
#elif defined(__DragonFly__)
# define OF_DRAGONFLYBSD
#elif defined(__ANDROID__)
# define OF_ANDROID
#elif defined(__HAIKU__)
# define OF_HAIKU
#elif defined(__MORPHOS__)
# ifndef __ixemul__
#  define OF_MORPHOS
#  define OF_AMIGAOS_LIKE
# else
#  define OF_MORPHOS_IXEMUL
# endif
#elif defined(__sun__)
# define OF_SOLARIS
#elif defined(__QNX__)
# define OF_QNX
#elif defined(__wii__)
# define OF_WII
#elif defined(_PSP)
# define OF_PSP
#elif defined(__DJGPP__)
# define OF_DJGPP
# define OF_MSDOS
#endif

#if defined(__ELF__)
# define OF_ELF
#elif defined(__MACH__)
# define OF_MACH_O
#endif

#if defined(__PIC__) || defined(__pic__)
# define OF_PIC
#endif
