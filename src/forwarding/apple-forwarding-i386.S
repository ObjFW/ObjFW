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

.intel_syntax noprefix

.globl _of_forward
.globl _of_forward_stret

.section __TEXT, __cstring, cstring_literals
Lstr_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section __OBJC, __message_refs, literal_pointers, no_dead_strip
Lsel_forwardingTargetForSelector_:
	.long Lstr_forwardingTargetForSelector_

.section __OBJC, __image_info
	.long 0, 0

.section __TEXT, __text, regular, pure_instructions
_of_forward:
	push	ebp
	mov	ebp, esp

	push	ebx
	sub	esp, 20

	call	get_eip
0:

	mov	eax, [ebp+8]
	mov	[esp], eax
	call	_object_getClass

	mov	[esp], eax
	.att_syntax	/* Next line is broken in Intel syntax */
	movl	Lsel_forwardingTargetForSelector_-0b(%ebx), %eax
	.intel_syntax noprefix
	mov	[esp+4], eax
	call	_class_respondsToSelector

	test	eax, eax
	jz	0f

	mov	eax, [ebp+8]
	mov	[esp], eax
	.att_syntax	/* Next line is broken in Intel syntax */
	movl	Lsel_forwardingTargetForSelector_-0b(%ebx), %eax
	.intel_syntax noprefix
	mov	[esp+4], eax
	mov	eax, [ebp+12]
	mov	[esp+8], eax
	call	_objc_msgSend

	test	eax, eax
	jz	0f
	cmp	eax, [ebp+8]
	je	0f

	mov	[ebp+8], eax

	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	_objc_msgSend

0:
	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	_of_method_not_found

_of_forward_stret:
	push	ebp
	mov	ebp, esp

	push	ebx
	sub	esp, 20

	call	get_eip
0:

	mov	eax, [ebp+12]
	mov	[esp], eax
	call	_object_getClass

	mov	[esp], eax
	.att_syntax	/* Next line is broken in Intel syntax */
	movl	Lsel_forwardingTargetForSelector_-0b(%ebx), %eax
	.intel_syntax noprefix
	mov	[esp+4], eax
	call	_class_respondsToSelector

	test	eax, eax
	jz	0f

	mov	eax, [ebp+12]
	mov	[esp], eax
	.att_syntax	/* Next line is broken in Intel syntax */
	movl	Lsel_forwardingTargetForSelector_-0b(%ebx), %eax
	.intel_syntax noprefix
	mov	[esp+4], eax
	mov	eax, [ebp+16]
	mov	[esp+8], eax
	call	_objc_msgSend

	test	eax, eax
	jz	0f
	cmp	eax, [ebp+12]
	je	0f

	mov	[ebp+12], eax

	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	_objc_msgSend_stret

0:
	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	_of_method_not_found_stret

get_eip:
	mov	ebx, [esp]
	ret
