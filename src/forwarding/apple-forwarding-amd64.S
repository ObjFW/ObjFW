/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

.intel_syntax noprefix

/* Work around assembler bugs. */
.macro call
	.att_syntax
	/* Use uppercase instruction to avoid recursion. */
	CALL	$0
	.intel_syntax noprefix
.endmacro
.macro jmp
	.att_syntax
	/* Use uppercase instruction to avoid recursion. */
	JMP	$0
	.intel_syntax noprefix
.endmacro

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
	push	rbp
	mov	rbp, rsp

	/* Save all arguments */
	sub	rsp, 0xC0	/* 16-byte alignment */
	mov	[rbp - 0x08], rax
	mov	[rbp - 0x10], rdi
	mov	[rbp - 0x18], rsi
	mov	[rbp - 0x20], rdx
	mov	[rbp - 0x28], rcx
	mov	[rbp - 0x30], r8
	mov	[rbp - 0x38], r9
	movaps	[rbp - 0x50], xmm0
	movaps	[rbp - 0x60], xmm1
	movaps	[rbp - 0x70], xmm2
	movaps	[rbp - 0x80], xmm3
	movaps	[rbp - 0x90], xmm4
	movaps	[rbp - 0xA0], xmm5
	movaps	[rbp - 0xB0], xmm6
	movaps	[rbp - 0xC0], xmm7

	call	_object_getClass

	mov	rdi, rax
	mov	rsi, [rip + Lsel_forwardingTargetForSelector_]
	call	_class_respondsToSelector

	test	rax, rax
	jz	0f

	mov	rdi, [rbp - 0x10]
	mov	rsi, [rip + Lsel_forwardingTargetForSelector_]
	mov	rdx, [rbp - 0x18]
	call	_objc_msgSend

	test	rax, rax
	jz	0f
	cmp	rax, [rbp - 0x10]
	je	0f

	mov	rdi, rax

	/* Restore all arguments, except %rdi */
	movaps	xmm7, [rbp - 0xC0]
	movaps	xmm6, [rbp - 0xB0]
	movaps	xmm5, [rbp - 0xA0]
	movaps	xmm4, [rbp - 0x90]
	movaps	xmm3, [rbp - 0x80]
	movaps	xmm2, [rbp - 0x70]
	movaps	xmm1, [rbp - 0x60]
	movaps	xmm0, [rbp - 0x50]
	mov	r9, [rbp - 0x38]
	mov	r8, [rbp - 0x30]
	mov	rcx, [rbp - 0x28]
	mov	rdx, [rbp - 0x20]
	mov	rsi, [rbp - 0x18]
	mov	rax, [rbp - 0x08]

	mov	rsp, rbp
	pop	rbp

	jmp	_objc_msgSend

0:
	mov	rdi, [rbp - 0x10]
	mov	rsi, [rbp - 0x18]

	mov	rsp, rbp
	pop	rbp

	jmp	_OFMethodNotFound

_OFForward_stret:
	push	rbp
	mov	rbp, rsp

	/* Save all arguments */
	sub	rsp, 0xC0	/* 16-byte alignment */
	movq	[rbp - 0x08], rax
	movq	[rbp - 0x10], rdi
	movq	[rbp - 0x18], rsi
	movq	[rbp - 0x20], rdx
	movq	[rbp - 0x28], rcx
	movq	[rbp - 0x30], r8
	movq	[rbp - 0x38], r9
	movaps	[rbp - 0x50], xmm0
	movaps	[rbp - 0x60], xmm1
	movaps	[rbp - 0x70], xmm2
	movaps	[rbp - 0x80], xmm3
	movaps	[rbp - 0x90], xmm4
	movaps	[rbp - 0xA0], xmm5
	movaps	[rbp - 0xB0], xmm6
	movaps	[rbp - 0xC0], xmm7

	mov	rdi, rsi
	call	_object_getClass

	mov	rdi, rax
	mov	rsi, [rip + Lsel_forwardingTargetForSelector_]
	call	_class_respondsToSelector
	test	rax, rax
	jz	0f

	mov	rdi, [rbp - 0x18]
	mov	rsi, [rip + Lsel_forwardingTargetForSelector_]
	mov	rdx, [rbp - 0x20]
	call	_objc_msgSend

	test	rax, rax
	jz	0f
	cmp	rax, [rbp - 0x18]
	je	0f

	mov	rsi, rax

	/* Restore all arguments, except %rsi */
	movaps	xmm7, [rbp - 0xC0]
	movaps	xmm6, [rbp - 0xB0]
	movaps	xmm5, [rbp - 0xA0]
	movaps	xmm4, [rbp - 0x90]
	movaps	xmm3, [rbp - 0x80]
	movaps	xmm2, [rbp - 0x70]
	movaps	xmm1, [rbp - 0x60]
	movaps	xmm0, [rbp - 0x50]
	mov	r9, [rbp - 0x38]
	mov	r8, [rbp - 0x30]
	mov	rcx, [rbp - 0x28]
	mov	rdx, [rbp - 0x20]
	mov	rdi, [rbp - 0x10]
	mov	rax, [rbp - 0x08]

	mov	rsp, rbp
	pop	rbp

	jmp	_objc_msgSend_stret

0:
	mov	rdi, [rbp - 0x10]
	mov	rsi, [rbp - 0x18]
	mov	rdx, [rbp - 0x20]

	mov	rsp, rbp
	pop	rbp

	jmp	_OFMethodNotFound_stret
