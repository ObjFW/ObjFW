/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#if defined(OF_MORPHOS)
__asm__ (
    ".section .eh_frame, \"aw\"\n"
    "	.long 0\n"
    ".section .ctors, \"aw\"\n"
    "	.long 0"
);
#elif defined(OF_AMIGAOS_M68K)
__asm__ (
    ".section .list___EH_FRAME_BEGINS__, \"aw\"\n"
    "    .long 0\n"
    ".section .dlist___EH_FRAME_OBJECTS__, \"aw\"\n"
    "    .long 0\n"
    ".section .list___CTOR_LIST__, \"aw\"\n"
    "    .long 0"
);
#endif
