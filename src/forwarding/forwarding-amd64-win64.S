/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#ifdef HAVE_CET_H
# include <cet.h>
#else
# define _CET_ENDBR
#endif

.globl OFForward
.globl OFForward_stret

.section .text
OFForward:
	_CET_ENDBR

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
	leaq	.Lsel_forwardingTargetForSelector_(%rip), %rdx
	call	class_respondsToSelector

	testq	%rax, %rax
	jz	0f

	movq	-0x30(%rbp), %rcx
	leaq	.Lsel_forwardingTargetForSelector_(%rip), %rdx
	call	objc_msg_lookup

	movq	-0x30(%rbp), %rcx
	leaq	.Lsel_forwardingTargetForSelector_(%rip), %rdx
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

	jmp	OFMethodNotFound
.def OFForward
.scl 2
.type 32
.endef

OFForward_stret:
	_CET_ENDBR

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
	leaq	.Lsel_forwardingTargetForSelector_(%rip), %rdx
	call	class_respondsToSelector

	testq	%rax, %rax
	jz	0f

	movq	-0x38(%rbp), %rcx
	leaq	.Lsel_forwardingTargetForSelector_(%rip), %rdx
	call	objc_msg_lookup

	movq	-0x38(%rbp), %rcx
	leaq	.Lsel_forwardingTargetForSelector_(%rip), %rdx
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

	jmp	OFMethodNotFound_stret
.def OFForward_stret
.scl 2
.type 32
.endef

.Linit:
	_CET_ENDBR

	leaq	.Lmodule(%rip), %rcx
	jmp	__objc_exec_class

.section .ctors, "aw"
	.quad .Linit

.section .rodata
.Lstr_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section .data
.Lsel_forwardingTargetForSelector_:
	.quad .Lstr_forwardingTargetForSelector_, 0
	.quad 0, 0
.Lsymtab:
	.long 0, 0
	.quad .Lsel_forwardingTargetForSelector_
	.short 0, 0
	.long 0
	.quad 0
.Lmodule:
	.long 8, 32
	.quad 0, .Lsymtab
