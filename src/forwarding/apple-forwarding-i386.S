/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
 *   Jonathan Schleifer <js@heap.zone>
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

.globl _of_forward
.globl _of_forward_stret

.section __TEXT, __cstring, cstring_literals
str_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section __OBJC, __message_refs, literal_pointers, no_dead_strip
sel_forwardingTargetForSelector_:
	.long str_forwardingTargetForSelector_

.section __OBJC, __image_info
	.long 0, 0

.section __TEXT, __text, regular, pure_instructions
_of_forward:
	pushl	%ebp
	movl	%esp, %ebp

	pushl	%ebx
	subl	$20, %esp

	call	get_eip
0:

	movl	8(%ebp), %eax
	movl	%eax, (%esp)
	call	_object_getClass

	movl	%eax, (%esp)
	movl	sel_forwardingTargetForSelector_-0b(%ebx), %eax
	movl	%eax, 4(%esp)
	call	_class_respondsToSelector

	testl	%eax, %eax
	jz	0f

	movl	8(%ebp), %eax
	movl	%eax, (%esp)
	movl	sel_forwardingTargetForSelector_-0b(%ebx), %eax
	movl	%eax, 4(%esp)
	movl	12(%ebp), %eax
	movl	%eax, 8(%esp)
	call	_objc_msgSend

	testl	%eax, %eax
	jz	0f
	cmpl	8(%ebp), %eax
	je	0f

	movl	%eax, 8(%ebp)

	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	_objc_msgSend

0:
	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	_of_method_not_found

_of_forward_stret:
	pushl	%ebp
	movl	%esp, %ebp

	pushl	%ebx
	subl	$20, %esp

	call	get_eip
0:

	movl	12(%ebp), %eax
	movl	%eax, (%esp)
	call	_object_getClass

	movl	%eax, (%esp)
	movl	sel_forwardingTargetForSelector_-0b(%ebx), %eax
	movl	%eax, 4(%esp)
	call	_class_respondsToSelector

	testl	%eax, %eax
	jz	0f

	movl	12(%ebp), %eax
	movl	%eax, (%esp)
	movl	sel_forwardingTargetForSelector_-0b(%ebx), %eax
	movl	%eax, 4(%esp)
	movl	16(%ebp), %eax
	movl	%eax, 8(%esp)
	call	_objc_msgSend

	testl	%eax, %eax
	jz	0f
	cmpl	12(%ebp), %eax
	je	0f

	movl	%eax, 12(%ebp)

	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	_objc_msgSend_stret

0:
	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	_of_method_not_found_stret

get_eip:
	movl	(%esp), %ebx
	ret
