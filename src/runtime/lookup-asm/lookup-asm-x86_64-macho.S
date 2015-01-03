/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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
.globl _objc_msg_lookup_stret
.globl _objc_msg_lookup_super
.globl _objc_msg_lookup_super_stret

.section __TEXT, __text, regular, pure_instructions
.macro generate_lookup
$0:
	testq	%rdi, %rdi
	jz	ret_nil

	movq	(%rdi), %r8
	movq	64(%r8), %r8

Lmain_$0:
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
	jz	$1

	ret
.endmacro

.macro generate_lookup_super
$0:
	movq	(%rdi), %rax
	testq	%rax, %rax
	jz	ret_nil

	movq	8(%rdi), %r8
	movq	64(%r8), %r8
	jmp	Lmain_$1
.endmacro

generate_lookup _objc_msg_lookup, _objc_method_not_found
generate_lookup _objc_msg_lookup_stret, _objc_method_not_found_stret
generate_lookup_super _objc_msg_lookup_super, _objc_msg_lookup
generate_lookup_super _objc_msg_lookup_super_stret, _objc_msg_lookup_stret

ret_nil:
	leaq	nil_method(%rip), %rax
	ret

nil_method:
	movq	%rdi, %rax
	ret
