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

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro GENERATE_LOOKUP name notFound
\name:
	beqz	a0, .LreturnNilMethod

	andi	t0, a0, 1
	bnez	t0, .LtaggedPointer_\name

	ld	t0, (a0)
	ld	t0, 64(t0)

.Lmain_\name:
#ifdef OF_SELUID24
	lbu	t1, 2(a1)
	slli	t1, t1, 3
#endif
	lbu	t2, 1(a1)
	slli	t2, t2, 3
	lbu	t3, (a1)
	slli	t3, t3, 3

#ifdef OF_SELUID24
	add	t0, t0, t1
	ld	t0, (t0)
#endif
	add	t0, t0, t2
	ld	t0, (t0)
	add	t0, t0, t3
	ld	t0, (t0)

	beqz	t0, 0f

	mv	a0, t0
	ret

0:
	tail	\notFound@plt

.LtaggedPointer_\name:
	la	t1, objc_taggedPointerSecret
	ld	t1, (t1)
	xor	t1, a0, t1
	andi	t1, t1, 0xE
	slli	t1, t1, 2

	la	t0, objc_taggedPointerClasses
	add	t0, t0, t1
	ld	t0, (t0)
	ld	t0, 64(t0)

	j	.Lmain_\name
.type \name, @function
.size \name, .-\name
.endm

.macro GENERATE_LOOKUP_SUPER name lookup
\name:
	mv	t0, a0
	ld	a0, (a0)
	beqz	a0, .LreturnNilMethod

	ld	t0, 8(t0)
	ld	t0, 64(t0)

	j	.Lmain_\lookup
.type \name, @function
.size \name, .-\name
.endm

GENERATE_LOOKUP objc_msg_lookup objc_methodNotFound
GENERATE_LOOKUP objc_msg_lookup_stret objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER objc_msg_lookup_super objc_msg_lookup
GENERATE_LOOKUP_SUPER objc_msg_lookup_super_stret objc_msg_lookup_stret

.LreturnNilMethod:
	lla	a0, .LnilMethod
	ret

.LnilMethod:
	li	a0, 0
	ret

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", @progbits
#endif
