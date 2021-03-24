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

.globl _objc_msg_lookup
.globl _objc_msg_lookup_stret
.globl _objc_msg_lookup_super
.globl _objc_msg_lookup_super_stret

.section .text
.macro generate_lookup name not_found
\name:
	movl	4(%esp), %edx
	testl	%edx, %edx
	jz	ret_nil

	testb	$1, %dl
	jnz	.Ltagged_pointer_\name

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
	jz	\not_found

	ret

.Ltagged_pointer_\name:
	xorl	_objc_tagged_pointer_secret, %edx
	andb	$0xE, %dl
	movzbl	%dl, %edx

	movl	_objc_tagged_pointer_classes(,%edx,2), %edx
	movl	32(%edx), %edx

	jmp	.Lmain_\name
.def \name
.scl 2
.type 32
.endef
.endm

.macro generate_lookup_super name lookup
\name:
	movl	4(%esp), %edx
	movl	(%edx), %eax
	test	%eax, %eax
	jz	ret_nil

	movl	%eax, 4(%esp)
	movl	4(%edx), %edx
	movl	32(%edx), %edx
	jmp	.Lmain_\lookup
.def \name
.scl 2
.type 32
.endef
.endm

generate_lookup _objc_msg_lookup _objc_method_not_found
generate_lookup _objc_msg_lookup_stret _objc_method_not_found_stret
generate_lookup_super _objc_msg_lookup_super _objc_msg_lookup
generate_lookup_super _objc_msg_lookup_super_stret _objc_msg_lookup_stret

ret_nil:
	movl	$nil_method, %eax
	ret

nil_method:
	xorl	%eax, %eax
	ret
