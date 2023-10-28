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

.globl _objc_msg_lookup
.globl _objc_msg_lookup_stret
.globl _objc_msg_lookup_super
.globl _objc_msg_lookup_super_stret

.intel_syntax

/* Work around assembler bugs. */
.macro jmp
	.att_syntax
	/* Use uppercase instruction to avoid recursion. */
	JMP	$0
	.intel_syntax noprefix
.endmacro
.macro jz
	.att_syntax
	/* Use uppercase instruction to avoid recursion. */
	JZ	$0
	.intel_syntax noprefix
.endmacro

.section __TEXT, __text, regular, pure_instructions
.macro GENERATE_LOOKUP
$0:
	test	rdi, rdi
	jz	LreturnNilMethod

	test	dil, 1
	jnz	LtaggedPointer_$0

	mov	r8, [rdi]
	mov	r8, [r8 + 64]

Lmain_$0:
	mov	rax, [rsi]
	movzx	ecx, ah
	movzx	edx, al
#ifdef OF_SELUID24
	shr	eax, 16

	mov	r8, [r8 + 8 * rax]
#endif
	movq	r8, [r8 + 8 * rcx]
	movq	rax, [r8 + 8 * rdx]

	test	rax, rax
	jz	$1

	ret

LtaggedPointer_$0:
	mov	rax, [rip + _objc_taggedPointerSecret@GOTPCREL]
	xor	rdi, [rax]
	andb	dil, 0xE
	movzx	r8d, dil

	mov	rax, [rip + _objc_taggedPointerClasses@GOTPCREL]
	mov	r8, [rax + 4 * r8]
	mov	r8, [r8 + 64]

	jmp	Lmain_$0
.endmacro

.macro GENERATE_LOOKUP_SUPER
$0:
	mov	r8, rdi
	mov	rdi, [rdi]
	test	rdi, rdi
	jz	LreturnNilMethod

	movq	r8, [r8 + 8]
	movq	r8, [r8 + 64]
	jmp	Lmain_$1
.endmacro

GENERATE_LOOKUP _objc_msg_lookup, _objc_methodNotFound
GENERATE_LOOKUP _objc_msg_lookup_stret, _objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER _objc_msg_lookup_super, _objc_msg_lookup
GENERATE_LOOKUP_SUPER _objc_msg_lookup_super_stret, _objc_msg_lookup_stret

LreturnNilMethod:
	lea	rax, [rip + LnilMethod]
	ret

LnilMethod:
	xor	rax, rax
	ret
