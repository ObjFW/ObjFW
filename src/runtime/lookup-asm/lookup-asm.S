/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
 *   Jonathan Schleifer <js@webkeks.org>
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

#if defined(__ELF__)
# if defined(__amd64__) || defined(__x86_64__)
#  include "lookup-asm-amd64-elf.S"
# elif defined(__i386__)
#  include "lookup-asm-x86-elf.S"
# elif defined(__arm__) || defined(__ARM__)
#  include "lookup-asm-arm-elf.S"
# elif defined(__ppc__) || defined(__PPC__)
#  include "lookup-asm-ppc-elf.S"
# elif (defined(_MIPS_SIM) && _MIPS_SIM == _ABIO32) || \
	(defined(__mips_eabi) && _MIPS_SZPTR == 32)
#  include "lookup-asm-mips-elf.S"
# endif
#elif defined(__MACH__)
# if defined(__x86_64__)
#  include "lookup-asm-amd64-macho.S"
# elif defined(__ppc__)
#  include "lookup-asm-ppc-macho.S"
# endif
#elif defined(_WIN32)
# if defined(__i386__)
#  include "lookup-asm-x86-win32.S"
# endif
#endif
