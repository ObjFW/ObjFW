/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro GENERATE_LOOKUP name notFound
\name:
	beqz	$a0, .LreturnNilMethod

	andi	$t0, $a0, 1
	bnez	$t0, .LtaggedPointer_\name

	ldptr.d	$t0, $a0, 0
	ldptr.d	$t0, $t0, 64

.Lmain_\name:
#ifdef OF_SELUID24
	ld.bu	$t1, $a1, 2
	slli.d	$t1, $t1, 3
#endif
	ld.bu	$t2, $a1, 1
	slli.d	$t2, $t2, 3
	ld.bu	$t3, $a1, 0
	slli.d	$t3, $t3, 3

#ifdef OF_SELUID24
	ldx.d	$t0, $t0, $t1
#endif
	ldx.d	$t0, $t0, $t2
	ldx.d	$t0, $t0, $t3

	beqz	$t0, 0f

	move	$a0, $t0
	ret

0:
	b	%plt(\notFound)

.LtaggedPointer_\name:
	la.global $t1, _objc_taggedPointerSecret
	ldptr.d	$t1, $t1, 0
	xor	$t1, $a0, $t1
	andi	$t1, $t1, 0xE
	slli.d	$t1, $t1, 2

	la.global $t0, _objc_taggedPointerClasses
	ldx.d	$t0, $t0, $t1
	ldptr.d	$t0, $t0, 64

	b	.Lmain_\name
.type \name, %function
.size \name, .-\name
.endm

.macro GENERATE_LOOKUP_SUPER name lookup
\name:
	move	$t0, $a0
	ldptr.d	$a0, $a0, 0
	beqz	$a0, .LreturnNilMethod

	ldptr.d	$t0, $t0, 8
	ldptr.d	$t0, $t0, 64

	b	.Lmain_\lookup
.type \name, %function
.size \name, .-\name
.endm

GENERATE_LOOKUP objc_msg_lookup _objc_methodNotFound
GENERATE_LOOKUP objc_msg_lookup_stret _objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER objc_msg_lookup_super objc_msg_lookup
GENERATE_LOOKUP_SUPER objc_msg_lookup_super_stret objc_msg_lookup_stret

.LreturnNilMethod:
	la.local $a0, .LnilMethod
	ret

.LnilMethod:
	li.d	$a0, 0
	ret

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", %progbits
#endif
