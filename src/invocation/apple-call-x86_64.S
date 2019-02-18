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

#include "invoke-x86_64.h"

.globl _of_invocation_call

.section __TEXT, __text, regular, pure_instructions
_of_invocation_call:
	pushq	%rbp
	movq	%rsp, %rbp

	subq	$16, %rsp
	andq	$-16, %rsp
	movq	%rdi, -8(%rbp)

	leaq	OFFSET_STACK(%rdi), %rdx
	movq	OFFSET_STACK_SIZE(%rdi), %rcx

	testq	$1, %rcx
	jnz	Lfix_align

Lfill_stack:
	testq	%rcx, %rcx
	jz	Lstack_filled

	decq	%rcx
	movq	(%rdx,%rcx,8), %r11
	pushq	%r11

	jmp	Lfill_stack

Lstack_filled:
	movb	OFFSET_NUM_SSE_USED(%rdi), %al

	movaps	OFFSET_SSE_INOUT+112(%rdi), %xmm7
	movaps	OFFSET_SSE_INOUT+96(%rdi), %xmm6
	movaps	OFFSET_SSE_INOUT+80(%rdi), %xmm5
	movaps	OFFSET_SSE_INOUT+64(%rdi), %xmm4
	movaps	OFFSET_SSE_INOUT+48(%rdi), %xmm3
	movaps	OFFSET_SSE_INOUT+32(%rdi), %xmm2
	movaps	OFFSET_SSE_INOUT+16(%rdi), %xmm1
	movaps	OFFSET_SSE_INOUT(%rdi), %xmm0

	movq	OFFSET_GPR_IN+40(%rdi), %r9
	movq	OFFSET_GPR_IN+32(%rdi), %r8
	movq	OFFSET_GPR_IN+24(%rdi), %rcx
	movq	OFFSET_GPR_IN+16(%rdi), %rdx
	movq	OFFSET_GPR_IN+8(%rdi), %rsi

	movb	OFFSET_RETURN_TYPE(%rdi), %r11b
	movq	OFFSET_GPR_IN(%rdi), %rdi

	cmpb	$RETURN_TYPE_STRET, %r11b
	je	Lcall_send_stret

	cmpb	$RETURN_TYPE_JMP, %r11b
	je	_objc_msgSend

	cmpb	$RETURN_TYPE_JMP_STRET, %r11b
	je	_objc_msgSend_stret

	call	_objc_msgSend

Lafter_send:
	movq	-8(%rbp), %rdi
	movq	%rax, OFFSET_GPR_OUT(%rdi)
	movq	%rdx, OFFSET_GPR_OUT+8(%rdi)
	movaps	%xmm0, OFFSET_SSE_INOUT(%rdi)
	movaps	%xmm1, OFFSET_SSE_INOUT+16(%rdi)

	movb	OFFSET_RETURN_TYPE(%rdi), %r11b

	cmpb	$RETURN_TYPE_X87, %r11b
	je	Lpop_long_double

	cmpb	$RETURN_TYPE_COMPLEX_X87, %r11b
	je	Lpop_complex_long_double

Lreturn:
	movq	%rbp, %rsp
	popq	%rbp

	ret

Lfix_align:
	xorq	%r11, %r11
	pushq	%r11
	jmp	Lfill_stack

Lcall_send_stret:
	call	_objc_msgSend_stret
	jmp	Lafter_send

Lpop_long_double:
	fstpt	OFFSET_X87_OUT(%rdi)
	jmp	Lreturn

Lpop_complex_long_double:
	fstpt	OFFSET_X87_OUT(%rdi)
	fstpt	OFFSET_X87_OUT+16(%rdi)
	jmp	Lreturn
