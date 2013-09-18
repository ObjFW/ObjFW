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

.globl of_forward
.globl of_forward_stret

.section .text
of_forward:
	pushl	%ebp
	movl	%esp, %ebp

	pushl	%ebx
	subl	$20, %esp

	call	get_eip
.L0:
	movl	8(%ebp), %eax
	movl	%eax, (%esp)
	leal	sel_forwardingTargetForSelector_-.L0(%ebx), %eax
	movl	%eax, 4(%esp)
	leal	objc_msg_lookup-.L0(%ebx), %eax
	call	*%eax

	movl	8(%ebp), %edx
	movl	%edx, (%esp)
	leal	sel_forwardingTargetForSelector_-.L0(%ebx), %edx
	movl	%edx, 4(%esp)
	movl	12(%ebp), %edx
	movl	%edx, 8(%esp)
	call	*%eax

	movl	%eax, 8(%ebp)
	movl	%eax, (%esp)
	movl	12(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	objc_msg_lookup-.L0(%ebx), %eax
	call	*%eax

	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	*%eax
.type of_forward, %function
.size of_forward, .-of_forward

of_forward_stret:
	pushl	%ebp
	movl	%esp, %ebp

	pushl	%ebx
	subl	$20, %esp

	call	get_eip
.L1:
	movl	12(%ebp), %eax
	movl	%eax, (%esp)
	leal	sel_forwardingTargetForSelector_-.L1(%ebx), %eax
	movl	%eax, 4(%esp)
	leal	objc_msg_lookup-.L1(%ebx), %eax
	call	*%eax

	movl	12(%ebp), %edx
	movl	%edx, (%esp)
	leal	sel_forwardingTargetForSelector_-.L1(%ebx), %edx
	movl	%edx, 4(%esp)
	movl	16(%ebp), %edx
	movl	%edx, 8(%esp)
	call	*%eax

	movl	%eax, 12(%ebp)
	movl	%eax, (%esp)
	movl	16(%ebp), %eax
	movl	%eax, 4(%esp)
	leal	objc_msg_lookup_stret-.L1(%ebx), %eax
	call	*%eax

	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	*%eax
.type of_forward_stret, %function
.size of_forward_stret, .-of_forward_stret

init:
	pushl	%ebp
	movl	%esp, %ebp

	pushl	%ebx
	subl	$4, %esp

	call	get_eip
.L2:
	leal	module-.L2(%ebx), %eax
	movl	%eax, (%esp)
	leal	__objc_exec_class-.L2(%ebx), %eax
	call	*%eax

	addl	$4, %esp
	popl	%ebx
	popl	%ebp
	ret

get_eip:
	movl	(%esp), %ebx
	ret

.section .ctors, "a", %progbits
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

#ifdef __linux__
.section .note.GNU-stack, "", %progbits
#endif
