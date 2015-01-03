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

.globl _of_forward
.globl _of_forward_stret

.section .text
_of_forward:
	pushl	%ebp
	movl	%esp, %ebp

	pushl	%ebx
	subl	$20, %esp

	call	get_eip
0:

	movl	8(%ebp), %eax
	movl	%eax, (%esp)
	leal	_object_getClass-0b(%ebx), %eax
	call	*%eax

	movl	%eax, (%esp)
	leal	sel_forwardingTargetForSelector_-0b(%ebx), %eax
	movl	%eax, 4(%esp)
	leal	_class_respondsToSelector-0b(%ebx), %eax
	call	*%eax

	testl	%eax, %eax
	jz	1f

	movl	8(%ebp), %eax
	movl	%eax, (%esp)
	leal	sel_forwardingTargetForSelector_-0b(%ebx), %eax
	movl	%eax, 4(%esp)
	leal	_objc_msg_lookup-0b(%ebx), %eax
	call	*%eax

	movl	8(%ebp), %edx
	movl	%edx, (%esp)
	leal	sel_forwardingTargetForSelector_-0b(%ebx), %edx
	movl	%edx, 4(%esp)
	movl	12(%ebp), %edx
	movl	%edx, 8(%esp)
	call	*%eax

	testl	%eax, %eax
	jz	1f
	cmpl	8(%ebp), %eax
	je	1f

	movl	%eax, 8(%ebp)
	movl	%eax, (%esp)
	movl	12(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	_objc_msg_lookup-0b(%ebx), %eax
	call	*%eax

	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	*%eax

1:
	leal	_of_method_not_found-0b(%ebx), %eax

	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	*%eax

_of_forward_stret:
	pushl	%ebp
	movl	%esp, %ebp

	pushl	%ebx
	subl	$20, %esp

	call	get_eip
0:

	movl	12(%ebp), %eax
	movl	%eax, (%esp)
	leal	_object_getClass-0b(%ebx), %eax
	call	*%eax

	movl	%eax, (%esp)
	leal	sel_forwardingTargetForSelector_-0b(%ebx), %eax
	movl	%eax, 4(%esp)
	leal	_class_respondsToSelector-0b(%ebx), %eax
	call	*%eax

	testl	%eax, %eax
	jz	1f

	movl	12(%ebp), %eax
	movl	%eax, (%esp)
	leal	sel_forwardingTargetForSelector_-0b(%ebx), %eax
	movl	%eax, 4(%esp)
	leal	_objc_msg_lookup-0b(%ebx), %eax
	call	*%eax

	movl	12(%ebp), %edx
	movl	%edx, (%esp)
	leal	sel_forwardingTargetForSelector_-0b(%ebx), %edx
	movl	%edx, 4(%esp)
	movl	16(%ebp), %edx
	movl	%edx, 8(%esp)
	call	*%eax

	testl	%eax, %eax
	jz	1f
	cmpl	12(%ebp), %eax
	je	1f

	movl	%eax, 12(%ebp)
	movl	%eax, (%esp)
	movl	16(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	_objc_msg_lookup_stret-0b(%ebx), %eax
	call	*%eax

	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	*%eax

1:
	leal	_of_method_not_found_stret-0b(%ebx), %eax

	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	*%eax

init:
	pushl	%ebp
	movl	%esp, %ebp

	pushl	%ebx
	subl	$4, %esp

	call	get_eip
0:
	leal	module-0b(%ebx), %eax
	movl	%eax, (%esp)
	leal	___objc_exec_class-0b(%ebx), %eax
	call	*%eax

	addl	$4, %esp
	popl	%ebx
	popl	%ebp
	ret

get_eip:
	movl	(%esp), %ebx
	ret

.section .ctors, "aw"
	.long init

.section .rodata
str_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section .data
sel_forwardingTargetForSelector_:
	.long str_forwardingTargetForSelector_, 0
	.long 0, 0
symtab:
	.long 0, sel_forwardingTargetForSelector_
	.short 0, 0
	.long 0
	.long 0
module:
	.long 8, 16, 0, symtab
