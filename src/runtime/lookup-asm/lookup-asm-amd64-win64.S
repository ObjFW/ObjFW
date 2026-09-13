/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

	testq	%rcx, %rcx
	jz	.LreturnNilMethod

	testb	$1, %cl
	jnz	.LtaggedPointer_\name

	movq	(%rcx), %r8
	movq	56(%r8), %r8

.Lmain_\name:
	movq	%rcx, %r10
	movq	%rdx, %r11

	movq	(%rdx), %rax
	movzbl	%ah, %ecx
	movzbl	%al, %edx
#ifdef OF_SELUID24
	shrl	$16, %eax

	movq	(%r8,%rax,8), %r8
#endif
	movq	(%r8,%rcx,8), %r8
	movq	(%r8,%rdx,8), %rax

	testq	%rax, %rax
	jz	0f

	ret

0:
	movq	%r10, %rcx
	movq	%r11, %rdx
	jmp	\notFound

.LtaggedPointer_\name:
	xorq	_objc_taggedPointerSecret(%rip), %rcx
	andb	$0xE, %cl
	movzbl	%cl, %r8d

	leaq	_objc_taggedPointerClasses(%rip), %rax
	movq	(%rax,%r8,4), %r8
	movq	56(%r8), %r8

	jmp	.Lmain_\name
.def \name
.scl 2
.type 32
.endef
.endm

.macro GENERATE_LOOKUP_SUPER name lookup
\name:
	_CET_ENDBR

	movq	%rcx, %r8
	movq	(%rcx), %rcx
	testq	%rcx, %rcx
	jz	.LreturnNilMethod

	movq	8(%r8), %r8
	movq	56(%r8), %r8
	jmp	.Lmain_\lookup
.def \name
.scl 2
.type 32
.endef
.endm

GENERATE_LOOKUP objc_msg_lookup _objc_methodNotFound
GENERATE_LOOKUP objc_msg_lookup_stret _objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER objc_msg_lookup_super objc_msg_lookup
GENERATE_LOOKUP_SUPER objc_msg_lookup_super_stret objc_msg_lookup_stret

.LreturnNilMethod:
	leaq	.LnilMethod(%rip), %rax
	ret

.LnilMethod:
	_CET_ENDBR

	xorq	%rax, %rax
	ret
