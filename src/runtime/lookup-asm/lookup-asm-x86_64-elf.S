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

#include "platform.h"

.intel_syntax noprefix

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro generate_lookup name not_found
\name:
	test	rdi, rdi
	jz	short ret_nil

	bt	edi, 0
	jc	short .Ltagged_pointer_\name

	mov	r8, [rdi]
	mov	r8, [r8+64]

.Lmain_\name:
	mov	rax, [rsi]
	movzx	ecx, ah
	movzx	edx, al
#ifdef OF_SELUID24
	shr	eax, 16

	mov	r8,  [r8+rax*8]
#endif
	mov	r8,  [r8+rcx*8]
	mov	rax, [r8+rdx*8]

	test	rax, rax
	jz	short \not_found@PLT

	ret

.Ltagged_pointer_\name:
	movzx	r8, dil
	shr	r8, 1

	mov	rax, [rip+objc_tagged_pointer_classes@GOTPCREL]
	mov	r8, [rax+r8*8]
	mov	r8, [r8+64]

	jmp	short .Lmain_\name
.type \name, %function
.size \name, .-\name
.endm

.macro generate_lookup_super name lookup
\name:
	mov	r8, rdi
	mov	rdi, [rdi]
	test	rdi, rdi
	jz	short ret_nil

	mov	r8, [r8+8]
	mov	r8, [r8+64]
	jmp	short .Lmain_\lookup
.type \name, %function
.size \name, .-\name
.endm

generate_lookup objc_msg_lookup objc_method_not_found
generate_lookup objc_msg_lookup_stret objc_method_not_found_stret
generate_lookup_super objc_msg_lookup_super objc_msg_lookup
generate_lookup_super objc_msg_lookup_super_stret objc_msg_lookup_stret

ret_nil:
	lea	rax, [rip+nil_method]
	ret

nil_method:
	xor	rax, rax
	ret

#ifdef OF_LINUX
.section .note.GNU-stack, "", %progbits
#endif
