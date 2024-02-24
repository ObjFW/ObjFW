/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
.macro GENERATE_LOOKUP name notFound
\name:
#ifdef HAVE_BTI
	bti	c
#endif

	cbz	x0, .LreturnNilMethod

	tst	x0, #1
	b.ne	.LtaggedPointer_\name

	ldr	x2, [x0]
	ldr	x2, [x2, #64]

.Lmain_\name:
#ifdef OF_SELUID24
	ldrb	w3, [x1, #2]
	ldr	x2, [x2, x3, lsl #3]
#endif
	ldrb	w3, [x1, #1]
	ldr	x2, [x2, x3, lsl #3]
	ldrb	w3, [x1]
	ldr	x2, [x2, x3, lsl #3]

	cbz	x2, \notFound

	mov	x0, x2
	ret

.LtaggedPointer_\name:
	adrp	x2, :got:objc_taggedPointerSecret
	ldr	x2, [x2, #:got_lo12:objc_taggedPointerSecret]
	ldr	x2, [x2]
	eor	x0, x0, x2
	and	x0, x0, #0xE
	lsl	x0, x0, #2

	adrp	x2, :got:objc_taggedPointerClasses
	ldr	x2, [x2, #:got_lo12:objc_taggedPointerClasses]
	ldr	x2, [x2, x0]
	ldr	x2, [x2, #64]

	b	.Lmain_\name
.type \name, %function
.size \name, .-\name
.endm

.macro GENERATE_LOOKUP_SUPER name lookup
\name:
#ifdef HAVE_BTI
	bti	c
#endif

	mov	x2, x0
	ldr	x0, [x0]
	cbz	x0, .LreturnNilMethod

	ldr	x2, [x2, #8]
	ldr	x2, [x2, #64]

	b	.Lmain_\lookup
.type \name, %function
.size \name, .-\name
.endm

GENERATE_LOOKUP objc_msg_lookup objc_methodNotFound
GENERATE_LOOKUP objc_msg_lookup_stret objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER objc_msg_lookup_super objc_msg_lookup
GENERATE_LOOKUP_SUPER objc_msg_lookup_super_stret objc_msg_lookup_stret

.LreturnNilMethod:
	adr	x0, .LnilMethod
	ret

.LnilMethod:
	mov	x0, #0
	ret

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", %progbits
#endif
