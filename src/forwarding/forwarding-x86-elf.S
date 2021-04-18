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

#include "platform.h"

.globl of_forward
.globl of_forward_stret

.section .text
of_forward:
	pushl	%ebp
	movl	%esp, %ebp

	pushl	%ebx
	subl	$20, %esp

	call	get_eip
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx

	movl	8(%ebp), %eax
	movl	%eax, (%esp)
	call	object_getClass@PLT

	movl	%eax, (%esp)
	leal	sel_forwardingTargetForSelector_@GOTOFF(%ebx), %eax
	movl	%eax, 4(%esp)
	call	class_respondsToSelector@PLT

	testl	%eax, %eax
	jz	0f

	movl	8(%ebp), %eax
	movl	%eax, (%esp)
	leal	sel_forwardingTargetForSelector_@GOTOFF(%ebx), %eax
	movl	%eax, 4(%esp)
	call	objc_msg_lookup@PLT

	movl	8(%ebp), %edx
	movl	%edx, (%esp)
	leal	sel_forwardingTargetForSelector_@GOTOFF(%ebx), %edx
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
	call	objc_msg_lookup@PLT

	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	*%eax

0:
	leal	OFMethodNotFound@GOTOFF(%ebx), %eax

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
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx

	movl	12(%ebp), %eax
	movl	%eax, (%esp)
	call	object_getClass@PLT

	movl	%eax, (%esp)
	leal	sel_forwardingTargetForSelector_@GOTOFF(%ebx), %eax
	movl	%eax, 4(%esp)
	call	class_respondsToSelector@PLT

	testl	%eax, %eax
	jz	0f

	movl	12(%ebp), %eax
	movl	%eax, (%esp)
	leal	sel_forwardingTargetForSelector_@GOTOFF(%ebx), %eax
	movl	%eax, 4(%esp)
	call	objc_msg_lookup@PLT

	movl	12(%ebp), %edx
	movl	%edx, (%esp)
	leal	sel_forwardingTargetForSelector_@GOTOFF(%ebx), %edx
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
	call	objc_msg_lookup_stret@PLT

	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	*%eax

0:
	leal	OFMethodNotFound_stret@GOTOFF(%ebx), %eax

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
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx

	leal	module@GOTOFF(%ebx), %eax
	movl	%eax, (%esp)
	call	__objc_exec_class@PLT

	addl	$4, %esp
	popl	%ebx
	popl	%ebp
	ret

get_eip:
	movl	(%esp), %ebx
	ret

#ifdef OF_SOLARIS
.section .init_array, "aw"
#else
.section .ctors, "aw", %progbits
#endif
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

#ifdef OF_LINUX
.section .note.GNU-stack, "", %progbits
#endif
