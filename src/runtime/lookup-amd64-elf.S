/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
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
.globl objc_msg_lookup_super

.section .text
objc_msg_lookup:
	testq	%rdi, %rdi
	jz	ret_nil

	movq	(%rdi), %r8
	movq	64(%r8), %r8

lookup:
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
	jz	forward

	ret

forward:
	movq	objc_not_found_handler@GOTPCREL(%rip), %rax
	jmp	*%rax

objc_msg_lookup_super:
	movq	(%rdi), %rax
	testq	%rax, %rax
	jz	ret_nil

	movq	8(%rdi), %r8
	movq	64(%r8), %r8
	movq	%rdi, %rax
	jmp	lookup

ret_nil:
	leaq	nil_method(%rip), %rax
	ret

nil_method:
	movq	%rdi, %rax
	ret

.type objc_msg_lookup, @function
.type objc_msg_lookup_super, @function
.size objc_msg_lookup, forward-objc_msg_lookup
.size objc_msg_lookup_super, ret_nil-objc_msg_lookup_super

#ifdef __linux__
.section .note.GNU-stack, "", %progbits
#endif
