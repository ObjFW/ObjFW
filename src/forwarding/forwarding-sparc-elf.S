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

.globl OFForward
.globl OFForward_stret

.section .text
OFForward:
	save	%sp, -96, %sp

#ifdef OF_PIC
	sethi	%hi(_GLOBAL_OFFSET_TABLE_ - 4), %l7
	call	add_pc
	 add	%l7, %lo(_GLOBAL_OFFSET_TABLE_ + 4), %l7
#endif

	mov	%i0, %o0
	call	object_getClass
	 nop

	sethi	%hi(sel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(sel_forwardingTargetForSelector_), %o1
#ifdef OF_PIC
	ld	[%l7 + %o1], %o1
#endif
	call	class_respondsToSelector
	 nop

	cmp	%o0, 0
	be	0f

	 mov	%i0, %o0
	sethi	%hi(sel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(sel_forwardingTargetForSelector_), %o1
#ifdef OF_PIC
	ld	[%l7 + %o1], %o1
#endif
	call	objc_msg_lookup
	 nop
	mov	%o0, %l0

	mov	%i0, %o0
	sethi	%hi(sel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(sel_forwardingTargetForSelector_), %o1
#ifdef OF_PIC
	ld	[%l7 + %o1], %o1
#endif
	jmpl	%l0, %o7
	 mov	%i1, %o2

	cmp	%o0, 0
	be	0f
	 cmp	%o0, %i0
	be	0f

	 mov	%o0, %i0
	call	objc_msg_lookup
	 mov	%i1, %o1

	jmpl	%o0, %g0
	 restore

0:
	call	OFMethodNotFound
	 restore
.type OFForward, %function
.size OFForward, .-OFForward

OFForward_stret:
	save	%sp, -96, %sp

#ifdef OF_PIC
	sethi	%hi(_GLOBAL_OFFSET_TABLE_ - 4), %l7
	call	add_pc
	 add	%l7, %lo(_GLOBAL_OFFSET_TABLE_ + 4), %l7
#endif

	mov	%i1, %o0
	call	object_getClass
	 nop

	sethi	%hi(sel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(sel_forwardingTargetForSelector_), %o1
#ifdef OF_PIC
	ld	[%l7 + %o1], %o1
#endif
	call	class_respondsToSelector
	 nop

	cmp	%o0, 0
	be	0f

	 mov	%i1, %o0
	sethi	%hi(sel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(sel_forwardingTargetForSelector_), %o1
#ifdef OF_PIC
	ld	[%l7 + %o1], %o1
#endif
	call	objc_msg_lookup
	 nop
	mov	%o0, %l0

	mov	%i1, %o0
	sethi	%hi(sel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(sel_forwardingTargetForSelector_), %o1
#ifdef OF_PIC
	ld	[%l7 + %o1], %o1
#endif
	jmpl	%l0, %o7
	 mov	%i2, %o2

	cmp	%o0, 0
	be	0f
	 cmp	%o0, %i1
	be	0f

	 mov	%o0, %i1
	call	objc_msg_lookup
	 mov	%i2, %o1

	jmpl	%o0, %g0
	 restore

0:
	call	OFMethodNotFound_stret
	 restore
.type OFForward_stret, %function
.size OFForward_stret, .-OFForward_stret

init:
	save	%sp, -96, %sp

#ifdef OF_PIC
	sethi	%hi(_GLOBAL_OFFSET_TABLE_ - 4), %l7
	call	add_pc
	 add	%l7, %lo(_GLOBAL_OFFSET_TABLE_ + 4), %l7
#endif

	sethi	%hi(module), %i0
	or	%i0, %lo(module), %i0
#ifdef OF_PIC
	ld	[%l7 + %i0], %i0
#endif

	call	__objc_exec_class
	 restore

#ifdef OF_PIC
add_pc:
	jmp	%o7 + 8
	 add	%l7, %o7, %l7
#endif

#ifdef OF_SOLARIS
.section .init_array, "aw"
#else
.section .ctors, "aw", %progbits
#endif
	.word init

.section .rodata
str_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section .data
sel_forwardingTargetForSelector_:
	.word str_forwardingTargetForSelector_, 0
	.word 0, 0
symtab:
	.word 0, sel_forwardingTargetForSelector_
	.half 0, 0
	.word 0
	.word 0
module:
	.word 8, 16, 0, symtab

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", %progbits
#endif
