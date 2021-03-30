/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro generate_lookup name not_found
\name:
	testq	%rcx, %rcx
	jz	ret_nil

	testb	$1, %cl
	jnz	.Ltagged_pointer_\name

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
	jmp	\not_found

.Ltagged_pointer_\name:
	xorq	objc_tagged_pointer_secret(%rip), %rcx
	andb	$0xE, %cl
	movzbl	%cl, %r8d

	leaq	objc_tagged_pointer_classes(%rip), %rax
	movq	(%rax,%r8,4), %r8
	movq	56(%r8), %r8

	jmp	.Lmain_\name
.def \name
.scl 2
.type 32
.endef
.endm

.macro generate_lookup_super name lookup
\name:
	movq	%rcx, %r8
	movq	(%rcx), %rcx
	testq	%rcx, %rcx
	jz	ret_nil

	movq	8(%r8), %r8
	movq	56(%r8), %r8
	jmp	.Lmain_\lookup
.def \name
.scl 2
.type 32
.endef
.endm

generate_lookup objc_msg_lookup objc_method_not_found
generate_lookup objc_msg_lookup_stret objc_method_not_found_stret
generate_lookup_super objc_msg_lookup_super objc_msg_lookup
generate_lookup_super objc_msg_lookup_super_stret objc_msg_lookup_stret

ret_nil:
	leaq	nil_method(%rip), %rax
	ret

nil_method:
	xorq	%rax, %rax
	ret
