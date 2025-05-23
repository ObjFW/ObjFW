/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include "platform.h"

#ifdef HAVE_CET_H
# include <cet.h>
#else
# define _CET_ENDBR
#endif

.globl _OFForward
.globl _OFForward_stret
.internal _OFForward
.internal _OFForward_stret

.section .text
_OFForward:
	_CET_ENDBR

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
.type _OFForward, %function
.size _OFForward, .-_OFForward

_OFForward_stret:
	_CET_ENDBR

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
.type _OFForward_stret, %function
.size _OFForward_stret, .-_OFForward_stret

.Linit:
	_CET_ENDBR

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
