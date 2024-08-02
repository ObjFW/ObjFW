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

#ifdef HAVE_CET_H
# include <cet.h>
#else
# define _CET_ENDBR
#endif

.globl _objc_msg_lookup
.globl _objc_msg_lookup_stret
.globl _objc_msg_lookup_super
.globl _objc_msg_lookup_super_stret

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
	jz	\notFound

	ret

.LtaggedPointer_\name:
	xorl	_objc_taggedPointerSecret, %edx
	andb	$0xE, %dl
	movzbl	%dl, %edx

	movl	_objc_taggedPointerClasses(,%edx,2), %edx
	movl	32(%edx), %edx

	jmp	.Lmain_\name
.def \name
.scl 2
.type 32
.endef
.endm

.macro GENERATE_LOOKUP_SUPER name lookup
\name:
	_CET_ENDBR

	movl	4(%esp), %edx
	movl	(%edx), %eax
	testl	%eax, %eax
	jz	.LreturnNilMethod

	subl	$16, %esp
	movl	%eax, (%esp)
	movl	24(%esp), %eax
	movl	%eax, 4(%esp)

	movl	4(%edx), %edx
	movl	32(%edx), %edx
	call	.Lmain_\lookup

	addl	$16, %esp
	ret
.def \name
.scl 2
.type 32
.endef
.endm

GENERATE_LOOKUP _objc_msg_lookup _objc_methodNotFound
GENERATE_LOOKUP _objc_msg_lookup_stret _objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER _objc_msg_lookup_super _objc_msg_lookup
GENERATE_LOOKUP_SUPER _objc_msg_lookup_super_stret _objc_msg_lookup_stret

.LreturnNilMethod:
	movl	$.LnilMethod, %eax
	ret

.LnilMethod:
	_CET_ENDBR

	xorl	%eax, %eax
	ret
