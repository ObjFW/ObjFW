/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#if defined(OF_ELF)
# if defined(OF_AMD64)
#  include "lookup-asm-amd64-elf.S"
# elif defined(OF_X86)
#  include "lookup-asm-x86-elf.S"
# elif defined(OF_ARM64)
#  include "lookup-asm-arm64-elf.S"
# elif defined(OF_ARM)
#  include "lookup-asm-arm-elf.S"
# elif defined(OF_POWERPC64)
#  include "lookup-asm-powerpc64-elf.S"
# elif defined(OF_POWERPC)
#  include "lookup-asm-powerpc-elf.S"
# elif defined(OF_MIPS64_N64)
#  include "lookup-asm-mips64-n64-elf.S"
# elif defined(OF_MIPS)
#  include "lookup-asm-mips-elf.S"
# elif defined(OF_SPARC64)
#  include "lookup-asm-sparc64-elf.S"
# elif defined(OF_SPARC)
#  include "lookup-asm-sparc-elf.S"
# elif defined(OF_RISCV64)
#  include "lookup-asm-riscv64-elf.S"
# elif defined(OF_LOONGARCH64)
#  include "lookup-asm-loongarch64-elf.S"
# endif
#elif defined(OF_MACH_O)
# if defined(OF_AMD64)
#  include "lookup-asm-amd64-macho.S"
# endif
#elif defined(OF_WINDOWS)
# if defined(OF_AMD64)
#  include "lookup-asm-amd64-win64.S"
# elif defined(OF_X86)
#  include "lookup-asm-x86-win32.S"
# elif defined(OF_ARM64)
#  include "lookup-asm-arm64-win64.S"
# endif
#endif
