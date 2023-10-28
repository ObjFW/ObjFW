/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

.globl _OFForward
.globl _OFForward_stret

.section .text
_OFForward:
	push	ebp
	mov	ebp, esp

	push	ebx
	sub	esp, 20

	mov	eax, [ebp + 8]
	mov	[esp], eax
	call	_object_getClass

	mov	[esp], eax
	mov	eax, offset .Lsel_forwardingTargetForSelector_
	mov	[esp + 4], eax
	call	_class_respondsToSelector

	test	eax, eax
	jz	0f

	mov	eax, [ebp + 8]
	mov	[esp], eax
	mov	eax, offset .Lsel_forwardingTargetForSelector_
	mov	[esp + 4], eax
	call	_objc_msg_lookup

	mov	edx, [ebp + 8]
	mov	[esp], edx
	mov	edx, offset .Lsel_forwardingTargetForSelector_
	mov	[esp + 4], edx
	mov	edx, [ebp + 12]
	mov	[esp + 8], edx
	call	eax

	test	eax, eax
	jz	0f
	cmp	eax, [ebp + 8]
	je	0f

	mov	[ebp + 8], eax
	mov	[esp], eax
	mov	eax, [ebp + 12]
	mov	[esp + 4], eax
	call	_objc_msg_lookup

	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	eax

0:
	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	_OFMethodNotFound
.def _OFForward
.scl 2
.type 32
.endef

_OFForward_stret:
	push	ebp
	mov	ebp, esp

	push	ebx
	sub	esp, 20

	mov	eax, [ebp + 12]
	mov	[esp], eax
	call	_object_getClass

	mov	[esp], eax
	mov	eax, offset .Lsel_forwardingTargetForSelector_
	mov	[esp + 4], eax
	call	_class_respondsToSelector

	test	eax, eax
	jz	0f

	mov	eax, [ebp + 12]
	mov	[esp], eax
	mov	eax, offset .Lsel_forwardingTargetForSelector_
	mov	[esp + 4], eax
	call	_objc_msg_lookup

	mov	edx, [ebp + 12]
	mov	[esp], edx
	mov	edx, offset .Lsel_forwardingTargetForSelector_
	mov	[esp + 4], edx
	mov	edx, [ebp + 16]
	mov	[esp + 8], edx
	call	eax

	test	eax, eax
	jz	0f
	cmp	eax, [ebp + 12]
	je	0f

	mov	[ebp + 12], eax
	mov	[esp], eax
	mov	eax, [ebp + 16]
	mov	[esp + 4], eax
	call	_objc_msg_lookup_stret

	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	eax

0:
	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	_OFMethodNotFound_stret
.def _OFForward_stret
.scl 2
.type 32
.endef

.Linit:
	push	ebp
	mov	ebp, esp

	push	ebx
	sub	esp, 4

	mov	eax, offset .Lmodule
	mov	[esp], eax
	call	___objc_exec_class

	add	esp, 4
	pop	ebx
	pop	ebp
	ret

.section .ctors, "aw"
	.long .Linit

.section .rodata
.Lstr_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section .data
.Lsel_forwardingTargetForSelector_:
	.long .Lstr_forwardingTargetForSelector_, 0
	.long 0, 0
.Lsymtab:
	.long 0, .Lsel_forwardingTargetForSelector_
	.short 0, 0
	.long 0
	.long 0
.Lmodule:
	.long 8, 16, 0, .Lsymtab
