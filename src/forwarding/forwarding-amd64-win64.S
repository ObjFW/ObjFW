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

.intel_syntax noprefix

.globl OFForward
.globl OFForward_stret

.section .text
OFForward:
	push	rbp
	mov	rbp, rsp

	/* Save all arguments */
	sub	rsp, 0x90	/* 16-byte alignment */
	mov	[rbp - 0x28], rax
	mov	[rbp - 0x30], rcx
	mov	[rbp - 0x38], rdx
	mov	[rbp - 0x40], r8
	mov	[rbp - 0x48], r9
	movaps	[rbp - 0x60], xmm0
	movaps	[rbp - 0x70], xmm1
	movaps	[rbp - 0x80], xmm2
	movaps	[rbp - 0x90], xmm3

	call	object_getClass

	mov	rcx, rax
	lea	rdx, [rip + sel_forwardingTargetForSelector_]
	call	class_respondsToSelector

	test	rax, rax
	jz	short 0f

	mov	rcx, [rbp - 0x30]
	lea	rdx, [rip + sel_forwardingTargetForSelector_]
	call	objc_msg_lookup

	mov	rcx, [rbp - 0x30]
	lea	rdx, [rip + sel_forwardingTargetForSelector_]
	mov	r8, [rbp - 0x38]
	call	rax

	test	rax, rax
	jz	short 0f
	cmp	rax, [rbp - 0x30]
	je	short 0f

	mov	[rbp - 0x30], rax

	mov	rcx, rax
	mov	rdx, [rbp - 0x38]
	call	objc_msg_lookup
	mov	r11, rax

	/* Restore all arguments */
	movaps	xmm3, [rbp - 0x90]
	movaps	xmm2, [rbp - 0x80]
	movaps	xmm1, [rbp - 0x70]
	movaps	xmm0, [rbp - 0x60]
	mov	r9, [rbp - 0x48]
	mov	r8, [rbp - 0x40]
	mov	rdx, [rbp - 0x38]
	mov	rcx, [rbp - 0x30]
	mov	rax, [rbp - 0x28]

	mov	rsp, rbp
	pop	rbp

	jmp	r11

0:
	mov	rcx, [rbp - 0x30]
	mov	rdx, [rbp - 0x38]

	mov	rsp, rbp
	pop	rbp

	jmp	OFMethodNotFound
.def OFForward
.scl 2
.type 32
.endef

OFForward_stret:
	push	rbp
	mov	rbp, rsp

	/* Save all arguments */
	sub	rsp, 0x90	/* 16-byte alignment */
	mov	[rbp - 0x28], rax
	mov	[rbp - 0x30], rcx
	mov	[rbp - 0x38], rdx
	mov	[rbp - 0x40], r8
	mov	[rbp - 0x48], r9
	movaps	[rbp - 0x60], xmm0
	movaps	[rbp - 0x70], xmm1
	movaps	[rbp - 0x80], xmm2
	movaps	[rbp - 0x90], xmm3

	mov	rcx, rdx
	call	object_getClass

	mov	rcx, rax
	lea	rdx, [rip + sel_forwardingTargetForSelector_]
	call	class_respondsToSelector

	test	rax, rax
	jz	short 0f

	mov	rcx, [rbp - 0x38]
	lea	rdx, [rip + sel_forwardingTargetForSelector_]
	call	objc_msg_lookup

	mov	rcx, [rbp - 0x38]
	lea	rdx, [rip + sel_forwardingTargetForSelector_]
	mov	r8, [rbp - 0x40]
	call	rax

	test	rax, rax
	jz	short 0f
	cmp	rax, [rbp - 0x38]
	je	short 0f

	mov	[rbp - 0x38], rax

	mov	rcx, rax
	mov	rdx, [rbp - 0x40]
	call	objc_msg_lookup_stret
	mov	r11, rax

	/* Restore all arguments */
	movaps	xmm3, [rbp - 0x90]
	movaps	xmm2, [rbp - 0x80]
	movaps	xmm1, [rbp - 0x70]
	movaps	xmm0, [rbp - 0x60]
	mov	r9, [rbp - 0x48]
	mov	r8, [rbp - 0x40]
	mov	rdx, [rbp - 0x38]
	mov	rcx, [rbp - 0x30]
	mov	rax, [rbp - 0x28]

	mov	rsp, rbp
	pop	rbp

	jmp	r11

0:
	mov	rcx, [rbp - 0x30]
	mov	rdx, [rbp - 0x38]
	mov	r8, [rbp - 0x40]

	mov	rsp, rbp
	pop	rbp

	jmp	OFMethodNotFound_stret
.def OFForward_stret
.scl 2
.type 32
.endef

init:
	lea	rcx, [rip + module]
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
