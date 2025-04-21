/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#ifdef HAVE_CET_H
# include <cet.h>
#else
# define _CET_ENDBR
#endif

.globl _objc_msg_lookup
.globl _objc_msg_lookup_stret
.globl _objc_msg_lookup_super
.globl _objc_msg_lookup_super_stret

.section __TEXT, __text, regular, pure_instructions
.macro GENERATE_LOOKUP
$0:
	_CET_ENDBR

	testq	%rdi, %rdi
	jz	LreturnNilMethod

	testb	$$1, %dil
	jnz	LtaggedPointer_$0

	movq	(%rdi), %r8
	movq	64(%r8), %r8

Lmain_$0:
	movq	(%rsi), %rax
	movzbl	%ah, %ecx
	movzbl	%al, %edx
#ifdef OF_SELUID24
	shrl	$$16, %eax

	movq	(%r8,%rax,8), %r8
#endif
	movq	(%r8,%rcx,8), %r8
	movq	(%r8,%rdx,8), %rax

	testq	%rax, %rax
	jz	$1

	ret

LtaggedPointer_$0:
	movq	_objc_taggedPointerSecret@GOTPCREL(%rip), %rax
	xorq	(%rax), %rdi
	andb	$$0xE, %dil
	movzbl	%dil, %r8d

	movq	_objc_taggedPointerClasses@GOTPCREL(%rip), %rax
	movq	(%rax,%r8,4), %r8
	movq	64(%r8), %r8

	jmp	Lmain_$0
.endmacro

.macro GENERATE_LOOKUP_SUPER
$0:
	_CET_ENDBR

	movq	%rdi, %r8
	movq	(%rdi), %rdi
	testq	%rdi, %rdi
	jz	LreturnNilMethod

	movq	8(%r8), %r8
	movq	64(%r8), %r8
	jmp	Lmain_$1
.endmacro

GENERATE_LOOKUP _objc_msg_lookup, _objc_methodNotFound
GENERATE_LOOKUP _objc_msg_lookup_stret, _objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER _objc_msg_lookup_super, _objc_msg_lookup
GENERATE_LOOKUP_SUPER _objc_msg_lookup_super_stret, _objc_msg_lookup_stret

LreturnNilMethod:
	leaq	LnilMethod(%rip), %rax
	ret

LnilMethod:
	_CET_ENDBR

	xorq	%rax, %rax
	ret
