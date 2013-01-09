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
_of_forward:
	pushl	%ebp
	movl	%esp, %ebp

	pushl	8(%ebp)
	call	_object_getClass
	addl	$4, %esp

	call	get_eip
L0:
	pushl	L_sel_forwardingTargetForSelector-L0(%edx)
	pushl	%eax
	call	_class_respondsToSelector
	addl	$8, %esp
	testl	%eax, %eax
	jz	fail

	pushl	12(%ebp)
	call	get_eip
L1:
	pushl	L_sel_forwardingTargetForSelector-L1(%edx)
	pushl	8(%ebp)
	call	_objc_msgSend

	testl	%eax, %eax
	jz	fail

	cmpl	8(%ebp), %eax
	je	fail

	movl	%eax, 8(%ebp)

	movl	%ebp, %esp
	popl	%ebp

	jmp	_objc_msgSend

fail:
	movl	%ebp, %esp
	popl	%ebp

	jmp	_of_method_not_found

_of_forward_stret:
	pushl	%ebp
	movl	%esp, %ebp

	pushl	12(%ebp)
	call	_object_getClass
	addl	$4, %esp

	call	get_eip
L2:
	pushl	L_sel_forwardingTargetForSelector-L2(%edx)
	pushl	%eax
	call	_class_respondsToSelector
	addl	$8, %esp
	testl	%eax, %eax
	jz	fail_stret

	pushl	16(%ebp)
	call	get_eip
L3:
	pushl	L_sel_forwardingTargetForSelector-L3(%edx)
	pushl	12(%ebp)
	call	_objc_msgSend

	testl	%eax, %eax
	jz	fail_stret

	cmpl	12(%ebp), %eax
	je	fail_stret

	movl	%eax, 12(%ebp)

	movl	%ebp, %esp
	popl	%ebp

	jmp	_objc_msgSend_stret

fail_stret:
	movl	12(%ebp), %eax
	movl	%eax, 8(%ebp)
	movl	16(%ebp), %eax
	movl	%eax, 12(%ebp)

	movl	%ebp, %esp
	popl	%ebp

	jmp	_of_method_not_found

get_eip:
	movl	(%esp), %edx
	ret
