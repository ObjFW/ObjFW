/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

.globl _of_forward
.globl _of_forward_stret

.section __TEXT, __objc_methname, cstring_literals
L_str_forwardingTargetForSelector:
	.asciz "forwardingTargetForSelector:"

.section __DATA, __objc_selrefs, literal_pointers, no_dead_strip
L_sel_forwardingTargetForSelector:
	.quad L_str_forwardingTargetForSelector

.section __DATA, __objc_imageinfo, regular, no_dead_strip
	.long 0, 0

.section __TEXT, __text, regular, pure_instructions
.macro forward dispatch_func
	push	%rbp
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

	call	_object_getClass
	movq	%rax, %rdi
	movq	L_sel_forwardingTargetForSelector(%rip), %rsi
	call	_class_respondsToSelector
	test	%rax, %rax
	jz	fail

	movq	0xA0(%rsp), %rdi
	movq	L_sel_forwardingTargetForSelector(%rip), %rsi
	movq	0x98(%rsp), %rdx
	call	\dispatch_func
	movq	%rax, %rdi

	test	%rdi, %rdi
	jz	fail

	cmp	0xA0(%rsp), %rdi
	je	fail

	/* Restore all arguments, except %rdi */
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
	movq	0xA8(%rsp),  %rax

	movq	%rbp, %rsp
	pop	%rbp

	jmp	\dispatch_func
.endmacro

_of_forward:
	forward	_objc_msgSend
_of_forward_stret:
	forward	_objc_msgSend_stret

fail:
	movq	0xA0(%rsp),  %rdi
	movq	0x98(%rsp),  %rsi

	movq	%rbp, %rsp
	pop	%rbp

	jmp	_of_method_not_found
