/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

	movl	8(%ebp), %eax
	movl	%eax, (%esp)
	call	_object_getClass

	movl	%eax, (%esp)
	movl	$sel_forwardingTargetForSelector_, %eax
	movl	%eax, 4(%esp)
	call	_class_respondsToSelector

	testl	%eax, %eax
	jz	0f

	movl	8(%ebp), %eax
	movl	%eax, (%esp)
	movl	$sel_forwardingTargetForSelector_, %eax
	movl	%eax, 4(%esp)
	call	_objc_msg_lookup

	movl	8(%ebp), %edx
	movl	%edx, (%esp)
	movl	$sel_forwardingTargetForSelector_, %edx
	movl	%edx, 4(%esp)
	movl	12(%ebp), %edx
	movl	%edx, 8(%esp)
	call	*%eax

	testl	%eax, %eax
	jz	0f
	cmpl	8(%ebp), %eax
	je	0f

	movl	%eax, 8(%ebp)
	movl	%eax, (%esp)
	movl	12(%ebp), %eax
	movl	%eax, 4(%esp)
	call	_objc_msg_lookup

	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	*%eax

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

	movl	12(%ebp), %eax
	movl	%eax, (%esp)
	call	_object_getClass

	movl	%eax, (%esp)
	movl	$sel_forwardingTargetForSelector_, %eax
	movl	%eax, 4(%esp)
	call	_class_respondsToSelector

	testl	%eax, %eax
	jz	0f

	movl	12(%ebp), %eax
	movl	%eax, (%esp)
	movl	$sel_forwardingTargetForSelector_, %eax
	movl	%eax, 4(%esp)
	call	_objc_msg_lookup

	movl	12(%ebp), %edx
	movl	%edx, (%esp)
	movl	$sel_forwardingTargetForSelector_, %edx
	movl	%edx, 4(%esp)
	movl	16(%ebp), %edx
	movl	%edx, 8(%esp)
	call	*%eax

	testl	%eax, %eax
	jz	0f
	cmpl	12(%ebp), %eax
	je	0f

	movl	%eax, 12(%ebp)
	movl	%eax, (%esp)
	movl	16(%ebp), %eax
	movl	%eax, 4(%esp)
	call	_objc_msg_lookup_stret

	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	*%eax

0:
	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	_of_method_not_found_stret

init:
	pushl	%ebp
	movl	%esp, %ebp

	pushl	%ebx
	subl	$4, %esp

	movl	$module, %eax
	movl	%eax, (%esp)
	call	___objc_exec_class

	addl	$4, %esp
	popl	%ebx
	popl	%ebp
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
