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

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro GENERATE_LOOKUP name notFound
\name:
	movl	4(%esp), %edx
	testl	%edx, %edx
	jz	returnNilMethod

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
	call	getEIP
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	movl	\notFound@GOT(%eax), %eax
	jmp	*%eax

.LtaggedPointer_\name:
	call	getEIP
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
	movl	4(%esp), %edx
	movl	(%edx), %eax
	testl	%eax, %eax
	jz	returnNilMethod

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

returnNilMethod:
	call	getEIP
	addl	$_GLOBAL_OFFSET_TABLE_, %eax
	leal	nilMethod@GOTOFF(%eax), %eax
	ret

nilMethod:
	xorl	%eax, %eax
	ret

getEIP:
	movl	(%esp), %eax
	ret

#if defined(OF_LINUX) || defined(OF_HURD)
.section .note.GNU-stack, "", %progbits
#endif
