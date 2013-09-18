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

	pushl	%ebx
	subl	$20, %esp

	call	get_eip
.L0:
	movl	8(%ebp), %eax
	movl	%eax, (%esp)
	call	_object_getClass

	movl	%eax, (%esp)
	movl	L_sel_forwardingTargetForSelector-.L0(%ebx), %eax
	movl	%eax, 4(%esp)
	call	_class_respondsToSelector
	testl	%eax, %eax
	jz	fail

	movl	8(%ebp), %eax
	movl	%eax, (%esp)
	movl	L_sel_forwardingTargetForSelector-.L0(%ebx), %eax
	movl	%eax, 4(%esp)
	movl	12(%ebp), %eax
	movl	%eax, 8(%esp)
	call	_objc_msgSend

	testl	%eax, %eax
	jz	fail

	cmpl	8(%ebp), %eax
	je	fail

	movl	%eax, 8(%ebp)

	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	_objc_msgSend

fail:
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
.L1:
	movl	12(%ebp), %eax
	movl	%eax, (%esp)
	call	_object_getClass

	movl	%eax, (%esp)
	movl	L_sel_forwardingTargetForSelector-.L1(%ebx), %eax
	movl	%eax, 4(%esp)
	call	_class_respondsToSelector
	testl	%eax, %eax
	jz	fail_stret

	movl	12(%ebp), %eax
	movl	%eax, (%esp)
	movl	L_sel_forwardingTargetForSelector-.L1(%ebx), %eax
	movl	%eax, 4(%esp)
	movl	16(%ebp), %eax
	movl	%eax, 8(%esp)
	call	_objc_msgSend

	testl	%eax, %eax
	jz	fail_stret

	cmpl	12(%ebp), %eax
	je	fail_stret

	movl	%eax, 12(%ebp)

	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	_objc_msgSend_stret

fail_stret:
	movl	12(%ebp), %eax
	movl	%eax, 8(%ebp)
	movl	16(%ebp), %eax
	movl	%eax, 12(%ebp)

	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	_of_method_not_found

get_eip:
	movl	(%esp), %ebx
	ret
