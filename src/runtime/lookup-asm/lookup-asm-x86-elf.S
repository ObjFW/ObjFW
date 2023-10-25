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

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro GENERATE_LOOKUP name notFound
\name:
	mov	edx, [esp + 4]
	test	edx, edx
	jz	short returnNilMethod

	test	dl, 1
	jnz	short .LtaggedPointer_\name

	mov	edx, [edx]
	mov	edx, [edx + 32]

.Lmain_\name:
	mov	eax, [esp + 8]

#ifdef OF_SELUID24
	movzx	ecx, byte ptr [eax + 2]
	mov	edx, [edx + 4 * ecx]
#endif
	movzx	ecx, byte ptr [eax + 1]
	mov	edx, [edx + 4 * ecx]
	movzx	ecx, byte ptr [eax]
	mov	eax, [edx + 4 * ecx]

	test	eax, eax
	jz	short 0f

	ret

0:
	call	getEIP
	add	eax, offset _GLOBAL_OFFSET_TABLE_
	mov	eax, [eax + \notFound@GOT]
	jmp	eax

.LtaggedPointer_\name:
	call	getEIP
	add	eax, offset _GLOBAL_OFFSET_TABLE_

	mov	ecx, [eax + objc_taggedPointerSecret@GOT]
	xor	edx, [ecx]
	and	dl, 0xE
	movzx	edx, dl

	mov	eax, [eax + objc_taggedPointerClasses@GOT]
	mov	edx, [eax + 2 * edx]
	mov	edx, [edx + 32]

	jmp	short .Lmain_\name
.type \name, %function
.size \name, .-\name
.endm

.macro GENERATE_LOOKUP_SUPER name lookup
\name:
	mov	edx, [esp + 4]
	mov	eax, [edx]
	test	eax, eax
	jz	short returnNilMethod

	mov	[esp + 4], eax
	mov	edx, [edx + 4]
	mov	edx, [edx + 32]
	jmp	short .Lmain_\lookup
.type \name, %function
.size \name, .-\name
.endm

GENERATE_LOOKUP objc_msg_lookup objc_methodNotFound
GENERATE_LOOKUP objc_msg_lookup_stret objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER objc_msg_lookup_super objc_msg_lookup
GENERATE_LOOKUP_SUPER objc_msg_lookup_super_stret objc_msg_lookup_stret

returnNilMethod:
	call	getEIP
	add	eax, offset _GLOBAL_OFFSET_TABLE_
	lea	eax, [eax + nilMethod@GOTOFF]
	ret

nilMethod:
	xor	eax, eax
	ret

getEIP:
	mov	eax, [esp]
	ret

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", %progbits
#endif
