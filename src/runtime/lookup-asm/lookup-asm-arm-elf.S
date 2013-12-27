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

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro generate_lookup name not_found
\name:
	cmp	r0, #0
	beq	ret_nil

	ldr	r2, [r0, #0]
	ldr	r2, [r2, #32]

.main_\name:
#ifdef OF_SELUID24
	ldrb	r3, [r1, #2]
	ldr	r2, [r2, r3, lsl #2]
#endif
	ldrb	r3, [r1, #1]
	ldr	r2, [r2, r3, lsl #2]
	ldrb	r3, [r1, #0]
	ldr	r2, [r2, r3, lsl #2]

	cmp	r2, #0
	beq	\not_found(PLT)

	mov	r0, r2
	bx	lr
.type \name, %function
.size \name, .-\name
.endm

.macro generate_lookup_super name lookup
\name:
	ldr	r2, [r0, #0]
	cmp	r0, #0
	beq	ret_nil

	ldr	r2, [r0, #4]
	ldr	r2, [r2, #32]

	b	.main_\lookup
.type \name, %function
.size \name, .-\name
.endm

generate_lookup objc_msg_lookup objc_method_not_found
generate_lookup objc_msg_lookup_stret objc_method_not_found_stret
generate_lookup_super objc_msg_lookup_super objc_msg_lookup
generate_lookup_super objc_msg_lookup_super_stret objc_msg_lookup_stret

ret_nil:
	adr	r0, nil_method
	bx	lr

nil_method:
	mov	r0, #0
	bx	lr

#ifdef __linux__
.section .note.GNU-stack, "", %progbits
#endif
