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

.globl _OFForward
.globl _OFForward_stret
.internal _OFForward
.internal _OFForward_stret

#define BIAS 2047

.section .text
_OFForward:
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
	call	.LaddPC
	 add	%l7, %lo(_GLOBAL_OFFSET_TABLE_ + 4), %l7

	mov	%i0, %o0
	call	object_getClass
	 nop

	sethi	%hi(.Lsel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(.Lsel_forwardingTargetForSelector_), %o1
	ldx	[%l7 + %o1], %o1
	call	class_respondsToSelector
	 nop

	brz,pn	%o0, 0f

	 mov	%i0, %o0
	sethi	%hi(.Lsel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(.Lsel_forwardingTargetForSelector_), %o1
	ldx	[%l7 + %o1], %o1
	call	objc_msg_lookup
	 nop
	mov	%o0, %l0

	mov	%i0, %o0
	sethi	%hi(.Lsel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(.Lsel_forwardingTargetForSelector_), %o1
	ldx	[%l7 + %o1], %o1
	jmpl	%l0, %o7
	 mov	%i1, %o2

	brz,pn	%o0, 0f
	 cmp	%o0, %i0
	be,pn	%xcc, 0f

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
	call	OFMethodNotFound
	 restore
.type _OFForward, %function
.size _OFForward, .-_OFForward

_OFForward_stret:
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
	call	.LaddPC
	 add	%l7, %lo(_GLOBAL_OFFSET_TABLE_ + 4), %l7

	mov	%i1, %o0
	call	object_getClass
	 nop

	sethi	%hi(.Lsel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(.Lsel_forwardingTargetForSelector_), %o1
	ldx	[%l7 + %o1], %o1
	call	class_respondsToSelector
	 nop

	brz,pn	%o0, 0f

	 mov	%i1, %o0
	sethi	%hi(.Lsel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(.Lsel_forwardingTargetForSelector_), %o1
	ldx	[%l7 + %o1], %o1
	call	objc_msg_lookup
	 nop
	mov	%o0, %l0

	mov	%i1, %o0
	sethi	%hi(.Lsel_forwardingTargetForSelector_), %o1
	or	%o1, %lo(.Lsel_forwardingTargetForSelector_), %o1
	ldx	[%l7 + %o1], %o1
	jmpl	%l0, %o7
	 mov	%i2, %o2

	brz,pn	%o0, 0f
	 cmp	%o0, %i1
	be,pn	%xcc, 0f

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
	call	OFMethodNotFound_stret
	 restore
.type _OFForward_stret, %function
.size _OFForward_stret, .-_OFForward_stret

.Linit:
	save	%sp, -176, %sp

	sethi	%hi(_GLOBAL_OFFSET_TABLE_ - 4), %l7
	call	.LaddPC
	 add	%l7, %lo(_GLOBAL_OFFSET_TABLE_ + 4), %l7

	sethi	%hi(.Lmodule), %i0
	or	%i0, %lo(.Lmodule), %i0
	ldx	[%l7 + %i0], %i0

	call	__objc_exec_class
	 restore

.LaddPC:
	jmp	%o7 + 8
	 add	%l7, %o7, %l7

#ifdef OF_SOLARIS
.section .init_array, "aw"
#else
.section .ctors, "aw", %progbits
#endif
	.xword .Linit

.section .rodata
.Lstr_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section .data
.Lsel_forwardingTargetForSelector_:
	.xword .Lstr_forwardingTargetForSelector_, 0
	.xword 0, 0
.Lsymtab:
	.xword 0, .Lsel_forwardingTargetForSelector_
	.half 0, 0
	.word 0
	.xword 0
.Lmodule:
	.xword 8, 32, 0, .Lsymtab

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", %progbits
#endif
