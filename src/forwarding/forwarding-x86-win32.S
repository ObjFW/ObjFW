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

.globl _OFForward
.globl _OFForward_stret

.section .text
_OFForward:
#ifdef HAVE_ENDBR32
	endbr32
#endif

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
.def _OFForward
.scl 2
.type 32
.endef

_OFForward_stret:
#ifdef HAVE_ENDBR32
	endbr32
#endif

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
.def _OFForward_stret
.scl 2
.type 32
.endef

.Linit:
#ifdef HAVE_ENDBR32
	endbr32
#endif

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
