/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#include "platform.h"

#ifdef HAVE_CET_H
# include <cet.h>
#else
# define _CET_ENDBR
#endif

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro GENERATE_LOOKUP name notFound
\name:
	_CET_ENDBR

	movl	4(%esp), %edx
	testl	%edx, %edx
	jz	.LreturnNilMethod

	testb	$1, %dl
	jnz	.LtaggedPointer_\name

	movl	(%edx), %edx
	movl	32(%edx), %edx

.Lmain_\name:
	movl	8(%esp), %eax

#ifdef OF_SELUID24
	movzbl	2(%eax), %ecx
	movl	(%edx,%ecx,4), %edx
#endif
	movzbl	1(%eax), %ecx
	movl	(%edx,%ecx,4), %edx
	movzbl	(%eax), %ecx
	movl	(%edx,%ecx,4), %eax

	testl	%eax, %eax
	jz	0f

	ret

0:
	call	.LgetEIP
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	\notFound@GOT(%eax), %eax
	jmp	*%eax

.LtaggedPointer_\name:
	call	.LgetEIP
	addl	$_GLOBAL_OFFSET_TABLE_, %eax

	movl	objc_taggedPointerSecret@GOT(%eax), %ecx
	xorl	(%ecx), %edx
	andb	$0xE, %dl
	movzbl	%dl, %edx

	movl	objc_taggedPointerClasses@GOT(%eax), %eax
	movl	(%eax,%edx,2), %edx
	movl	32(%edx), %edx

	jmp	.Lmain_\name
.type \name, %function
.size \name, .-\name
.endm

.macro GENERATE_LOOKUP_SUPER name lookup
\name:
	_CET_ENDBR

	movl	4(%esp), %edx
	movl	(%edx), %eax
	testl	%eax, %eax
	jz	.LreturnNilMethod

	movl	%eax, 4(%esp)
	mov	4(%edx), %edx
	mov	32(%edx), %edx
	jmp	.Lmain_\lookup
.type \name, %function
.size \name, .-\name
.endm

GENERATE_LOOKUP objc_msg_lookup objc_methodNotFound
GENERATE_LOOKUP objc_msg_lookup_stret objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER objc_msg_lookup_super objc_msg_lookup
GENERATE_LOOKUP_SUPER objc_msg_lookup_super_stret objc_msg_lookup_stret

.LreturnNilMethod:
	call	.LgetEIP
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	leal	.LnilMethod@GOTOFF(%eax), %eax
	ret

.LnilMethod:
	_CET_ENDBR

	xorl	%eax, %eax
	ret

.LgetEIP:
	movl	(%esp), %eax
	ret

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", %progbits
#endif
