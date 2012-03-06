/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
 *   Jonathan Schleifer <js@webkeks.org>
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

#if defined(__x86_64__) && defined(__ELF__)

.intel_syntax noprefix
.globl objc_msg_lookup
.globl objc_msg_lookup_super

.section .text
objc_msg_lookup:
	test	rdi, rdi
	jz	ret_nil

	mov	r8, [rdi]
	mov	r8, [r8+64]

lookup:
	mov	rax, [rsi]
	movzx	ecx, ah
	movzx	edx, al
	shr	eax, 16

	mov	r8, [r8+rax*8]
	mov	r8, [r8+rcx*8]
	mov	rax, [r8+rdx*8]

	test	rax, rax
	jz	forward

	ret

forward:
	mov	rax, qword ptr objc_forward_handler@GOTPCREL[rip]
	jmp	[rax]

objc_msg_lookup_super:
	mov	rax, [rdi]
	test	rax, rax
	jz	ret_nil

	mov	r8, [rdi+8]
	mov	r8, [r8+64]
	mov	rdi, rax
	jmp	lookup

ret_nil:
	lea	rax, nil_method[rip]
	ret

nil_method:
	mov	rax, rdi
	ret

.type objc_msg_lookup, @function
.type objc_msg_lookup_super, @function
.size objc_msg_lookup, forward-objc_msg_lookup
.size objc_msg_lookup_super, ret_nil-objc_msg_lookup_super

#endif
