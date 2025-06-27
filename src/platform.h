/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
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

#if (defined(__x86_64__) || defined(__amd64__)) && defined(__LP64__)
# define OF_AMD64
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
#elif defined(__hppa64__) || defined(_PA_RISC2_0)
# define OF_PA_RISC_2_0
#elif defined(__hppa__) || defined(_PA_RISC1_0) || defined(_PA_RISC1_1)
# define OF_PA_RISC
#elif defined(__ia64__) || defined(__IA64__)
# define OF_ITANIUM
#elif defined(__m68k__)
# define OF_M68K
# ifdef __mc68060__
#  define OF_M68060
# endif
# if defined(__mc68040__) || defined(OF_M68060)
#  define OF_M68040
# endif
# if defined(__mc68030__) || defined(OF_M68040)
#  define OF_M68030
# endif
# if defined(__mc68020__) || defined(OF_M68030)
#  define OF_M68020
# endif
# if defined(__mc68010__) || defined(OF_M68020)
#  define OF_M68010
# endif
#elif defined(__riscv) && defined(__riscv_xlen) && __riscv_xlen == 64
# define OF_RISCV64
#elif defined(__riscv)
# define OF_RISCV
#elif defined(__s390x__)
# define OF_S390X
#elif defined(__s390__)
# define OF_S390
#elif defined(__sh__)
# define OF_SUPERH
#elif defined(__e2k__)
# define OF_ELBRUS_2000
#elif defined(__loongarch64)
# define OF_LOONGARCH64
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
#elif defined(_AIX)
# define OF_AIX
#elif defined(__MORPHOS__)
# define OF_MORPHOS
# define OF_AMIGAOS
#elif defined(__amigaos4__)
# define OF_AMIGAOS4
# define OF_AMIGAOS
#elif defined(__amigaos__)
# define OF_AMIGAOS_M68K
# define OF_AMIGAOS
#elif defined(__sun__)
# define OF_SOLARIS
#elif defined(__QNX__)
# define OF_QNX
#elif defined(__hpux__)
# define OF_HPUX
#elif defined(_PSP)
# define OF_PSP
#elif defined(__DJGPP__)
# define OF_DJGPP
# define OF_MSDOS
#elif defined(__riscos__)
# define OF_ACORN_RISC_OS
#elif defined(__MINT__)
# define OF_MINT
#elif defined(__gnu_hurd__)
# define OF_HURD
#elif defined(__serenity__)
# define OF_SERENITYOS
#endif

#ifdef __GLIBC__
# define OF_GLIBC
#endif

#if defined(__ELF__)
# define OF_ELF
#elif defined(__MACH__)
# define OF_MACH_O
#endif

#if defined(__PIC__) || defined(__pic__)
# define OF_PIC
#endif
