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

.intel_syntax noprefix

.globl _of_forward
.globl _of_forward_stret

.section .text
_of_forward:
	push	ebp
	mov	ebp, esp

	push	ebx
	sub	esp, 20

	mov	eax, [ebp+8]
	mov	[esp], eax
	call	_object_getClass

	mov	[esp], eax
	mov	eax, offset sel_forwardingTargetForSelector_
	mov	[esp+4], eax
	call	_class_respondsToSelector

	test	eax, eax
	jz	short 0f

	mov	eax, [ebp+8]
	mov	[esp], eax
	mov	eax, offset sel_forwardingTargetForSelector_
	mov	[esp+4], eax
	call	_objc_msg_lookup

	mov	edx, [ebp+8]
	mov	[esp], edx
	mov	edx, offset sel_forwardingTargetForSelector_
	mov	[esp+4], edx
	mov	edx, [ebp+12]
	mov	[esp+8], edx
	call	eax

	test	eax, eax
	jz	short 0f
	cmp	eax, [ebp+8]
	je	short 0f

	mov	[ebp+8], eax
	mov	[esp], eax
	mov	eax, [ebp+12]
	mov	[esp+4], eax
	call	_objc_msg_lookup

	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	eax

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

	mov	eax, [ebp+12]
	mov	[esp], eax
	call	_object_getClass

	mov	[esp], eax
	mov	eax, offset sel_forwardingTargetForSelector_
	mov	[esp+4], eax
	call	_class_respondsToSelector

	test	eax, eax
	jz	short 0f

	mov	eax, [ebp+12]
	mov	[esp], eax
	mov	eax, offset sel_forwardingTargetForSelector_
	mov	[esp+4], eax
	call	_objc_msg_lookup

	mov	edx, [ebp+12]
	mov	[esp], edx
	mov	edx, offset sel_forwardingTargetForSelector_
	mov	[esp+4], edx
	mov	edx, [ebp+16]
	mov	[esp+8], edx
	call	eax

	test	eax, eax
	jz	short 0f
	cmp	eax, [ebp+12]
	je	short 0f

	mov	[ebp+12], eax
	mov	[esp], eax
	mov	eax, [ebp+16]
	mov	[esp+4], eax
	call	_objc_msg_lookup_stret

	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	eax

0:
	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	_of_method_not_found_stret

init:
	push	ebp
	mov	ebp, esp

	push	ebx
	sub	esp, 4

	mov	eax, offset module
	mov	[esp], eax
	call	___objc_exec_class

	add	esp, 4
	pop	ebx
	pop	ebp
	ret

.section .ctors, "aw"
	.long init

.section .rodata
str_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section .data
sel_forwardingTargetForSelector_:
	.long str_forwardingTargetForSelector_, 0
	.long 0, 0
symtab:
	.long 0, sel_forwardingTargetForSelector_
	.short 0, 0
	.long 0
	.long 0
module:
	.long 8, 16, 0, symtab
