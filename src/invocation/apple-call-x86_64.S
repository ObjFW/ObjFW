/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#include "invoke-x86_64.h"

.intel_syntax noprefix

.globl _of_invocation_call

.section __TEXT, __text, regular, pure_instructions
_of_invocation_call:
	push	rbp
	mov	rbp, rsp

	sub	rsp, 16
	and	rsp, -16
	mov	[rbp-8], rdi

	lea	rdx, [rdi+OFFSET_STACK]
	mov	rcx, [rdi+OFFSET_STACK_SIZE]

	test	rcx, 1
	jnz	Lfix_align

Lfill_stack:
	test	rcx, rcx
	jz	Lstack_filled

	dec	rcx
	mov	r11, [rdx+rcx*8]
	push	r11

	jmp	Lfill_stack

Lstack_filled:
	mov	al, [rdi+OFFSET_NUM_SSE_USED]

	movaps	xmm7, [rdi+OFFSET_SSE_INOUT+112]
	movaps	xmm6, [rdi+OFFSET_SSE_INOUT+96]
	movaps	xmm5, [rdi+OFFSET_SSE_INOUT+80]
	movaps	xmm4, [rdi+OFFSET_SSE_INOUT+64]
	movaps	xmm3, [rdi+OFFSET_SSE_INOUT+48]
	movaps	xmm2, [rdi+OFFSET_SSE_INOUT+32]
	movaps	xmm1, [rdi+OFFSET_SSE_INOUT+16]
	movaps	xmm0, [rdi+OFFSET_SSE_INOUT]

	mov	r9,  [rdi+OFFSET_GPR_IN+40]
	mov	r8,  [rdi+OFFSET_GPR_IN+32]
	mov	rcx, [rdi+OFFSET_GPR_IN+24]
	mov	rdx, [rdi+OFFSET_GPR_IN+16]
	mov	rsi, [rdi+OFFSET_GPR_IN+8]

	mov	r11b, [rdi+OFFSET_RETURN_TYPE]
	mov	rdi,  [rdi+OFFSET_GPR_IN]

	cmp	r11b, RETURN_TYPE_STRET
	je	Lcall_send_stret

	cmp	r11b, RETURN_TYPE_JMP
	je	_objc_msgSend

	cmp	r11b, RETURN_TYPE_JMP_STRET
	je	_objc_msgSend_stret

	call	_objc_msgSend

Lafter_send:
	mov	rdi, [rbp-8]
	mov	[rdi+OFFSET_GPR_OUT], rax
	mov	[rdi+OFFSET_GPR_OUT+8], rdx
	movaps	[rdi+OFFSET_SSE_INOUT], xmm0
	movaps	[rdi+OFFSET_SSE_INOUT+16], xmm1

	mov	r11b, [rdi+OFFSET_RETURN_TYPE]

	cmp	r11b, RETURN_TYPE_X87
	je	Lpop_long_double

	cmp	r11b, RETURN_TYPE_COMPLEX_X87
	je	Lpop_complex_long_double

Lreturn:
	mov	rsp, rbp
	pop	rbp

	ret

Lfix_align:
	xor	r11, r11
	push	r11
	jmp	Lfill_stack

Lcall_send_stret:
	call	_objc_msgSend_stret
	jmp	Lafter_send

Lpop_long_double:
	fstp	tbyte ptr [rdi+OFFSET_X87_OUT]
	jmp	Lreturn

Lpop_complex_long_double:
	fstp	tbyte ptr [rdi+OFFSET_X87_OUT]
	fstp	tbyte ptr [rdi+OFFSET_X87_OUT+16]
	jmp	Lreturn
