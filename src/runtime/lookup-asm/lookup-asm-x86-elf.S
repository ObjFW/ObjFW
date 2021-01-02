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

#include "platform.h"

.intel_syntax noprefix

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro generate_lookup name not_found
\name:
	mov	edx, [esp+4]
	test	edx, edx
	jz	short ret_nil

	bt	edx, 0
	jc	short .Ltagged_pointer_\name

	mov	edx, [edx]
	mov	edx, [edx+32]

.Lmain_\name:
	mov	eax, [esp+8]

#ifdef OF_SELUID24
	movzx	ecx, byte ptr [eax+2]
	mov	edx, [edx+ecx*4]
#endif
	movzx	ecx, byte ptr [eax+1]
	mov	edx, [edx+ecx*4]
	movzx	ecx, byte ptr [eax]
	mov	eax, [edx+ecx*4]

	test	eax, eax
	jz	short 0f

	ret

0:
	call	get_eip
	add	eax, offset _GLOBAL_OFFSET_TABLE_
	lea	eax, [eax+\not_found@GOTOFF]
	jmp	eax

.Ltagged_pointer_\name:
	call	get_eip
	add	eax, offset _GLOBAL_OFFSET_TABLE_

	lea	ecx, [eax+objc_tagged_pointer_secret@GOTOFF]
	xor	edx, [ecx]
	and	dl, 0xE
	movzx	edx, dl

	lea	eax, [eax+objc_tagged_pointer_classes@GOTOFF]
	mov	edx, [eax+edx*2]
	mov	edx, [edx+32]

	jmp	short .Lmain_\name
.type \name, %function
.size \name, .-\name
.endm

.macro generate_lookup_super name lookup
\name:
	mov	edx, [esp+4]
	mov	eax, [edx]
	test	eax, eax
	jz	short ret_nil

	mov	[esp+4], eax
	mov	edx, [edx+4]
	mov	edx, [edx+32]
	jmp	short .Lmain_\lookup
.type \name, %function
.size \name, .-\name
.endm

generate_lookup objc_msg_lookup objc_method_not_found
generate_lookup objc_msg_lookup_stret objc_method_not_found_stret
generate_lookup_super objc_msg_lookup_super objc_msg_lookup
generate_lookup_super objc_msg_lookup_super_stret objc_msg_lookup_stret

ret_nil:
	call	get_eip
	add	eax, offset _GLOBAL_OFFSET_TABLE_
	lea	eax, [eax+nil_method@GOTOFF]
	ret

nil_method:
	xor	eax, eax
	ret

get_eip:
	mov	eax, [esp]
	ret

#ifdef OF_LINUX
.section .note.GNU-stack, "", %progbits
#endif
