/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
	testq	%rdi, %rdi
	jz	returnNilMethod

	testb	$1, %dil
	jnz	.LtaggedPointer_\name

	movq	(%rdi), %r8
	movq	64(%r8), %r8

.Lmain_\name:
	movq	(%rsi), %rax
	movzbl	%ah, %ecx
	movzbl	%al, %edx
#ifdef OF_SELUID24
	shrl	$16, %eax

	movq	(%r8,%rax,8), %r8
#endif
	movq	(%r8,%rcx,8), %r8
	movq	(%r8,%rdx,8), %rax

	testq	%rax, %rax
	jz	\notFound@PLT

	ret

.LtaggedPointer_\name:
	movq	objc_taggedPointerSecret@GOTPCREL(%rip), %rax
	xorq	(%rax), %rdi
	andb	$0xE, %dil
	movzbl	%dil, %r8d

	movq	objc_taggedPointerClasses@GOTPCREL(%rip), %rax
	movq	(%rax,%r8,4), %r8
	movq	64(%r8), %r8

	jmp	.Lmain_\name
.type \name, %function
.size \name, .-\name
.endm

.macro GENERATE_LOOKUP_SUPER name lookup
\name:
	movq	%rdi, %r8
	movq	(%rdi), %rdi
	testq	%rdi, %rdi
	jz	returnNilMethod

	movq	8(%r8), %r8
	movq	64(%r8), %r8
	jmp	.Lmain_\lookup
.type \name, %function
.size \name, .-\name
.endm

GENERATE_LOOKUP objc_msg_lookup objc_methodNotFound
GENERATE_LOOKUP objc_msg_lookup_stret objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER objc_msg_lookup_super objc_msg_lookup
GENERATE_LOOKUP_SUPER objc_msg_lookup_super_stret objc_msg_lookup_stret

returnNilMethod:
	leaq	nilMethod(%rip), %rax
	ret

nilMethod:
	xorq	%rax, %rax
	ret

#ifdef OF_LINUX
.section .note.GNU-stack, "", %progbits
#endif
