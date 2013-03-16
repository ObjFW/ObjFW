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

.section .text
of_forward:
	pushq	%rbp
	movq	%rsp, %rbp

	/* Save all arguments */
	subq	$0xC0, %rsp	/* 16-byte alignment */
	movq	 %rax, 0xA8(%rsp)
	movq	 %rdi, 0xA0(%rsp)
	movq	 %rsi, 0x98(%rsp)
	movq	 %rdx, 0x90(%rsp)
	movq	 %rcx, 0x88(%rsp)
	movq	  %r8, 0x80(%rsp)
	movq	  %r9, 0x78(%rsp)
	movd	%xmm0, 0x70(%rsp)
	movd	%xmm1, 0x60(%rsp)
	movd	%xmm2, 0x50(%rsp)
	movd	%xmm3, 0x40(%rsp)
	movd	%xmm4, 0x30(%rsp)
	movd	%xmm5, 0x20(%rsp)
	movd	%xmm6, 0x10(%rsp)
	movd	%xmm7,     (%rsp)

	leaq	sel_forwardingTargetForSelector_(%rip), %rsi
	call	objc_msg_lookup@PLT
	movq	0xA0(%rsp), %rdi
	leaq	sel_forwardingTargetForSelector_(%rip), %rsi
	movq	0x98(%rsp), %rdx
	call	*%rax
	movq	%rax, 0xA0(%rsp)

	movq	%rax, %rdi
	movq	0x98(%rsp), %rsi
	call	objc_msg_lookup@PLT
	movq	%rax, %r11

	/* Restore all arguments */
	movd	    (%rsp), %xmm7
	movd	0x10(%rsp), %xmm6
	movd	0x20(%rsp), %xmm5
	movd	0x30(%rsp), %xmm4
	movd	0x40(%rsp), %xmm3
	movd	0x50(%rsp), %xmm2
	movd	0x60(%rsp), %xmm1
	movd	0x70(%rsp), %xmm0
	movq	0x78(%rsp),   %r9
	movq	0x80(%rsp),   %r8
	movq	0x88(%rsp),  %rcx
	movq	0x90(%rsp),  %rdx
	movq	0x98(%rsp),  %rsi
	movq	0xA0(%rsp),  %rdi
	movq	0xA8(%rsp),  %rax

	movq	%rbp, %rsp
	popq	%rbp

	jmp     *%r11

init:
	leaq	module(%rip), %rdi
	call	__objc_exec_class@PLT
	ret

.section .init_array
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

.type of_forward, %function
.size of_forward, init-of_forward

#ifdef __linux__
.section .note.GNU-stack, "", %progbits
#endif
