/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
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
	beq-	.LreturnNilMethod

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

	lwz	%r5, .Lgot__objc_taggedPointerSecret-.Lbiased_got2(%r6)
	lwz	%r5, 0(%r5)
#elif defined(OF_BASEREL)
	addis	%r5, %r13, _objc_taggedPointerSecret@drel@ha
	lwz	%r5, _objc_taggedPointerSecret@drel@l(%r5)
#else
	lis	%r5, _objc_taggedPointerSecret@ha
	lwz	%r5, _objc_taggedPointerSecret@l(%r5)
#endif
	xor	%r5, %r3, %r5
	rlwinm	%r5, %r5, 1, 0x1C

#if defined(OF_PIC)
	lwz	%r6, .Lgot__objc_taggedPointerClasses-.Lbiased_got2(%r6)
#elif defined(OF_BASEREL)
	addis	%r6, %r13, _objc_taggedPointerClasses@drel@ha
	addi	%r6, %r6, _objc_taggedPointerClasses@drel@l
#else
	lis	%r6, _objc_taggedPointerClasses@ha
	addi	%r6, %r6, _objc_taggedPointerClasses@l
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
	beq-	.LreturnNilMethod

	lwz	%r5, 4(%r5)
	lwz	%r5, 32(%r5)

	b	.Lmain_\lookup
.type \name, @function
.size \name, .-\name
.endm

GENERATE_LOOKUP objc_msg_lookup _objc_methodNotFound
GENERATE_LOOKUP objc_msg_lookup_stret _objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER objc_msg_lookup_super objc_msg_lookup
GENERATE_LOOKUP_SUPER objc_msg_lookup_super_stret objc_msg_lookup_stret

.LreturnNilMethod:
	mflr	%r0
	bl	.LgetPC
	mtlr	%r0
0:
	addi	%r3, %r3, .LnilMethod-0b
	blr

.LnilMethod:
	li	%r3, 0
	blr

.LgetPC:
	mflr	%r3
	blr

#ifdef OF_PIC
.section .got2, "aw"
.Lbiased_got2 = .+0x8000
.Lgot__objc_methodNotFound:
	.long _objc_methodNotFound
.Lgot__objc_methodNotFound_stret:
	.long _objc_methodNotFound_stret
.Lgot__objc_taggedPointerSecret:
	.long _objc_taggedPointerSecret
.Lgot__objc_taggedPointerClasses:
	.long _objc_taggedPointerClasses
#endif

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", @progbits
#endif
