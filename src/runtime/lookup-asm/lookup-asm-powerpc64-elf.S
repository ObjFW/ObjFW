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

#if defined(_CALL_ELF) && _CALL_ELF == 2
.abiversion 2
#endif

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro GENERATE_LOOKUP name notFound
#if defined(_CALL_ELF) && _CALL_ELF == 2
\name:
	addis	%r2, %r12, .TOC.-\name@ha
	addi	%r2, %r2, .TOC.-\name@l
.localentry \name, .-\name
#else
.section .opd, "aw", @progbits
\name:
	.p2align 3
	.quad .Lbegin_\name
	.quad .TOC.@tocbase
	.quad 0
.previous
#endif
.Lbegin_\name:
	cmpdi	%r3, 0
	beq-	.LreturnNilMethod

	andi.	%r0, %r3, 1
	bne-	.LtaggedPointer_\name

	ld	%r5, 0(%r3)
	ld	%r5, 64(%r5)

.Lmain_\name:
	ld	%r8, 0(%r4)
#ifdef OF_SELUID24
	rlwinm	%r6, %r8, 19, 0x7F8
#endif
	rlwinm	%r7, %r8, 27, 0x7F8
	rlwinm	%r8, %r8, 3, 0x7F8

#ifdef OF_SELUID24
	ldx	%r5, %r5, %r6
#endif
	ldx	%r5, %r5, %r7
	ldx	%r5, %r5, %r8

	cmpdi	%r5, 0
	beq-	0f

	mr	%r3, %r5
	blr

0:
	mflr	%r0
	std	%r0, 16(%r1)
	stdu	%r1, -112(%r1)
	bl	\notFound
	nop
	addi	%r1, %r1, 112
	ld	%r0, 16(%r1)
	mtlr	%r0
	blr

.LtaggedPointer_\name:
	addis	%r5, %r2, objc_taggedPointerSecret@toc@ha
	ld	%r5, objc_taggedPointerSecret@toc@l(%r5)
	xor	%r5, %r3, %r5
	rlwinm	%r5, %r5, 2, 0x38

	addis	%r6, %r2, objc_taggedPointerClasses@toc@ha
	addi	%r6, %r6, objc_taggedPointerClasses@toc@l
	ldx	%r5, %r6, %r5
	ld	%r5, 64(%r5)

	b	.Lmain_\name
.type \name, @function
.size \name, .-.Lbegin_\name
.endm

.macro GENERATE_LOOKUP_SUPER name lookup
#if defined(_CALL_ELF) && _CALL_ELF == 2
\name:
	addis	%r2, %r12, .TOC.-\name@ha
	addi	%r2, %r2, .TOC.-\name@l
.localentry \name, .-\name
#else
.section .opd, "aw", @progbits
\name:
	.p2align 3
	.quad .Lbegin_\name
	.quad .TOC.@tocbase
	.quad 0
.previous
#endif
.Lbegin_\name:
	mr	%r5, %r3
	ld	%r3, 0(%r3)
	cmpdi	%r3, 0
	beq-	.LreturnNilMethod

	ld	%r5, 8(%r5)
	ld	%r5, 64(%r5)

	b	.Lmain_\lookup
.type \name, @function
.size \name, .-.Lbegin_\name
.endm

GENERATE_LOOKUP objc_msg_lookup objc_methodNotFound
GENERATE_LOOKUP objc_msg_lookup_stret objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER objc_msg_lookup_super objc_msg_lookup
GENERATE_LOOKUP_SUPER objc_msg_lookup_super_stret objc_msg_lookup_stret

.LreturnNilMethod:
	addis	%r3, %r2, .LnilMethod@toc@ha
	addi	%r3, %r3, .LnilMethod@toc@l
	blr

#if defined(_CALL_ELF) && _CALL_ELF == 2
.LnilMethod:
	addis	%r2, %r12, .TOC.-.LnilMethod@ha
	addi	%r2, %r2, .TOC.-.LnilMethod@l
.localentry .LnilMethod, .-.LnilMethod
#else
.section .opd, "aw", @progbits
.LnilMethod:
	.p2align 3
	.quad .Lbegin_nilMethod
	.quad .TOC.@tocbase
	.quad 0
.previous
#endif
.Lbegin_nilMethod:
	li	%r3, 0
	blr
.type .LnilMethod, @function
.size .LnilMethod, .-.Lbegin_nilMethod

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", @progbits
#endif
