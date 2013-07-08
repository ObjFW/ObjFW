/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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
#  include "lookup-amd64-elf.S"
# elif defined(__i386__)
#  include "lookup-x86-elf.S"
# elif defined(__ppc__) || defined(__PPC__)
#  include "lookup-ppc-elf.S"
# elif defined(__arm__) || defined(__ARM__)
#  include "lookup-arm-elf.S"
# elif defined(__mips) && __mips < 64
#  include "lookup-mips-elf.S"
# endif
#elif defined(__MACH__)
# if defined(__amd64__) || defined(__x86_64__)
#  include "lookup-amd64-macho.S"
# endif
#endif
