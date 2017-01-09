/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#include "config.h"

#include "platform.h"

#if defined(OF_ELF)
# if defined(OF_X86_64)
#  include "lookup-asm-x86_64-elf.S"
# elif defined(OF_X86)
#  include "lookup-asm-x86-elf.S"
# elif defined(OF_ARM64)
#  include "lookup-asm-arm64-elf.S"
# elif defined(OF_ARM)
#  include "lookup-asm-arm-elf.S"
# elif defined(OF_POWERPC)
#  include "lookup-asm-ppc-elf.S"
# elif defined(OF_MIPS64_N64)
#  include "lookup-asm-mips64-elf.S"
# elif defined(OF_MIPS)
#  include "lookup-asm-mips-elf.S"
# elif defined(OF_SPARC64)
#  include "lookup-asm-sparc64-elf.S"
# elif defined(OF_SPARC)
#  include "lookup-asm-sparc-elf.S"
# endif
#elif defined(OF_MACH_O)
# if defined(OF_X86_64)
#  include "lookup-asm-x86_64-macho.S"
# elif defined(OF_POWERPC)
#  include "lookup-asm-ppc-macho.S"
# endif
#elif defined(OF_WINDOWS)
# if defined(OF_X86_64)
#  include "lookup-asm-x86_64-win64.S"
# elif defined(OF_X86)
#  include "lookup-asm-x86-win32.S"
# endif
#endif
