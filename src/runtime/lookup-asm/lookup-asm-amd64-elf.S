/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#ifdef HAVE_CET_H
# include <cet.h>
#else
# define _CET_ENDBR
#endif

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro GENERATE_LOOKUP name notFound
\name:
	_CET_ENDBR

	testq	%rdi, %rdi
	jz	.LreturnNilMethod

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
	_CET_ENDBR

	movq	%rdi, %r8
	movq	(%rdi), %rdi
	testq	%rdi, %rdi
	jz	.LreturnNilMethod

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

.LreturnNilMethod:
	leaq	.LnilMethod(%rip), %rax
	ret

.LnilMethod:
	_CET_ENDBR

	xorq	%rax, %rax
	ret

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", %progbits
#endif
