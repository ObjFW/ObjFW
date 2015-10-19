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

#include "platform.h"

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro generate_lookup name not_found
\name:
	movl	4(%esp), %edx
	testl	%edx, %edx
	jz	ret_nil

	movl	(%edx), %edx
	movl	32(%edx), %edx

.Lmain_\name:
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
	jz	0f

	ret

0:
	call	get_eip
1:
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	\not_found@GOT(%eax), %eax
	jmp	*%eax
.type \name, %function
.size \name, .-\name
.endm

.macro generate_lookup_super name lookup
\name:
	movl	4(%esp), %edx
	cmpl	$0, (%edx)
	je	ret_nil

	movl	4(%edx), %edx
	movl	32(%edx), %edx
	jmp	.Lmain_\lookup
.type \name, %function
.size \name, .-\name
.endm

generate_lookup objc_msg_lookup objc_method_not_found
generate_lookup objc_msg_lookup_stret objc_method_not_found_stret
generate_lookup_super objc_msg_lookup_super objc_msg_lookup
generate_lookup_super objc_msg_lookup_super_stret objc_msg_lookup_stret

ret_nil:
	call	get_eip
0:
	addl	$nil_method-0b, %eax
	ret

nil_method:
	xorl	%eax, %eax
	ret

get_eip:
	movl	(%esp), %eax
	ret

#ifdef OF_LINUX
.section .note.GNU-stack, "", %progbits
#endif
