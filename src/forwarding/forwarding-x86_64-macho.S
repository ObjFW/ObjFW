/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

.intel_syntax noprefix

.globl _of_forward
.globl _of_forward_stret

.section __TEXT, __text, regular, pure_instructions
_of_forward:
	push	rbp
	mov	rbp, rsp

	/* Save all arguments */
	sub	rsp, 0xC0	/* 16-byte alignment */
	mov	[rbp-0x08], rax
	mov	[rbp-0x10], rdi
	mov	[rbp-0x18], rsi
	mov	[rbp-0x20], rdx
	mov	[rbp-0x28], rcx
	mov	[rbp-0x30], r8
	mov	[rbp-0x38], r9
	movaps	[rbp-0x50], xmm0
	movaps	[rbp-0x60], xmm1
	movaps	[rbp-0x70], xmm2
	movaps	[rbp-0x80], xmm3
	movaps	[rbp-0x90], xmm4
	movaps	[rbp-0xA0], xmm5
	movaps	[rbp-0xB0], xmm6
	movaps	[rbp-0xC0], xmm7

	call	_object_getClass

	mov	rdi, rax
	lea	rsi, [rip+sel_forwardingTargetForSelector_]
	call	_class_respondsToSelector

	test	rax, rax
	jz	0f

	mov	rdi, [rbp-0x10]
	lea	rsi, [rip+sel_forwardingTargetForSelector_]
	call	_objc_msg_lookup

	mov	rdi, [rbp-0x10]
	lea	rsi, [rip+sel_forwardingTargetForSelector_]
	mov	rdx, [rbp-0x18]
	call	rax

	test	rax, rax
	jz	0f
	cmp	rax, [rbp-0x10]
	je	0f

	mov	[rbp-0x10], rax

	mov	rdi, rax
	mov	rsi, [rbp-0x18]
	call	_objc_msg_lookup
	mov	r11, rax

	/* Restore all arguments */
	movaps	xmm7, [rbp-0xC0]
	movaps	xmm6, [rbp-0xB0]
	movaps	xmm5, [rbp-0xA0]
	movaps	xmm4, [rbp-0x90]
	movaps	xmm3, [rbp-0x80]
	movaps	xmm2, [rbp-0x70]
	movaps	xmm1, [rbp-0x60]
	movaps	xmm0, [rbp-0x50]
	mov	r9,   [rbp-0x38]
	mov	r8,   [rbp-0x30]
	mov	rcx,  [rbp-0x28]
	mov	rdx,  [rbp-0x20]
	mov	rsi,  [rbp-0x18]
	mov	rdi,  [rbp-0x10]
	mov	rax,  [rbp-0x08]

	mov	rsp, rbp
	pop	rbp

	jmp	r11

0:
	mov	rdi, [rbp-0x10]
	mov	rsi, [rbp-0x18]

	mov	rsp, rbp
	pop	rbp

	jmp	_of_method_not_found

_of_forward_stret:
	push	rbp
	mov	rbp, rsp

	/* Save all arguments */
	sub	rsp, 0xC0	/* 16-byte alignment */
	mov	[rbp-0x08], rax
	mov	[rbp-0x10], rdi
	mov	[rbp-0x18], rsi
	mov	[rbp-0x20], rdx
	mov	[rbp-0x28], rcx
	mov	[rbp-0x30], r8
	mov	[rbp-0x38], r9
	movaps	[rbp-0x50], xmm0
	movaps	[rbp-0x60], xmm1
	movaps	[rbp-0x70], xmm2
	movaps	[rbp-0x80], xmm3
	movaps	[rbp-0x90], xmm4
	movaps	[rbp-0xA0], xmm5
	movaps	[rbp-0xB0], xmm6
	movaps	[rbp-0xC0], xmm7

	mov	rdi, rsi
	call	_object_getClass

	mov	rdi, rax
	lea	rsi, [rip+sel_forwardingTargetForSelector_]
	call	_class_respondsToSelector

	test	rax, rax
	jz	0f

	mov	rdi, [rbp-0x18]
	lea	rsi, [rip+sel_forwardingTargetForSelector_]
	call	_objc_msg_lookup

	mov	rdi, [rbp-0x18]
	lea	rsi, [rip+sel_forwardingTargetForSelector_]
	mov	rdx, [rbp-0x20]
	call	rax

	test	rax, rax
	jz	0f
	cmp	rax, [rbp-0x18]
	je	0f

	mov	[rbp-0x18], rax

	mov	rdi, rax
	mov	rsi, [rbp-0x20]
	call	_objc_msg_lookup_stret
	mov	r11, rax

	/* Restore all arguments */
	movaps	xmm7, [rbp-0xC0]
	movaps	xmm6, [rbp-0xB0]
	movaps	xmm5, [rbp-0xA0]
	movaps	xmm4, [rbp-0x90]
	movaps	xmm3, [rbp-0x80]
	movaps	xmm2, [rbp-0x70]
	movaps	xmm1, [rbp-0x60]
	movaps	xmm0, [rbp-0x50]
	mov	r9,   [rbp-0x38]
	mov	r8,   [rbp-0x30]
	mov	rcx,  [rbp-0x28]
	mov	rdx,  [rbp-0x20]
	mov	rsi,  [rbp-0x18]
	mov	rdi,  [rbp-0x10]
	mov	rax,  [rbp-0x08]

	mov	rsp, rbp
	pop	rbp

	jmp	r11

0:
	mov	rdi, [rbp-0x10]
	mov	rsi, [rbp-0x18]
	mov	rdx, [rbp-0x20]

	mov	rsp, rbp
	pop	rbp

	jmp	_of_method_not_found_stret

init:
	lea	rdi, [rip+module]
	jmp	___objc_exec_class

.section __DATA, __mod_init_func, mod_init_funcs
	.quad init

.section __TEXT, __cstring, cstring_literals
str_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section __DATA, __data
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
