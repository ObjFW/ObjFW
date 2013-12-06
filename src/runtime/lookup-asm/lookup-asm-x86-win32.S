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

.globl _objc_msg_lookup
.globl _objc_msg_lookup_stret
.globl _objc_msg_lookup_super
.globl _objc_msg_lookup_super_stret

.section .text
.macro generate_lookup name not_found_handler
\name:
	movl	4(%esp), %edx
	testl	%edx, %edx
	jz	ret_nil

	movl	(%edx), %edx
	movl	32(%edx), %edx

.main_\name:
	movl	8(%esp), %eax

#ifdef OF_SELUID24
	movzbl	2(%eax), %ecx
	movl	(%edx,%ecx,4), %edx
#endif
	movzbl	1(%eax), %ecx
	movl	(%edx,%ecx,4), %edx
	movzbl	(%eax), %ecx
	movl	(%edx,%ecx,4), %eax

	testl	%eax, %eax
	jz	.forward_\name

	ret

.forward_\name:
	call	get_eip
.forward_L0_\name:
	addl	$\not_found_handler-.forward_L0_\name, %eax
	jmp	*%eax
.endm

.macro generate_lookup_super name lookup
\name:
	movl	4(%esp), %edx
	cmpl	$0, (%edx)
	je	ret_nil

	movl	4(%edx), %edx
	movl	32(%edx), %edx
	jmp	.main_\lookup
.endm

generate_lookup _objc_msg_lookup _objc_not_found_handler
generate_lookup _objc_msg_lookup_stret _objc_not_found_handler_stret
generate_lookup_super _objc_msg_lookup_super _objc_msg_lookup
generate_lookup_super _objc_msg_lookup_super_stret _objc_msg_lookup_stret

ret_nil:
	call	get_eip
.L0:
	addl	$nil_method-.L0, %eax
	ret

nil_method:
	xorl	%eax, %eax
	ret

get_eip:
	movl	(%esp), %eax
	ret
