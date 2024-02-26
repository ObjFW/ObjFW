/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
	test	%eax, %eax
	jz	returnNilMethod

	movl	%eax, 4(%esp)
	movl	4(%edx), %edx
	movl	32(%edx), %edx
	jmp	.Lmain_\lookup
.def \name
.scl 2
.type 32
.endef
.endm

GENERATE_LOOKUP _objc_msg_lookup _objc_methodNotFound
GENERATE_LOOKUP _objc_msg_lookup_stret _objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER _objc_msg_lookup_super _objc_msg_lookup
GENERATE_LOOKUP_SUPER _objc_msg_lookup_super_stret _objc_msg_lookup_stret

returnNilMethod:
	movl	$nilMethod, %eax
	ret

nilMethod:
	xorl	%eax, %eax
	ret
