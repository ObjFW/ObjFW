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

#include "platform.h"

.intel_syntax noprefix

.globl OFForward
.globl OFForward_stret

.section .text
OFForward:
	push	ebp
	mov	ebp, esp

	push	ebx
	sub	esp, 20

	call	.LgetEIP
	add	ebx, offset _GLOBAL_OFFSET_TABLE_

	mov	eax, [ebp + 8]
	mov	[esp], eax
	call	object_getClass@PLT

	mov	[esp], eax
	lea	eax, [ebx + .Lsel_forwardingTargetForSelector_@GOTOFF]
	mov	[esp + 4], eax
	call	class_respondsToSelector@PLT

	test	eax, eax
	jz	0f

	mov	eax, [ebp + 8]
	mov	[esp], eax
	lea	eax, [ebx + .Lsel_forwardingTargetForSelector_@GOTOFF]
	mov	[esp + 4], eax
	call	objc_msg_lookup@PLT

	mov	edx, [ebp + 8]
	mov	[esp], edx
	lea	edx, [ebx + .Lsel_forwardingTargetForSelector_@GOTOFF]
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
	call	objc_msg_lookup@PLT

	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	eax

0:
	mov	eax, [ebx + OFMethodNotFound@GOT]

	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	eax
.type OFForward, %function
.size OFForward, .-OFForward

OFForward_stret:
	push	ebp
	mov	ebp, esp

	push	ebx
	sub	esp, 20

	call	.LgetEIP
	add	ebx, offset _GLOBAL_OFFSET_TABLE_

	mov	eax, [ebp + 12]
	mov	[esp], eax
	call	object_getClass@PLT

	mov	[esp], eax
	lea	eax, [ebx + .Lsel_forwardingTargetForSelector_@GOTOFF]
	mov	[esp + 4], eax
	call	class_respondsToSelector@PLT

	test	eax, eax
	jz	0f

	mov	eax, [ebp + 12]
	mov	[esp], eax
	lea	eax, [ebx + .Lsel_forwardingTargetForSelector_@GOTOFF]
	mov	[esp + 4], eax
	call	objc_msg_lookup@PLT

	mov	edx, [ebp + 12]
	mov	[esp], edx
	lea	edx, [ebx + .Lsel_forwardingTargetForSelector_@GOTOFF]
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
	call	objc_msg_lookup_stret@PLT

	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	eax

0:
	mov	eax, [ebx + OFMethodNotFound_stret@GOT]

	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	eax
.type OFForward_stret, %function
.size OFForward_stret, .-OFForward_stret

.Linit:
	push	ebp
	mov	ebp, esp

	push	ebx
	sub	esp, 4

	call	.LgetEIP
	add	ebx, offset _GLOBAL_OFFSET_TABLE_

	lea	eax, [ebx + .Lmodule@GOTOFF]
	mov	[esp], eax
	call	__objc_exec_class@PLT

	add	esp, 4
	pop	ebx
	pop	ebp
	ret

.LgetEIP:
	mov	ebx, [esp]
	ret

#ifdef OF_SOLARIS
.section .init_array, "aw"
#else
.section .ctors, "aw", %progbits
#endif
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

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", %progbits
#endif
