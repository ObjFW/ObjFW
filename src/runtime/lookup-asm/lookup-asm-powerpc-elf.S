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
	cmpwi	%r3, 0
	beq-	returnNilMethod

	andi.	%r0, %r3, 1
	bne-	.LtaggedPointer_\name

	lwz	%r5, 0(%r3)
	lwz	%r5, 32(%r5)

.Lmain_\name:
	lwz	%r8, 0(%r4)
#ifdef OF_SELUID24
	rlwinm	%r6, %r8, 18, 0x3FC
#endif
	rlwinm	%r7, %r8, 26, 0x3FC
	rlwinm	%r8, %r8, 2, 0x3FC

#ifdef OF_SELUID24
	lwzx	%r5, %r5, %r6
#endif
	lwzx	%r5, %r5, %r7
	lwzx	%r5, %r5, %r8

	cmpwi	%r5, 0
	beq-	0f

	mr	%r3, %r5
	blr

0:
#ifdef OF_PIC
	stwu	%r1, -16(%r1)
	mflr	%r0	
	stw	%r0, 20(%r1)
	stw	%r30, 8(%r1)

	bl	0f
0:
	mflr	%r30
	addis	%r30, %r30, .Lbiased_got2-0b@ha
	addi	%r30, %r30, .Lbiased_got2-0b@l

	lwz	%r0, .Lgot_\notFound-.Lbiased_got2(%r30)
	mtctr	%r0

	lwz	%r30, 8(%r1)
	lwz	%r0, 20(%r1)
	addi	%r1, %r1, 16
	mtlr	%r0

	bctr
#else
	b	\notFound
#endif

.LtaggedPointer_\name:
#if defined(OF_PIC)
	mflr	%r7
	bl	0f
0:
	mflr	%r6
	mtlr	%r7
	addis	%r6, %r6, .Lbiased_got2-0b@ha
	addi	%r6, %r6, .Lbiased_got2-0b@l

	lwz	%r5, .Lgot_objc_taggedPointerSecret-.Lbiased_got2(%r6)
	lwz	%r5, 0(%r5)
#elif defined(OF_BASEREL)
	addis	%r5, %r13, objc_taggedPointerSecret@drel@ha
	lwz	%r5, objc_taggedPointerSecret@drel@l(%r5)
#else
	lis	%r5, objc_taggedPointerSecret@ha
	lwz	%r5, objc_taggedPointerSecret@l(%r5)
#endif
	xor	%r5, %r3, %r5
	rlwinm	%r5, %r5, 1, 0x1C

#if defined(OF_PIC)
	lwz	%r6, .Lgot_objc_taggedPointerClasses-.Lbiased_got2(%r6)
#elif defined(OF_BASEREL)
	addis	%r6, %r13, objc_taggedPointerClasses@drel@ha
	addi	%r6, %r6, objc_taggedPointerClasses@drel@l
#else
	lis	%r6, objc_taggedPointerClasses@ha
	addi	%r6, %r6, objc_taggedPointerClasses@l
#endif
	lwzx	%r5, %r6, %r5
	lwz	%r5, 32(%r5)

	b	.Lmain_\name
.type \name, @function
.size \name, .-\name
.endm

.macro GENERATE_LOOKUP_SUPER name lookup
\name:
	mr	%r5, %r3
	lwz	%r3, 0(%r3)
	cmpwi	%r3, 0
	beq-	returnNilMethod

	lwz	%r5, 4(%r5)
	lwz	%r5, 32(%r5)

	b	.Lmain_\lookup
.type \name, @function
.size \name, .-\name
.endm

GENERATE_LOOKUP objc_msg_lookup objc_methodNotFound
GENERATE_LOOKUP objc_msg_lookup_stret objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER objc_msg_lookup_super objc_msg_lookup
GENERATE_LOOKUP_SUPER objc_msg_lookup_super_stret objc_msg_lookup_stret

returnNilMethod:
	mflr	%r0
	bl	getPC
	mtlr	%r0
0:
	addi	%r3, %r3, nilMethod-0b
	blr

nilMethod:
	li	%r3, 0
	blr

getPC:
	mflr	%r3
	blr

#ifdef OF_PIC
.section .got2, "aw"
.Lbiased_got2 = .+0x8000
.Lgot_objc_methodNotFound:
	.long objc_methodNotFound
.Lgot_objc_methodNotFound_stret:
	.long objc_methodNotFound_stret
.Lgot_objc_taggedPointerSecret:
	.long objc_taggedPointerSecret
.Lgot_objc_taggedPointerClasses:
	.long objc_taggedPointerClasses
#endif

#ifdef OF_LINUX
.section .note.GNU-stack, "", @progbits
#endif
