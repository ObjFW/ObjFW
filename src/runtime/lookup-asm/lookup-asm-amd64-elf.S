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

.intel_syntax noprefix

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro GENERATE_LOOKUP name notFound
\name:
	test	rdi, rdi
	jz	short returnNilMethod

	test	dil, 1
	jnz	short .LtaggedPointer_\name

	mov	r8, [rdi]
	mov	r8, [r8 + 64]

.Lmain_\name:
	mov	rax, [rsi]
	movzx	ecx, ah
	movzx	edx, al
#ifdef OF_SELUID24
	shr	eax, 16

	mov	r8, [r8 + 8 * rax]
#endif
	mov	r8, [r8 + 8 * rcx]
	mov	rax, [r8 + 8 * rdx]

	test	rax, rax
	jz	short \notFound@PLT

	ret

.LtaggedPointer_\name:
	mov	rax, [rip + objc_taggedPointerSecret@GOTPCREL]
	xor	rdi, [rax]
	and	dil, 0xE
	movzx	r8d, dil

	mov	rax, [rip + objc_taggedPointerClasses@GOTPCREL]
	mov	r8, [rax + 4 * r8]
	mov	r8, [r8 + 64]

	jmp	short .Lmain_\name
.type \name, %function
.size \name, .-\name
.endm

.macro GENERATE_LOOKUP_SUPER name lookup
\name:
	mov	r8, rdi
	mov	rdi, [rdi]
	test	rdi, rdi
	jz	short returnNilMethod

	mov	r8, [r8 + 8]
	mov	r8, [r8 + 64]
	jmp	short .Lmain_\lookup
.type \name, %function
.size \name, .-\name
.endm

GENERATE_LOOKUP objc_msg_lookup objc_methodNotFound
GENERATE_LOOKUP objc_msg_lookup_stret objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER objc_msg_lookup_super objc_msg_lookup
GENERATE_LOOKUP_SUPER objc_msg_lookup_super_stret objc_msg_lookup_stret

returnNilMethod:
	lea	rax, [rip + nilMethod]
	ret

nilMethod:
	xor	rax, rax
	ret

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", %progbits
#endif
