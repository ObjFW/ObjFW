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

#if defined(__i386__) && defined(__ELF__)

.intel_syntax noprefix
.globl objc_msg_lookup
.globl objc_msg_lookup_super

.section .text
objc_msg_lookup:
	mov	edx, [esp+4]
	test	edx, edx
	jz	ret_nil

	mov	edx, [edx]
	mov	edx, [edx+32]

lookup:
	mov	eax, [esp+8]

	movzx	ecx, byte ptr [eax+2]
	mov	edx, [edx+ecx*4]
	movzx	ecx, byte ptr [eax+1]
	mov	edx, [edx+ecx*4]
	movzx	ecx, byte ptr [eax]
	mov	eax, [edx+ecx*4]

	test	eax, eax
	jz	forward

	ret

forward:
	call	get_eip
.L1:
	add	eax, offset objc_forward_handler - offset .L1
	jmp	[eax]

objc_msg_lookup_super:
	mov	edx, [esp+4]
	cmp	dword ptr [edx], 0
	je	ret_nil

	mov	edx, [edx+4]
	mov	edx, [edx+32]
	jmp	lookup

ret_nil:
	call	get_eip
.L2:
	add	eax, offset nil_method - offset .L2
	ret

nil_method:
	mov	eax, [esp+4]
	ret

get_eip:
	mov	eax, dword ptr [esp]
	ret

.type objc_msg_lookup, @function
.type objc_msg_lookup_super, @function
.size objc_msg_lookup, forward-objc_msg_lookup
.size objc_msg_lookup_super, ret_nil-objc_msg_lookup_super

#endif
