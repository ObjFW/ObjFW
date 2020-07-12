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

.globl _objc_msg_lookup
.globl _objc_msg_lookup_stret
.globl _objc_msg_lookup_super
.globl _objc_msg_lookup_super_stret

.section __TEXT, __text, regular, pure_instructions
.macro generate_lookup
$0:
	test	rdi, rdi
	jz	ret_nil

	bt	edi, 0
	jc	Ltagged_pointer_$0

	mov	r8, [rdi]
	mov	r8, [r8+64]

Lmain_$0:
	mov	rax, [rsi]
	movzx	ecx, ah
	movzx	edx, al
#ifdef OF_SELUID24
	shr	eax, 16

	mov	r8, [r8+rax*8]
#endif
	mov	r8, [r8+rcx*8]
	mov	rax, [r8+rdx*8]

	test	rax, rax
	jz	$1

	ret

Ltagged_pointer_$0:
	mov	rax, [rip+objc_tagged_pointer_secret@GOTPCREL]
	xor	rdi, [rax]
	and	dil, 0xE
	movzx	r8, dil

	mov	rax, [rip+_objc_tagged_pointer_classes]
	mov	r8, [rax+r8*4]
	mov	r8, [r8+64]

	jmp	Lmain_$0
.endmacro

.macro generate_lookup_super
$0:
	mov	r8, rdi
	mov	rdi, [rdi]
	test	rdi, rdi
	jz	ret_nil

	mov	r8, [r8+8]
	mov	r8, [r8+64]
	jmp	Lmain_$1
.endmacro

generate_lookup _objc_msg_lookup, _objc_method_not_found
generate_lookup _objc_msg_lookup_stret, _objc_method_not_found_stret
generate_lookup_super _objc_msg_lookup_super, _objc_msg_lookup
generate_lookup_super _objc_msg_lookup_super_stret, _objc_msg_lookup_stret

ret_nil:
	lea	rax, [rip+nil_method]
	ret

nil_method:
	mov	rax, rdi
	ret
