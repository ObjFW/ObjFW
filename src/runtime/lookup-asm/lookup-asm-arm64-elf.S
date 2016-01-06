/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro generate_lookup name not_found
\name:
	cmp	x0, #0
	beq	ret_nil

	ldr	x2, [x0, #0]
	ldr	x2, [x2, #64]

.Lmain_\name:
#ifdef OF_SELUID24
	ldrb	w3, [x1, #2]
	ldr	x2, [x2, x3, lsl #3]
#endif
	ldrb	w3, [x1, #1]
	ldr	x2, [x2, x3, lsl #3]
	ldrb	w3, [x1, #0]
	ldr	x2, [x2, x3, lsl #3]

	cmp	x2, #0
	beq	\not_found

	mov	x0, x2
	ret
.type \name, %function
.size \name, .-\name
.endm

.macro generate_lookup_super name lookup
\name:
	ldr	x2, [x0, #0]
	cmp	x0, #0
	beq	ret_nil

	ldr	x2, [x0, #8]
	ldr	x2, [x2, #64]

	b	.Lmain_\lookup
.type \name, %function
.size \name, .-\name
.endm

generate_lookup objc_msg_lookup objc_method_not_found
generate_lookup objc_msg_lookup_stret objc_method_not_found_stret
generate_lookup_super objc_msg_lookup_super objc_msg_lookup
generate_lookup_super objc_msg_lookup_super_stret objc_msg_lookup_stret

ret_nil:
	adr	x0, nil_method
	ret

nil_method:
	mov	x0, #0
	ret

#ifdef OF_LINUX
.section .note.GNU-stack, "", %progbits
#endif
