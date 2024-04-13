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

#include "platform.h"

#ifdef HAVE_CET_H
# include <cet.h>
#else
# define _CET_ENDBR
#endif

.globl _OFForward
.globl _OFForward_stret

.section __TEXT, __text, regular, pure_instructions
_OFForward:
	_CET_ENDBR

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
	leaq	Lsel_forwardingTargetForSelector_(%rip), %rsi
	call	_class_respondsToSelector

	testq	%rax, %rax
	jz	0f

	movq	-0x10(%rbp), %rdi
	leaq	Lsel_forwardingTargetForSelector_(%rip), %rsi
	call	_objc_msg_lookup

	movq	-0x10(%rbp), %rdi
	leaq	Lsel_forwardingTargetForSelector_(%rip), %rsi
	movq	-0x18(%rbp), %rdx
	call	*%rax

	testq	%rax, %rax
	jz	0f
	cmpq	-0x10(%rbp), %rax
	je	0f

	movq	%rax, -0x10(%rbp)

	movq	%rax, %rdi
	movq	-0x18(%rbp), %rsi
	call	_objc_msg_lookup
	movq	%rax, %r11

	/* Restore all arguments */
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
	movq	-0x10(%rbp), %rdi
	movq	-0x8(%rbp), %rax

	movq	%rbp, %rsp
	popq	%rbp

	jmpq	*%r11

0:
	movq	-0x10(%rbp), %rdi
	movq	-0x18(%rbp), %rsi

	movq	%rbp, %rsp
	popq	%rbp

	jmp	_OFMethodNotFound

_OFForward_stret:
	_CET_ENDBR

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
	leaq	Lsel_forwardingTargetForSelector_(%rip), %rsi
	call	_class_respondsToSelector

	testq	%rax, %rax
	jz	0f

	movq	-0x18(%rbp), %rdi
	leaq	Lsel_forwardingTargetForSelector_(%rip), %rsi
	call	_objc_msg_lookup

	movq	-0x18(%rbp), %rdi
	leaq	Lsel_forwardingTargetForSelector_(%rip), %rsi
	movq	-0x20(%rbp), %rdx
	call	*%rax

	testq	%rax, %rax
	jz	0f
	cmpq	-0x18(%rbp), %rax
	je	0f

	movq	%rax, -0x18(%rbp)

	movq	%rax, %rdi
	movq	-0x20(%rbp), %rsi
	call	_objc_msg_lookup_stret
	movq	%rax, %r11

	/* Restore all arguments */
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
	movq	-0x10(%rbp), %rdi
	movq	-0x8(%rbp), %rax

	movq	%rbp, %rsp
	popq	%rbp

	jmpq	*%r11

0:
	movq	-0x10(%rbp), %rdi
	movq	-0x18(%rbp), %rsi
	movq	-0x20(%rbp), %rdx

	movq	%rbp, %rsp
	popq	%rbp

	jmp	_OFMethodNotFound_stret

Linit:
	_CET_ENDBR

	leaq	Lmodule(%rip), %rdi
	jmp	___objc_exec_class

.section __DATA, __mod_init_func, mod_init_funcs
	.quad Linit

.section __TEXT, __cstring, cstring_literals
Lstr_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section __DATA, __data
Lsel_forwardingTargetForSelector_:
	.quad Lstr_forwardingTargetForSelector_, 0
	.quad 0, 0
Lsymtab:
	.quad 0, Lsel_forwardingTargetForSelector_
	.short 0, 0
	.long 0
	.quad 0
Lmodule:
	.quad 8, 32, 0, Lsymtab
