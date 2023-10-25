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

	call	getEIP
	add	ebx, offset _GLOBAL_OFFSET_TABLE_

	mov	eax, [ebp + 8]
	mov	[esp], eax
	call	object_getClass@PLT

	mov	[esp], eax
	lea	eax, [ebx + sel_forwardingTargetForSelector_@GOTOFF]
	mov	[esp + 4], eax
	call	class_respondsToSelector@PLT

	test	eax, eax
	jz	short 0f

	mov	eax, [ebp + 8]
	mov	[esp], eax
	lea	eax, [ebx + sel_forwardingTargetForSelector_@GOTOFF]
	mov	[esp + 4], eax
	call	objc_msg_lookup@PLT

	mov	edx, [ebp + 8]
	mov	[esp], edx
	lea	edx, [ebx + sel_forwardingTargetForSelector_@GOTOFF]
	mov	[esp + 4], edx
	mov	edx, [ebp + 12]
	mov	[esp + 8], edx
	call	eax

	test	eax, eax
	jz	short 0f
	cmp	eax, [ebp + 8]
	je	short 0f

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

	call	getEIP
	add	ebx, offset _GLOBAL_OFFSET_TABLE_

	mov	eax, [ebp + 12]
	mov	[esp], eax
	call	object_getClass@PLT

	mov	[esp], eax
	lea	eax, [ebx + sel_forwardingTargetForSelector_@GOTOFF]
	mov	[esp + 4], eax
	call	class_respondsToSelector@PLT

	test	eax, eax
	jz	short 0f

	mov	eax, [ebp + 12]
	mov	[esp], eax
	lea	eax, [ebx + sel_forwardingTargetForSelector_@GOTOFF]
	mov	[esp  + 4], eax
	call	objc_msg_lookup@PLT

	mov	edx, [ebp + 12]
	mov	[esp], edx
	lea	edx, [ebx + sel_forwardingTargetForSelector_@GOTOFF]
	mov	[esp + 4], edx
	mov	edx, [ebp + 16]
	mov	[esp + 8], edx
	call	eax

	test	eax, eax
	jz	short 0f
	cmp	eax, [ebp + 12]
	je	short 0f

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

init:
	push	ebp
	mov	ebp, esp

	push	ebx
	sub	esp, 4

	call	getEIP
	add	ebx, offset _GLOBAL_OFFSET_TABLE_

	lea	eax, [ebx + module@GOTOFF]
	mov	[esp], eax
	call	__objc_exec_class@PLT

	add	esp, 4
	pop	ebx
	pop	ebp
	ret

getEIP:
	mov	ebx, [esp]
	ret

#ifdef OF_SOLARIS
.section .init_array, "aw"
#else
.section .ctors, "aw", %progbits
#endif
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

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", %progbits
#endif
