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

#include "invoke-x86_64.h"

.globl _OFInvocationCall

.section __TEXT, __text, regular, pure_instructions
_OFInvocationCall:
	pushq	%rbp
	movq	%rsp, %rbp

	subq	$16, %rsp
	andq	$-16, %rsp
	movq	%rdi, -8(%rbp)

	leaq	offsetStack(%rdi), %rdx
	movq	offsetStackSize(%rdi), %rcx

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
	movb	offsetNumSSEUsed(%rdi), %al

	movaps	offsetSSEInOut+112(%rdi), %xmm7
	movaps	offsetSSEInOut+96(%rdi), %xmm6
	movaps	offsetSSEInOut+80(%rdi), %xmm5
	movaps	offsetSSEInOut+64(%rdi), %xmm4
	movaps	offsetSSEInOut+48(%rdi), %xmm3
	movaps	offsetSSEInOut+32(%rdi), %xmm2
	movaps	offsetSSEInOut+16(%rdi), %xmm1
	movaps	offsetSSEInOut(%rdi), %xmm0

	movq	offsetGPRIn+40(%rdi), %r9
	movq	offsetGPRIn+32(%rdi), %r8
	movq	offsetGPRIn+24(%rdi), %rcx
	movq	offsetGPRIn+16(%rdi), %rdx
	movq	offsetGPRIn+8(%rdi), %rsi

	movb	offsetReturnType(%rdi), %r11b
	movq	offsetGPRIn(%rdi), %rdi

	cmpb	$returnTypeStret, %r11b
	je	Lcall_send_stret

	cmpb	$returnTypeJmp, %r11b
	je	_objc_msgSend

	cmpb	$returnTypeJmpStret, %r11b
	je	_objc_msgSend_stret

	call	_objc_msgSend

Lafter_send:
	movq	-8(%rbp), %rdi
	movq	%rax, offsetGPROut(%rdi)
	movq	%rdx, offsetGPROut+8(%rdi)
	movaps	%xmm0, offsetSSEInOut(%rdi)
	movaps	%xmm1, offsetSSEInOut+16(%rdi)

	movb	offsetReturnType(%rdi), %r11b

	cmpb	$returnTypeX87, %r11b
	je	Lpop_long_double

	cmpb	$returnTypeComplexX87, %r11b
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
	fstpt	offsetX87Out(%rdi)
	jmp	Lreturn

Lpop_complex_long_double:
	fstpt	offsetX87Out(%rdi)
	fstpt	offsetX87Out+16(%rdi)
	jmp	Lreturn
