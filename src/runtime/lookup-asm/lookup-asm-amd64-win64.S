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

.intel_syntax noprefix

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro GENERATE_LOOKUP name notFound
\name:
	test	rcx, rcx
	jz	.LreturnNilMethod

	test	cl, 1
	jnz	.LtaggedPointer_\name

	mov	r8, [rcx]
	mov	r8, [r8 + 56]

.Lmain_\name:
	mov	r10, rcx
	mov	r11, rdx

	mov	rax, [rdx]
	movzx	ecx, ah
	movzx	edx, al
#ifdef OF_SELUID24
	shr	eax, 16

	mov	r8, [r8 + 8 * rax]
#endif
	mov	r8, [r8 + 8 * rcx]
	mov	rax, [r8 + 8 * rdx]

	test	rax, rax
	jz	0f

	ret

0:
	mov	rcx, r10
	mov	rdx, r11
	jmp	\notFound

.LtaggedPointer_\name:
	xor	rcx, [rip + objc_taggedPointerSecret]
	and	cl, 0xE
	movzx	r8d, cl

	lea	rax, [rip + objc_taggedPointerClasses]
	mov	r8, [rax + 4 * r8]
	mov	r8, [r8 + 56]

	jmp	.Lmain_\name
.def \name
.scl 2
.type 32
.endef
.endm

.macro GENERATE_LOOKUP_SUPER name lookup
\name:
	mov	r8, rcx
	mov	rcx, [rcx]
	test	rcx, rcx
	jz	short .LreturnNilMethod

	mov	r8, [r8 + 8]
	mov	r8, [r8 + 56]
	jmp	short .Lmain_\lookup
.def \name
.scl 2
.type 32
.endef
.endm

GENERATE_LOOKUP objc_msg_lookup objc_methodNotFound
GENERATE_LOOKUP objc_msg_lookup_stret objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER objc_msg_lookup_super objc_msg_lookup
GENERATE_LOOKUP_SUPER objc_msg_lookup_super_stret objc_msg_lookup_stret

.LreturnNilMethod:
	lea	rax, [rip + .LnilMethod]
	ret

.LnilMethod:
	xor	rax, rax
	ret
