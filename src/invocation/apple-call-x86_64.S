/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

.globl _of_invocation_call

.section __TEXT, __text, regular, pure_instructions
_of_invocation_call:
	pushq	%rbp
	movq	%rsp, %rbp

	subq	$16, %rsp
	movq	%rdi, -8(%rbp)

	movb	177(%rdi), %al

	movdqa	176(%rdi), %xmm7
	movdqa	160(%rdi), %xmm6
	movdqa	144(%rdi), %xmm5
	movdqa	128(%rdi), %xmm4
	movdqa	112(%rdi), %xmm3
	movdqa	96(%rdi), %xmm2
	movdqa	80(%rdi), %xmm1
	movdqa	64(%rdi), %xmm0

	movq	40(%rdi), %r9
	movq	32(%rdi), %r8
	movq	24(%rdi), %rcx
	movq	16(%rdi), %rdx
	movq	8(%rdi), %rsi
	movq	0(%rdi), %rdi

	call	_objc_msgSend

	movq	-8(%rbp), %rdi
	movq	%rax, 48(%rdi)
	movq	%rdx, 56(%rdi)
	movdqa	%xmm0, 64(%rdi)
	movdqa	%xmm1, 80(%rdi)

	movq	%rbp, %rsp
	popq	%rbp

	ret
