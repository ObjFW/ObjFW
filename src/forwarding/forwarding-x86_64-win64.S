/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

.globl of_forward
.globl of_forward_stret

.section .text
of_forward:
	pushq	%rbp
	movq	%rsp, %rbp

	/* Save all arguments */
	subq	$0x90, %rsp	/* 16-byte alignment */
	movq	%rax, -0x28(%rbp)
	movq	%rcx, -0x30(%rbp)
	movq	%rdx, -0x38(%rbp)
	movq	%r8, -0x40(%rbp)
	movq	%r9, -0x48(%rbp)
	movaps	%xmm0, -0x60(%rbp)
	movaps	%xmm1, -0x70(%rbp)
	movaps	%xmm2, -0x80(%rbp)
	movaps	%xmm3, -0x90(%rbp)

	call	object_getClass

	movq	%rax, %rcx
	leaq	sel_forwardingTargetForSelector_(%rip), %rdx
	call	class_respondsToSelector

	testq	%rax, %rax
	jz	0f

	movq	-0x30(%rbp), %rcx
	leaq	sel_forwardingTargetForSelector_(%rip), %rdx
	call	objc_msg_lookup

	movq	-0x30(%rbp), %rcx
	leaq	sel_forwardingTargetForSelector_(%rip), %rdx
	movq	-0x38(%rbp), %r8
	call	*%rax

	testq	%rax, %rax
	jz	0f
	cmpq	-0x30(%rbp), %rax
	je	0f

	movq	%rax, -0x30(%rbp)

	movq	%rax, %rcx
	movq	-0x38(%rbp), %rdx
	call	objc_msg_lookup
	movq	%rax, %r11

	/* Restore all arguments */
	movaps	-0x90(%rbp), %xmm3
	movaps	-0x80(%rbp), %xmm2
	movaps	-0x70(%rbp), %xmm1
	movaps	-0x60(%rbp), %xmm0
	movq	-0x48(%rbp), %r9
	movq	-0x40(%rbp), %r8
	movq	-0x38(%rbp), %rdx
	movq	-0x30(%rbp), %rcx
	movq	-0x28(%rbp), %rax

	movq	%rbp, %rsp
	popq	%rbp

	jmpq	*%r11

0:
	movq	-0x30(%rbp), %rcx
	movq	-0x38(%rbp), %rdx

	movq	%rbp, %rsp
	popq	%rbp

	jmp	of_method_not_found

of_forward_stret:
	pushq	%rbp
	movq	%rsp, %rbp

	/* Save all arguments */
	subq	$0x90, %rsp	/* 16-byte alignment */
	movq	%rax, -0x28(%rbp)
	movq	%rcx, -0x30(%rbp)
	movq	%rdx, -0x38(%rbp)
	movq	%r8, -0x40(%rbp)
	movq	%r9, -0x48(%rbp)
	movaps	%xmm0, -0x60(%rbp)
	movaps	%xmm1, -0x70(%rbp)
	movaps	%xmm2, -0x80(%rbp)
	movaps	%xmm3, -0x90(%rbp)

	movq	%rdx, %rcx
	call	object_getClass

	movq	%rax, %rcx
	leaq	sel_forwardingTargetForSelector_(%rip), %rdx
	call	class_respondsToSelector

	testq	%rax, %rax
	jz	0f

	movq	-0x38(%rbp), %rcx
	leaq	sel_forwardingTargetForSelector_(%rip), %rdx
	call	objc_msg_lookup

	movq	-0x38(%rbp), %rcx
	leaq	sel_forwardingTargetForSelector_(%rip), %rdx
	movq	-0x40(%rbp), %r8
	call	*%rax

	testq	%rax, %rax
	jz	0f
	cmpq	-0x38(%rbp), %rax
	je	0f

	movq	%rax, -0x38(%rbp)

	movq	%rax, %rcx
	movq	-0x40(%rbp), %rdx
	call	objc_msg_lookup_stret
	movq	%rax, %r11

	/* Restore all arguments */
	movaps	-0x90(%rbp), %xmm3
	movaps	-0x80(%rbp), %xmm2
	movaps	-0x70(%rbp), %xmm1
	movaps	-0x60(%rbp), %xmm0
	movq	-0x48(%rbp), %r9
	movq	-0x40(%rbp), %r8
	movq	-0x38(%rbp), %rdx
	movq	-0x30(%rbp), %rcx
	movq	-0x28(%rbp), %rax

	movq	%rbp, %rsp
	popq	%rbp

	jmpq	*%r11

0:
	movq	-0x30(%rbp), %rcx
	movq	-0x38(%rbp), %rdx
	movq	-0x40(%rbp), %r8

	movq	%rbp, %rsp
	popq	%rbp

	jmp	of_method_not_found_stret

init:
	leaq	module(%rip), %rcx
	jmp	__objc_exec_class

.section .ctors, "aw"
	.quad init

.section .rodata
str_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section .data
sel_forwardingTargetForSelector_:
	.quad str_forwardingTargetForSelector_, 0
	.quad 0, 0
symtab:
	.long 0, 0
	.quad sel_forwardingTargetForSelector_
	.short 0, 0
	.long 0
	.quad 0
module:
	.long 8, 32
	.quad 0, symtab
