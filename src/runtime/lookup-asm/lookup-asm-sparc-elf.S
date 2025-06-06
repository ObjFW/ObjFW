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

#include "platform.h"

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro GENERATE_LOOKUP name notFound
\name:
	tst	%o0
	bz	.LreturnNilMethod
	 btst	1, %o0
	bnz	.LtaggedPointer_\name
	 nop

	ld	[%o0], %o2
	ld	[%o2 + 32], %o2

.Lmain_\name:
#ifdef OF_SELUID24
	ldub	[%o1 + 1], %o3
#endif
	ldub	[%o1 + 2], %o4
	ldub	[%o1 + 3], %o5

#ifdef OF_SELUID24
	sll	%o3, 2, %o3
#endif
	sll	%o4, 2, %o4
	sll	%o5, 2, %o5

#ifdef OF_SELUID24
	ld	[%o2 + %o3], %o2
#endif
	ld	[%o2 + %o4], %o2
	ld	[%o2 + %o5], %o2

	cmp	%o2, 0
	be	0f
	 nop

	retl
	 mov	%o2, %o0

0:
	mov	%o7, %g1
	call	\notFound
	 mov	%g1, %o7

.LtaggedPointer_\name:
#ifdef OF_PIC
	mov	%o7, %g1
	sethi	%hi(_GLOBAL_OFFSET_TABLE_ - 4), %o3
	call	0f
	 or	%o3, %lo(_GLOBAL_OFFSET_TABLE_ + 4), %o3
0:
	add	%o7, %o3, %o3
	mov	%g1, %o7
#endif

	sethi	%hi(_objc_taggedPointerSecret), %o2
	or	%o2, %lo(_objc_taggedPointerSecret), %o2
#ifdef OF_PIC
	ld	[%o3 + %o2], %o2
#endif
	ld	[%o2], %o2
	xor	%o0, %o2, %o0
	and	%o0, 0xE, %o0
	sll	%o0, 1, %o0

	sethi	%hi(_objc_taggedPointerClasses), %o2
	or	%o2, %lo(_objc_taggedPointerClasses), %o2
#ifdef OF_PIC
	ld	[%o3 + %o2], %o2
#endif

	ld	[%o2 + %o0], %o2
	ba	.Lmain_\name
	 ld	[%o2 + 32], %o2
.type \name, %function
.size \name, .-\name
.endm

.macro GENERATE_LOOKUP_SUPER name lookup
\name:
	mov	%o0, %o2
	ld	[%o0], %o0
	cmp	%o0, 0
	be	.LreturnNilMethod
	 nop

	ld	[%o2 + 4], %o2
	ba	.Lmain_\lookup
	 ld	[%o2 + 32], %o2
.type \name, %function
.size \name, .-\name
.endm

GENERATE_LOOKUP objc_msg_lookup _objc_methodNotFound
GENERATE_LOOKUP objc_msg_lookup_stret _objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER objc_msg_lookup_super objc_msg_lookup
GENERATE_LOOKUP_SUPER objc_msg_lookup_super_stret objc_msg_lookup_stret

.LreturnNilMethod:
#ifdef OF_PIC
	mov	%o7, %g1

	sethi	%hi(_GLOBAL_OFFSET_TABLE_ - 4), %o1
	call	0f
	 add	%o1, %lo(_GLOBAL_OFFSET_TABLE_ + 4), %o1
0:
	add	%o7, %o1, %o1

	sethi	%hi(.LnilMethod), %o0
	or	%o0, %lo(.LnilMethod), %o0

	jmpl	%g1 + 8, %g0
	 ld	[%o1 + %o0], %o0
#else
	sethi	%hi(.LnilMethod), %o0
	retl
	 or	%o0, %lo(.LnilMethod), %o0
#endif

.LnilMethod:
	retl
	 clr	%o0

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", %progbits
#endif
