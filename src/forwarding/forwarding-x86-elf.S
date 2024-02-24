/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

.globl OFForward
.globl OFForward_stret

.section .text
OFForward:
#ifdef HAVE_ENDBR32
	endbr32
#endif

	pushl	%ebp
	movl	%esp, %ebp

	pushl	%ebx
	subl	$20, %esp

	call	.LgetEIP
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx

	movl	8(%ebp), %eax
	movl	%eax, (%esp)
	call	object_getClass@PLT

	movl	%eax, (%esp)
	leal	.Lsel_forwardingTargetForSelector_@GOTOFF(%ebx), %eax
	movl	%eax, 4(%esp)
	call	class_respondsToSelector@PLT

	testl	%eax, %eax
	jz	0f

	movl	8(%ebp), %eax
	movl	%eax, (%esp)
	leal	.Lsel_forwardingTargetForSelector_@GOTOFF(%ebx), %eax
	movl	%eax, 4(%esp)
	call	objc_msg_lookup@PLT

	movl	8(%ebp), %edx
	movl	%edx, (%esp)
	leal	.Lsel_forwardingTargetForSelector_@GOTOFF(%ebx), %edx
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
	movl	OFMethodNotFound@GOT(%ebx), %eax

	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	*%eax
.type OFForward, %function
.size OFForward, .-OFForward

OFForward_stret:
#ifdef HAVE_ENDBR32
	endbr32
#endif

	pushl	%ebp
	movl	%esp, %ebp

	pushl	%ebx
	subl	$20, %esp

	call	.LgetEIP
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx

	movl	12(%ebp), %eax
	movl	%eax, (%esp)
	call	object_getClass@PLT

	movl	%eax, (%esp)
	leal	.Lsel_forwardingTargetForSelector_@GOTOFF(%ebx), %eax
	movl	%eax, 4(%esp)
	call	class_respondsToSelector@PLT

	testl	%eax, %eax
	jz	0f

	movl	12(%ebp), %eax
	movl	%eax, (%esp)
	leal	.Lsel_forwardingTargetForSelector_@GOTOFF(%ebx), %eax
	movl	%eax, 4(%esp)
	call	objc_msg_lookup@PLT

	movl	12(%ebp), %edx
	movl	%edx, (%esp)
	leal	.Lsel_forwardingTargetForSelector_@GOTOFF(%ebx), %edx
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
	movl	OFMethodNotFound_stret@GOT(%ebx), %eax

	addl	$20, %esp
	popl	%ebx
	popl	%ebp

	jmp	*%eax
.type OFForward_stret, %function
.size OFForward_stret, .-OFForward_stret

.Linit:
#ifdef HAVE_ENDBR32
	endbr32
#endif

	pushl	%ebp
	movl	%esp, %ebp

	pushl	%ebx
	subl	$4, %esp

	call	.LgetEIP
	addl	$_GLOBAL_OFFSET_TABLE_, %ebx

	leal	.Lmodule@GOTOFF(%ebx), %eax
	movl	%eax, (%esp)
	call	__objc_exec_class@PLT

	addl	$4, %esp
	popl	%ebx
	popl	%ebp
	ret

.LgetEIP:
	movl	(%esp), %ebx
	ret

#ifdef OF_SOLARIS
.section .init_array, "aw"
#else
.section .ctors, "aw", %progbits
#endif
	.long .Linit

.section .rodata
.Lstr_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section .data
.Lsel_forwardingTargetForSelector_:
	.long .Lstr_forwardingTargetForSelector_, 0
	.long 0, 0
.Lsymtab:
	.long 0, .Lsel_forwardingTargetForSelector_
	.short 0, 0
	.long 0
	.long 0
.Lmodule:
	.long 8, 16, 0, .Lsymtab

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", %progbits
#endif
