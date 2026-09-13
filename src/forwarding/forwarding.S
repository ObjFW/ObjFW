/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#include "config.h"

#include "platform.h"

#ifdef OF_APPLE_RUNTIME
# if defined(OF_AMD64)
#  include "apple-forwarding-amd64.S"
# elif defined(OF_X86)
#  include "apple-forwarding-x86.S"
# elif defined(OF_ARM64)
#  include "apple-forwarding-arm64.S"
# elif defined(OF_ARM)
#  include "apple-forwarding-arm.S"
# elif defined(OF_POWERPC)
#  include "apple-forwarding-powerpc.S"
# endif
#else
# if defined(OF_ELF)
#  if defined(OF_AMD64)
#   include "forwarding-amd64-elf.S"
#  elif defined(OF_X86)
#   include "forwarding-x86-elf.S"
#  elif defined(OF_ARM64)
#   include "forwarding-arm64-elf.S"
#  elif defined(OF_ARM)
#   include "forwarding-arm-elf.S"
#  elif defined(OF_POWERPC)
#   include "forwarding-powerpc-elf.S"
#  elif defined(OF_POWERPC64)
#   if defined(_CALL_ELF) && _CALL_ELF == 2
#    include "forwarding-powerpc64-elf-v2.S"
#   else
#    include "forwarding-powerpc64-elf.S"
#   endif
#  elif defined(OF_MIPS64_N64)
#   include "forwarding-mips64-n64-elf.S"
#  elif defined(OF_MIPS)
#   include "forwarding-mips-elf.S"
#  elif defined(OF_SPARC64)
#   include "forwarding-sparc64-elf.S"
#  elif defined(OF_SPARC)
#   include "forwarding-sparc-elf.S"
#  elif defined(OF_RISCV64)
#   include "forwarding-riscv64-elf.S"
#  elif defined(OF_LOONGARCH64)
#   include "forwarding-loongarch64-elf.S"
#  endif
# elif defined(OF_MACH_O)
#  if defined(OF_AMD64)
#   include "forwarding-amd64-macho.S"
#  endif
# elif defined(OF_WINDOWS)
#  if defined(OF_AMD64)
#   include "forwarding-amd64-win64.S"
#  elif defined(OF_X86)
#   include "forwarding-x86-win32.S"
#  elif defined(OF_ARM64)
#   include "forwarding-arm64-win64.S"
#  endif
# endif
#endif
