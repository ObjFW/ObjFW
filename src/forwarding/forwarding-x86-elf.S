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

.globl of_forward
.globl of_forward_stret

.section .text
of_forward:
	push	ebp
	mov	ebp, esp

	push	ebx
	sub	esp, 20

	call	get_eip
0:
	add	ebx, offset _GLOBAL_OFFSET_TABLE_

	mov	eax, [ebp+8]
	mov	[esp], eax
	mov	eax, [ebx+object_getClass@GOT]
	call	eax

	mov	[esp], eax
	lea	eax, [ebx+sel_forwardingTargetForSelector_@GOTOFF]
	mov	[esp+4], eax
	mov	eax, [ebx+class_respondsToSelector@GOT]
	call	eax

	test	eax, eax
	jz	short 1f

	mov	eax, [ebp+8]
	mov	[esp], eax
	lea	eax, [ebx+sel_forwardingTargetForSelector_@GOTOFF]
	mov	[esp+4], eax
	mov	eax, [ebx+objc_msg_lookup@GOT]
	call	eax

	mov	edx, [ebp+8]
	mov	[esp], edx
	lea	edx, [ebx+sel_forwardingTargetForSelector_@GOTOFF]
	mov	[esp+4], edx
	mov	edx, [ebp+12]
	mov	[esp+8], edx
	call	eax

	test	eax, eax
	jz	short 1f
	cmp	eax, [ebp+8]
	je	short 1f

	mov	[ebp+8], eax
	mov	[esp], eax
	mov	eax, [ebp+12]
	mov	[esp+4], eax
	mov	eax, [ebx+objc_msg_lookup@GOT]
	call	eax

	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	eax

1:
	mov	eax, [ebx+of_method_not_found@GOT]

	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	eax
.type of_forward, %function
.size of_forward, .-of_forward

of_forward_stret:
	push	ebp
	mov	ebp, esp

	push	ebx
	sub	esp, 20

	call	get_eip
0:
	add	ebx, offset _GLOBAL_OFFSET_TABLE_

	mov	eax, [ebp+12]
	mov	[esp], eax
	mov	eax, [ebx+object_getClass@GOT]
	call	eax

	mov	[esp], eax
	lea	eax, [ebx+sel_forwardingTargetForSelector_@GOTOFF]
	mov	[esp+4], eax
	mov	eax, [ebx+class_respondsToSelector@GOT]
	call	eax

	test	eax, eax
	jz	short 1f

	mov	eax, [ebp+12]
	mov	[esp], eax
	lea	eax, [ebx+sel_forwardingTargetForSelector_@GOTOFF]
	mov	[esp+4], eax
	mov	eax, [ebx+objc_msg_lookup@GOT]
	call	eax

	mov	edx, [ebp+12]
	mov	[esp], edx
	lea	edx, [ebx+sel_forwardingTargetForSelector_@GOTOFF]
	mov	[esp+4], edx
	mov	edx, [ebp+16]
	mov	[esp+8], edx
	call	eax

	test	eax, eax
	jz	short 1f
	cmp	eax, [ebp+12]
	je	short 1f

	mov	[ebp+12], eax
	mov	[esp], eax
	mov	eax, [ebp+16]
	mov	[esp+4], eax
	mov	eax, [ebx+objc_msg_lookup_stret@GOT]
	call	eax

	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	eax

1:
	mov	eax, [ebx+of_method_not_found_stret@GOT]

	add	esp, 20
	pop	ebx
	pop	ebp

	jmp	eax
.type of_forward_stret, %function
.size of_forward_stret, .-of_forward_stret

init:
	push	ebp
	mov	ebp, esp

	push	ebx
	sub	esp, 4

	call	get_eip
0:
	add	ebx, offset _GLOBAL_OFFSET_TABLE_

	lea	eax, [ebx+module@GOTOFF]
	mov	[esp], eax
	mov	eax, [ebx+__objc_exec_class@GOT]
	call	eax

	add	esp, 4
	pop	ebx
	pop	ebp
	ret

get_eip:
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

#ifdef OF_LINUX
.section .note.GNU-stack, "", %progbits
#endif
