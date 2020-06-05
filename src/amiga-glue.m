/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#import "amiga-library.h"
#import "platform.h"

#ifdef OF_AMIGAOS_M68K
# define PPC_PARAMS(...) (void)
# define M68K_ARG OF_M68K_ARG
#else
# define PPC_PARAMS(...) (__VA_ARGS__)
# define M68K_ARG(...)
#endif

#ifdef OF_MORPHOS
/* All __saveds functions in this file need to use the SysV ABI */
__asm__ (
    ".section .text\n"
    ".align 2\n"
    "__restore_r13:\n"
    "	lwz	%r13, 44(%r12)\n"
    "	blr\n"
);
#endif

bool __saveds
glue_of_init PPC_PARAMS(unsigned int version, struct of_libc *libc,
    FILE *stderr_)
{
	M68K_ARG(unsigned int, version, d0)
	M68K_ARG(struct objc_libc *, libc, a0)
	M68K_ARG(FILE *, stderr_, a1)

	return of_init(version, libc, stderr_);
}
