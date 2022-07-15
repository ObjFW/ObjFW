/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
	brz,pn	%o0, returnNilMethod
	 and	%o0, 1, %o2
	brnz,pn	%o2, .LtaggedPointer_\name
	 nop

	ldx	[%o0], %o2
	ldx	[%o2 + 64], %o2

.Lmain_\name:
#ifdef OF_SELUID24
	ldub	[%o1 + 5], %o3
#endif
	ldub	[%o1 + 6], %o4
	ldub	[%o1 + 7], %o5

#ifdef OF_SELUID24
	sll	%o3, 3, %o3
#endif
	sll	%o4, 3, %o4
	sll	%o5, 3, %o5

#ifdef OF_SELUID24
	ldx	[%o2 + %o3], %o2
#endif
	ldx	[%o2 + %o4], %o2
	ldx	[%o2 + %o5], %o2

	brz,pn	%o2, 0f
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

	sethi	%hi(objc_taggedPointerSecret), %o2
	or	%o2, %lo(objc_taggedPointerSecret), %o2
#ifdef OF_PIC
	ldx	[%o3 + %o2], %o2
#endif
	ldx	[%o2], %o2
	xor	%o0, %o2, %o0
	and	%o0, 0xE, %o0
	sll	%o0, 2, %o0

	sethi	%hi(objc_taggedPointerClasses), %o2
	or	%o2, %lo(objc_taggedPointerClasses), %o2
#ifdef OF_PIC
	ldx	[%o3 + %o2], %o2
#endif

	ldx	[%o2 + %o0], %o2
	ba	.Lmain_\name
	 ldx	[%o2 + 64], %o2
.type \name, %function
.size \name, .-\name
.endm

.macro GENERATE_LOOKUP_SUPER name lookup
\name:
	mov	%o0, %o2
	ldx	[%o0], %o0
	brz,pn	%o0, returnNilMethod
	 nop

	ldx	[%o2 + 8], %o2
	ba	.Lmain_\lookup
	 ldx	[%o2 + 64], %o2
.type \name, %function
.size \name, .-\name
.endm

GENERATE_LOOKUP objc_msg_lookup objc_methodNotFound
GENERATE_LOOKUP objc_msg_lookup_stret objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER objc_msg_lookup_super objc_msg_lookup
GENERATE_LOOKUP_SUPER objc_msg_lookup_super_stret objc_msg_lookup_stret

returnNilMethod:
#ifdef OF_PIC
	mov	%o7, %g1

	sethi	%hi(_GLOBAL_OFFSET_TABLE_ - 4), %o1
	call	0f
	 or	%o1, %lo(_GLOBAL_OFFSET_TABLE_ + 4), %o1
0:
	add	%o7, %o1, %o1

	sethi	%hi(nilMethod), %o0
	or	%o0, %lo(nilMethod), %o0

	jmpl	%g1 + 8, %g0
	 ldx	[%o1 + %o0], %o0
#else
	sethi	%hi(nilMethod), %o0
	retl
	 or	%o0, %lo(nilMethod), %o0
#endif

nilMethod:
	retl
	 clr	%o0

#ifdef OF_LINUX
.section .note.GNU-stack, "", %progbits
#endif
