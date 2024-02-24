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

.section __TEXT, __objc_methname, cstring_literals
Lstr_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section __DATA, __objc_selrefs, literal_pointers, no_dead_strip
Lsel_forwardingTargetForSelector_:
	.quad Lstr_forwardingTargetForSelector_

.section __DATA, __objc_imageinfo, regular, no_dead_strip
	.long 0, 0

.section __TEXT, __text, regular, pure_instructions
_OFForward:
#ifdef HAVE_ENDBR64
	endbr64
#endif

	pushq	%rbp
	movq	%rsp, %rbp

	/* Save all arguments */
	subq	$0xC0, %rsp	/* 16-byte alignment */
	movq	%rax, -0x8(%rbp)
	movq	%rdi, -0x10(%rbp)
	movq	%rsi, -0x18(%rbp)
	movq	%rdx, -0x20(%rbp)
	movq	%rcx, -0x28(%rbp)
	movq	%r8, -0x30(%rbp)
	movq	%r9, -0x38(%rbp)
	movaps	%xmm0, -0x50(%rbp)
	movaps	%xmm1, -0x60(%rbp)
	movaps	%xmm2, -0x70(%rbp)
	movaps	%xmm3, -0x80(%rbp)
	movaps	%xmm4, -0x90(%rbp)
	movaps	%xmm5, -0xA0(%rbp)
	movaps	%xmm6, -0xB0(%rbp)
	movaps	%xmm7, -0xC0(%rbp)

	call	_object_getClass

	movq	%rax, %rdi
	movq	Lsel_forwardingTargetForSelector_(%rip), %rsi
	call	_class_respondsToSelector

	testq	%rax, %rax
	jz	0f

	movq	-0x10(%rbp), %rdi
	movq	Lsel_forwardingTargetForSelector_(%rip), %rsi
	movq	-0x18(%rbp), %rdx
	call	_objc_msgSend

	testq	%rax, %rax
	jz	0f
	cmpq	-0x10(%rbp), %rax
	je	0f

	movq	%rax, %rdi

	/* Restore all arguments, except %rdi */
	movaps	-0xC0(%rbp), %xmm7
	movaps	-0xB0(%rbp), %xmm6
	movaps	-0xA0(%rbp), %xmm5
	movaps	-0x90(%rbp), %xmm4
	movaps	-0x80(%rbp), %xmm3
	movaps	-0x70(%rbp), %xmm2
	movaps	-0x60(%rbp), %xmm1
	movaps	-0x50(%rbp), %xmm0
	movq	-0x38(%rbp), %r9
	movq	-0x30(%rbp), %r8
	movq	-0x28(%rbp), %rcx
	movq	-0x20(%rbp), %rdx
	movq	-0x18(%rbp), %rsi
	movq	-0x8(%rbp), %rax

	movq	%rbp, %rsp
	popq	%rbp

	jmp	_objc_msgSend

0:
	movq	-0x10(%rbp), %rdi
	movq	-0x18(%rbp), %rsi

	movq	%rbp, %rsp
	popq	%rbp

	jmp	_OFMethodNotFound

_OFForward_stret:
#ifdef HAVE_ENDBR64
	endbr64
#endif

	pushq	%rbp
	movq	%rsp, %rbp

	/* Save all arguments */
	subq	$0xC0, %rsp	/* 16-byte alignment */
	movq	%rax, -0x8(%rbp)
	movq	%rdi, -0x10(%rbp)
	movq	%rsi, -0x18(%rbp)
	movq	%rdx, -0x20(%rbp)
	movq	%rcx, -0x28(%rbp)
	movq	%r8, -0x30(%rbp)
	movq	%r9, -0x38(%rbp)
	movaps	%xmm0, -0x50(%rbp)
	movaps	%xmm1, -0x60(%rbp)
	movaps	%xmm2, -0x70(%rbp)
	movaps	%xmm3, -0x80(%rbp)
	movaps	%xmm4, -0x90(%rbp)
	movaps	%xmm5, -0xA0(%rbp)
	movaps	%xmm6, -0xB0(%rbp)
	movaps	%xmm7, -0xC0(%rbp)

	movq	%rsi, %rdi
	call	_object_getClass

	movq	%rax, %rdi
	movq	Lsel_forwardingTargetForSelector_(%rip), %rsi
	call	_class_respondsToSelector
	testq	%rax, %rax
	jz	0f

	movq	-0x18(%rbp), %rdi
	movq	Lsel_forwardingTargetForSelector_(%rip), %rsi
	movq	-0x20(%rbp), %rdx
	call	_objc_msgSend

	testq	%rax, %rax
	jz	0f
	cmpq	-0x18(%rbp), %rax
	je	0f

	movq	%rax, %rsi

	/* Restore all arguments, except %rsi */
	movaps	-0xC0(%rbp), %xmm7
	movaps	-0xB0(%rbp), %xmm6
	movaps	-0xA0(%rbp), %xmm5
	movaps	-0x90(%rbp), %xmm4
	movaps	-0x80(%rbp), %xmm3
	movaps	-0x70(%rbp), %xmm2
	movaps	-0x60(%rbp), %xmm1
	movaps	-0x50(%rbp), %xmm0
	movq	-0x38(%rbp), %r9
	movq	-0x30(%rbp), %r8
	movq	-0x28(%rbp), %rcx
	movq	-0x20(%rbp), %rdx
	movq	-0x10(%rbp), %rdi
	movq	-0x8(%rbp), %rax

	movq	%rbp, %rsp
	popq	%rbp

	jmp	_objc_msgSend_stret

0:
	movq	-0x10(%rbp), %rdi
	movq	-0x18(%rbp), %rsi
	movq	-0x20(%rbp), %rdx

	movq	%rbp, %rsp
	popq	%rbp

	jmp	_OFMethodNotFound_stret
