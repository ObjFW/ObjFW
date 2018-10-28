/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

.globl of_forward
.globl of_forward_stret

#define BIAS 2047

.section .text
of_forward:
	save	%sp, -304, %sp

	/*
	 * Save all floating point registers as they can be used for parameter
	 * passing.
	 */
	std	%f0, [%sp + BIAS + 176]
	std	%f2, [%sp + BIAS + 184]
	std	%f4, [%sp + BIAS + 192]
	std	%f6, [%sp + BIAS + 200]
	std	%f8, [%sp + BIAS + 208]
	std	%f10, [%sp + BIAS + 216]
	std	%f12, [%sp + BIAS + 224]
	std	%f14, [%sp + BIAS + 232]
	std	%f16, [%sp + BIAS + 240]
	std	%f18, [%sp + BIAS + 248]
	std	%f20, [%sp + BIAS + 256]
	std	%f22, [%sp + BIAS + 264]
	std	%f24, [%sp + BIAS + 272]
	std	%f26, [%sp + BIAS + 280]
	std	%f28, [%sp + BIAS + 288]
	std	%f30, [%sp + BIAS + 296]

	sethi	%hi(_GLOBAL_OFFSET_TABLE_ - 4), %l7
	call	add_pc
	 add	%l7, %lo(_GLOBAL_OFFSET_TABLE_ + 4), %l7

	mov	%i0, %o0
	call	object_getClass
	 nop

	sethi	%hi(sel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(sel_forwardingTargetForSelector_), %o1
	ldx	[%l7 + %o1], %o1
	call	class_respondsToSelector
	 nop

	cmp	%o0, 0
	be,pn	%xcc, 0f
	 nop

	mov	%i0, %o0
	sethi	%hi(sel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(sel_forwardingTargetForSelector_), %o1
	ldx	[%l7 + %o1], %o1
	call	objc_msg_lookup
	 nop
	mov	%o0, %l0

	mov	%i0, %o0
	sethi	%hi(sel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(sel_forwardingTargetForSelector_), %o1
	ldx	[%l7 + %o1], %o1
	jmpl	%l0, %o7
	 mov	%i1, %o2

	cmp	%o0, 0
	be,pn	%xcc, 0f
	 nop
	cmp	%o0, %i0
	be,pn	%xcc, 0f
	 nop

	mov	%o0, %i0
	call	objc_msg_lookup
	 mov	%i1, %o1

	/*
	 * Restore all floating point registers as they can be used for
	 * parameter passing.
	 */
	ldd	[%sp + BIAS + 176], %f0
	ldd	[%sp + BIAS + 184], %f2
	ldd	[%sp + BIAS + 192], %f4
	ldd	[%sp + BIAS + 200], %f6
	ldd	[%sp + BIAS + 208], %f8
	ldd	[%sp + BIAS + 216], %f10
	ldd	[%sp + BIAS + 224], %f12
	ldd	[%sp + BIAS + 232], %f14
	ldd	[%sp + BIAS + 240], %f16
	ldd	[%sp + BIAS + 248], %f18
	ldd	[%sp + BIAS + 256], %f20
	ldd	[%sp + BIAS + 264], %f22
	ldd	[%sp + BIAS + 272], %f24
	ldd	[%sp + BIAS + 280], %f26
	ldd	[%sp + BIAS + 288], %f28
	ldd	[%sp + BIAS + 296], %f30

	jmpl	%o0, %g0
	 restore

0:
	call	of_method_not_found
	 restore
.type of_forward, %function
.size of_forward, .-of_forward

of_forward_stret:
	save	%sp, -304, %sp

	/*
	 * Save all floating point registers as they can be used for parameter
	 * passing.
	 */
	std	%f0, [%sp + BIAS + 176]
	std	%f2, [%sp + BIAS + 184]
	std	%f4, [%sp + BIAS + 192]
	std	%f6, [%sp + BIAS + 200]
	std	%f8, [%sp + BIAS + 208]
	std	%f10, [%sp + BIAS + 216]
	std	%f12, [%sp + BIAS + 224]
	std	%f14, [%sp + BIAS + 232]
	std	%f16, [%sp + BIAS + 240]
	std	%f18, [%sp + BIAS + 248]
	std	%f20, [%sp + BIAS + 256]
	std	%f22, [%sp + BIAS + 264]
	std	%f24, [%sp + BIAS + 272]
	std	%f26, [%sp + BIAS + 280]
	std	%f28, [%sp + BIAS + 288]
	std	%f30, [%sp + BIAS + 296]

	sethi	%hi(_GLOBAL_OFFSET_TABLE_ - 4), %l7
	call	add_pc
	 add	%l7, %lo(_GLOBAL_OFFSET_TABLE_ + 4), %l7

	mov	%i1, %o0
	call	object_getClass
	 nop

	sethi	%hi(sel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(sel_forwardingTargetForSelector_), %o1
	ldx	[%l7 + %o1], %o1
	call	class_respondsToSelector
	 nop

	cmp	%o0, 0
	be,pn	%xcc, 0f
	 nop

	mov	%i1, %o0
	sethi	%hi(sel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(sel_forwardingTargetForSelector_), %o1
	ldx	[%l7 + %o1], %o1
	call	objc_msg_lookup
	 nop
	mov	%o0, %l0

	mov	%i1, %o0
	sethi	%hi(sel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(sel_forwardingTargetForSelector_), %o1
	ldx	[%l7 + %o1], %o1
	jmpl	%l0, %o7
	 mov	%i2, %o2

	cmp	%o0, 0
	be,pn	%xcc, 0f
	 nop
	cmp	%o0, %i1
	be,pn	%xcc, 0f
	 nop

	mov	%o0, %i1
	call	objc_msg_lookup
	 mov	%i2, %o1

	/*
	 * Restore all floating point registers as they can be used for
	 * parameter passing.
	 */
	ldd	[%sp + BIAS + 176], %f0
	ldd	[%sp + BIAS + 184], %f2
	ldd	[%sp + BIAS + 192], %f4
	ldd	[%sp + BIAS + 200], %f6
	ldd	[%sp + BIAS + 208], %f8
	ldd	[%sp + BIAS + 216], %f10
	ldd	[%sp + BIAS + 224], %f12
	ldd	[%sp + BIAS + 232], %f14
	ldd	[%sp + BIAS + 240], %f16
	ldd	[%sp + BIAS + 248], %f18
	ldd	[%sp + BIAS + 256], %f20
	ldd	[%sp + BIAS + 264], %f22
	ldd	[%sp + BIAS + 272], %f24
	ldd	[%sp + BIAS + 280], %f26
	ldd	[%sp + BIAS + 288], %f28
	ldd	[%sp + BIAS + 296], %f30

	jmpl	%o0, %g0
	 restore

0:
	call	of_method_not_found_stret
	 restore
.type of_forward_stret, %function
.size of_forward_stret, .-of_forward_stret

init:
	save	%sp, -176, %sp

	sethi	%hi(_GLOBAL_OFFSET_TABLE_ - 4), %l7
	call	add_pc
	 add	%l7, %lo(_GLOBAL_OFFSET_TABLE_ + 4), %l7

	sethi	%hi(module), %i0
	or	%i0, %lo(module), %i0
	ldx	[%l7 + %i0], %i0

	call	__objc_exec_class
	 restore

add_pc:
	jmp	%o7 + 8
	 add	%l7, %o7, %l7

#ifdef OF_SOLARIS
.section .init_array, "aw"
#else
.section .ctors, "aw", %progbits
#endif
	.xword init

.section .rodata
str_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section .data
sel_forwardingTargetForSelector_:
	.xword str_forwardingTargetForSelector_, 0
	.xword 0, 0
symtab:
	.xword 0, sel_forwardingTargetForSelector_
	.half 0, 0
	.word 0
	.xword 0
module:
	.xword 8, 32, 0, symtab

#ifdef OF_LINUX
.section .note.GNU-stack, "", %progbits
#endif
