/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#include "platform.h"

.globl of_forward
.globl of_forward_stret

.section .text
of_forward:
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
	movdqa	%xmm0, -0x50(%rbp)
	movdqa	%xmm1, -0x60(%rbp)
	movdqa	%xmm2, -0x70(%rbp)
	movdqa	%xmm3, -0x80(%rbp)
	movdqa	%xmm4, -0x90(%rbp)
	movdqa	%xmm5, -0xA0(%rbp)
	movdqa	%xmm6, -0xB0(%rbp)
	movdqa	%xmm7, -0xC0(%rbp)

	call	object_getClass@PLT

	movq	%rax, %rdi
	leaq	sel_forwardingTargetForSelector_(%rip), %rsi
	call	class_respondsToSelector@PLT

	testq	%rax, %rax
	jz	0f

	movq	-0x10(%rbp), %rdi
	leaq	sel_forwardingTargetForSelector_(%rip), %rsi
	call	objc_msg_lookup@PLT

	movq	-0x10(%rbp), %rdi
	leaq	sel_forwardingTargetForSelector_(%rip), %rsi
	movq	-0x18(%rbp), %rdx
	call	*%rax

	testq	%rax, %rax
	jz	0f
	cmpq	-0x10(%rbp), %rax
	je	0f

	movq	%rax, -0x10(%rbp)

	movq	%rax, %rdi
	movq	-0x18(%rbp), %rsi
	call	objc_msg_lookup@PLT
	movq	%rax, %r11

	/* Restore all arguments */
	movdqa	-0xC0(%rbp), %xmm7
	movdqa	-0xB0(%rbp), %xmm6
	movdqa	-0xA0(%rbp), %xmm5
	movdqa	-0x90(%rbp), %xmm4
	movdqa	-0x80(%rbp), %xmm3
	movdqa	-0x70(%rbp), %xmm2
	movdqa	-0x60(%rbp), %xmm1
	movdqa	-0x50(%rbp), %xmm0
	movq	-0x38(%rbp), %r9
	movq	-0x30(%rbp), %r8
	movq	-0x28(%rbp), %rcx
	movq	-0x20(%rbp), %rdx
	movq	-0x18(%rbp), %rsi
	movq	-0x10(%rbp), %rdi
	movq	-0x8(%rbp), %rax

	movq	%rbp, %rsp
	popq	%rbp

	jmpq     *%r11

0:
	movq	-0x10(%rbp), %rdi
	movq	-0x18(%rbp), %rsi

	movq	%rbp, %rsp
	popq	%rbp

	jmp	of_method_not_found@PLT
.type of_forward, %function
.size of_forward, .-of_forward

of_forward_stret:
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
	movdqa	%xmm0, -0x50(%rbp)
	movdqa	%xmm1, -0x60(%rbp)
	movdqa	%xmm2, -0x70(%rbp)
	movdqa	%xmm3, -0x80(%rbp)
	movdqa	%xmm4, -0x90(%rbp)
	movdqa	%xmm5, -0xA0(%rbp)
	movdqa	%xmm6, -0xB0(%rbp)
	movdqa	%xmm7, -0xC0(%rbp)

	movq	%rsi, %rdi
	call	object_getClass@PLT

	movq	%rax, %rdi
	leaq	sel_forwardingTargetForSelector_(%rip), %rsi
	call	class_respondsToSelector@PLT

	testq	%rax, %rax
	jz	0f

	movq	-0x18(%rbp), %rdi
	leaq	sel_forwardingTargetForSelector_(%rip), %rsi
	call	objc_msg_lookup@PLT

	movq	-0x18(%rbp), %rdi
	leaq	sel_forwardingTargetForSelector_(%rip), %rsi
	movq	-0x20(%rbp), %rdx
	call	*%rax

	testq	%rax, %rax
	jz	0f
	cmpq	-0x18(%rbp), %rax
	je	0f

	movq	%rax, -0x18(%rbp)

	movq	%rax, %rdi
	movq	-0x20(%rbp), %rsi
	call	objc_msg_lookup_stret@PLT
	movq	%rax, %r11

	/* Restore all arguments */
	movdqa	-0xC0(%rbp), %xmm7
	movdqa	-0xB0(%rbp), %xmm6
	movdqa	-0xA0(%rbp), %xmm5
	movdqa	-0x90(%rbp), %xmm4
	movdqa	-0x80(%rbp), %xmm3
	movdqa	-0x70(%rbp), %xmm2
	movdqa	-0x60(%rbp), %xmm1
	movdqa	-0x50(%rbp), %xmm0
	movq	-0x38(%rbp), %r9
	movq	-0x30(%rbp), %r8
	movq	-0x28(%rbp), %rcx
	movq	-0x20(%rbp), %rdx
	movq	-0x18(%rbp), %rsi
	movq	-0x10(%rbp), %rdi
	movq	-0x8(%rbp), %rax

	movq	%rbp, %rsp
	popq	%rbp

	jmpq     *%r11

0:
	movq	-0x10(%rbp), %rdi
	movq	-0x18(%rbp), %rsi
	movq	-0x20(%rbp), %rdx

	movq	%rbp, %rsp
	popq	%rbp

	jmp	of_method_not_found_stret@PLT
.type of_forward_stret, %function
.size of_forward_stret, .-of_forward_stret

init:
	leaq	module(%rip), %rdi
	jmp	__objc_exec_class@PLT

#ifdef OF_SOLARIS
.section .init_array, "aw"
#else
.section .ctors, "aw", %progbits
#endif
	.quad init

.section .rodata
str_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section .data
sel_forwardingTargetForSelector_:
	.quad str_forwardingTargetForSelector_, 0
	.quad 0, 0
symtab:
	.quad 0, sel_forwardingTargetForSelector_
	.short 0, 0
	.long 0
	.quad 0
module:
	.quad 8, 32, 0, symtab

#ifdef OF_LINUX
.section .note.GNU-stack, "", %progbits
#endif
