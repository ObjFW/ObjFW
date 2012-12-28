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

.globl objc_msg_lookup
.globl objc_msg_lookup_super

.section .text
objc_msg_lookup:
	movl	4(%esp), %edx
	testl	%edx, %edx
	jz	ret_nil

	movl	(%edx), %edx
	movl	32(%edx), %edx

lookup:
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
	jz	forward

	ret

forward:
	call	get_eip
.L1:
	addl	$objc_not_found_handler-.L1, %eax
	jmp	*%eax

objc_msg_lookup_super:
	movl	4(%esp), %edx
	cmpl	$0, (%edx)
	je	ret_nil

	movl	4(%edx), %edx
	movl	32(%edx), %edx
	jmp	lookup

ret_nil:
	call	get_eip
.L2:
	addl	$nil_method-.L2, %eax
	ret

nil_method:
	movl	4(%esp), %eax
	ret

get_eip:
	movl	(%esp), %eax
	ret

.type objc_msg_lookup, @function
.type objc_msg_lookup_super, @function
.size objc_msg_lookup, forward-objc_msg_lookup
.size objc_msg_lookup_super, ret_nil-objc_msg_lookup_super

#ifdef __linux__
.section .note.GNU-stack, "", %progbits
#endif
