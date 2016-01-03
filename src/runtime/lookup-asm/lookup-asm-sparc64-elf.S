/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
 *   Jonathan Schleifer <js@heap.zone>
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
.macro generate_lookup name not_found
\name:
	cmp	%o0, 0
	beq,pn	ret_nil
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

	cmp	%o2, 0
	beq,pn	\not_found
	 nop

	retl
	 mov	%o2, %o0
.type \name, %function
.size \name, .-\name
.endm

.macro generate_lookup_super name lookup
\name:
	ldx	[%o0], %o2
	cmp	%o2, 0
	beq,pn	ret_nil
	 nop

	ldx	[%o0 + 8], %o2
	ba	.Lmain_\lookup
	 ldx	[%o2 + 64], %o2
.type \name, %function
.size \name, .-\name
.endm

generate_lookup objc_msg_lookup objc_method_not_found
generate_lookup objc_msg_lookup_stret objc_method_not_found_stret
generate_lookup_super objc_msg_lookup_super objc_msg_lookup
generate_lookup_super objc_msg_lookup_super_stret objc_msg_lookup_stret

ret_nil:
#ifdef OF_PIC
	mov	%o7, %g1

	sethi	%hi(_GLOBAL_OFFSET_TABLE_ - 4), %o1
	call	0f
	 add	%o1, %lo(_GLOBAL_OFFSET_TABLE_ + 4), %o1
0:
	add	%o7, %o1, %o1

	sethi	%hi(nil_method), %o0
	or	%o0, %lo(nil_method), %o0

	jmpl	%g1 + 8, %g0
	 ldx	[%o1 + %o0], %o0
#else
	sethi	%hi(nil_method), %o0
	retl
	 or	%o0, %lo(nil_method), %o0
#endif

nil_method:
	retl
	 clr	%o0

#ifdef OF_LINUX
.section .note.GNU-stack, "", %progbits
#endif
