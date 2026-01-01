/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

.globl __OFForward
.globl __OFForward_stret

#ifdef HAVE_CET_H
# include <cet.h>
#else
# define _CET_ENDBR
#endif

.section .text
__OFForward:
	_CET_ENDBR

	pushl	%ebp
	movl	%esp, %ebp

	pushl	%ebx
	subl	$20, %esp

	movl	8(%ebp), %eax
	movl	%eax, (%esp)
	call	_object_getClass

	movl	%eax, (%esp)
	movl	$.Lsel_forwardingTargetForSelector_, %eax
	movl	%eax, 4(%esp)
	call	_class_respondsToSelector

	testl	%eax, %eax
	jz	0f

	movl	8(%ebp), %eax
	movl	%eax, (%esp)
	movl	$.Lsel_forwardingTargetForSelector_, %eax
	movl	%eax, 4(%esp)
	call	_objc_msg_lookup

	movl	8(%ebp), %edx
	movl	%edx, (%esp)
	movl	$.Lsel_forwardingTargetForSelector_, %edx
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

	jmp	_OFMethodNotFound
.def __OFForward
.scl 2
.type 32
.endef

__OFForward_stret:
	_CET_ENDBR

	pushl	%ebp
	movl	%esp, %ebp

	pushl	%ebx
	subl	$20, %esp

	movl	12(%ebp), %eax
	movl	%eax, (%esp)
	call	_object_getClass

	movl	%eax, (%esp)
	movl	$.Lsel_forwardingTargetForSelector_, %eax
	movl	%eax, 4(%esp)
	call	_class_respondsToSelector

	testl	%eax, %eax
	jz	0f

	movl	12(%ebp), %eax
	movl	%eax, (%esp)
	movl	$.Lsel_forwardingTargetForSelector_, %eax
	movl	%eax, 4(%esp)
	call	_objc_msg_lookup

	movl	12(%ebp), %edx
	movl	%edx, (%esp)
	movl	$.Lsel_forwardingTargetForSelector_, %edx
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

	jmp	_OFMethodNotFound_stret
.def __OFForward_stret
.scl 2
.type 32
.endef

.Linit:
	_CET_ENDBR

	pushl	%ebp
	movl	%esp, %ebp

	pushl	%ebx
	subl	$4, %esp

	movl	$.Lmodule, %eax
	movl	%eax, (%esp)
	call	___objc_exec_class

	addl	$4, %esp
	popl	%ebx
	popl	%ebp
	ret

.section .ctors, "aw"
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
