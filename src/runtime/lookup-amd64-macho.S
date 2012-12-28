/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

.globl _objc_msg_lookup
.globl _objc_msg_lookup_super

.section __TEXT, __text, regular, pure_instructions
_objc_msg_lookup:
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
	jmp	_objc_not_found_handler

_objc_msg_lookup_super:
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
