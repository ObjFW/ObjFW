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

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro GENERATE_LOOKUP name notFound
\name:
	cmp	r0, #0
	beq	returnNilMethod

	tst	r0, #1
	bne	.LtaggedPointer_\name

	ldr	r2, [r0, #0]
	ldr	r2, [r2, #32]

.Lmain_\name:
#ifndef OF_BIG_ENDIAN
# ifdef OF_SELUID24
	ldrb	r3, [r1, #2]
	ldr	r2, [r2, r3, lsl #2]
# endif
	ldrb	r3, [r1, #1]
	ldr	r2, [r2, r3, lsl #2]
	ldrb	r3, [r1, #0]
	ldr	r2, [r2, r3, lsl #2]
#else
# ifdef OF_SELUID24
	ldrb	r3, [r1, #1]
	ldr	r2, [r2, r3, lsl #2]
# endif
	ldrb	r3, [r1, #2]
	ldr	r2, [r2, r3, lsl #2]
	ldrb	r3, [r1, #3]
	ldr	r2, [r2, r3, lsl #2]
#endif

	cmp	r2, #0
	beq	\notFound(PLT)

	mov	r0, r2
	bx	lr

.LtaggedPointer_\name:
	ldr	r2, .Lgot$indirect_.LtaggedPointer_\name
	add	r2, pc, r2

	ldr	r3, .Lgot$indirect_.LtaggedPointer_\name+4
	ldr	r3, [r2, r3]
	ldr	r3, [r3]
	eor	r0, r0, r3
	and	r0, r0, #0xE
	lsl	r0, r0, #1

	ldr	r3, .Lgot$indirect_.LtaggedPointer_\name+8
	ldr	r3, [r2, r3]
	ldr	r2, [r3, r0]
	ldr	r2, [r2, #32]

	b	.Lmain_\name
.type \name, %function
.size \name, .-\name

.Lgot$indirect_.LtaggedPointer_\name:
	.long	_GLOBAL_OFFSET_TABLE_-(.LtaggedPointer_\name+12)
	.long	objc_taggedPointerSecret(GOT)
	.long	objc_taggedPointerClasses(GOT)
.endm

.macro GENERATE_LOOKUP_SUPER name lookup
\name:
	mov	r2, r0
	ldr	r0, [r0, #0]
	cmp	r0, #0
	beq	returnNilMethod

	ldr	r2, [r2, #4]
	ldr	r2, [r2, #32]

	b	.Lmain_\lookup
.type \name, %function
.size \name, .-\name
.endm

GENERATE_LOOKUP objc_msg_lookup objc_methodNotFound
GENERATE_LOOKUP objc_msg_lookup_stret objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER objc_msg_lookup_super objc_msg_lookup
GENERATE_LOOKUP_SUPER objc_msg_lookup_super_stret objc_msg_lookup_stret

returnNilMethod:
	adr	r0, nilMethod
	bx	lr

nilMethod:
	mov	r0, #0
	bx	lr

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", %progbits
#endif
