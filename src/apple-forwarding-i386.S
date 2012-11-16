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

.globl _of_forward
.globl _of_forward_stret

.section __TEXT, __cstring, cstring_literals
L_str_forwardingTargetForSelector:
	.asciz "forwardingTargetForSelector:"

.section __OBJC, __message_refs, literal_pointers, no_dead_strip
L_sel_forwardingTargetForSelector:
	.long L_str_forwardingTargetForSelector

.section __OBJC, __image_info
	.long 0, 0

.section __TEXT, __text, regular, pure_instructions
.macro forward dispatch_func
	pushl	%ebp
	movl	%esp, %ebp

	pushl	8(%ebp)
	call	_object_getClass
	addl	$4, %esp
	movl	%eax, %edx

	call	get_eip
L0_\dispatch_func:
	pushl	L_sel_forwardingTargetForSelector-L0_\dispatch_func(%eax)
	pushl	%edx
	call	_class_respondsToSelector
	addl	$8, %esp
	testl	%eax, %eax
	jz	fail

	pushl	12(%ebp)
	call	get_eip
L1_\dispatch_func:
	pushl	L_sel_forwardingTargetForSelector-L1_\dispatch_func(%eax)
	pushl	8(%ebp)
	call	_objc_msgSend

	testl	%eax, %eax
	jz	fail

	cmpl	8(%ebp), %eax
	je	fail

	movl	%eax, 8(%ebp)

	movl	%ebp, %esp
	popl	%ebp

	jmp	\dispatch_func
.endmacro

_of_forward:
	forward	_objc_msgSend

_of_forward_stret:
	forward	_objc_msgSend_stret

fail:
	movl	%ebp, %esp
	popl	%ebp

	jmp	_of_method_not_found

get_eip:
	movl	(%esp), %eax
	ret
