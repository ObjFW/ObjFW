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

.globl OFForward
.globl OFForward_stret

.section .text
OFForward:
OFForward_stret:
#ifdef HAVE_BTI
	bti	c
#endif

	stp	fp, lr, [sp, #-224]!
	mov	fp, sp

	/* Save all arguments, x8 and x19 */
	stp	x0, x1, [sp, #16]
	stp	x2, x3, [sp, #32]
	stp	x4, x5, [sp, #48]
	stp	x6, x7, [sp, #64]
	stp	x8, x19, [sp, #80]

	/* Save all foating point arguments */
	stp	q0, q1, [sp, #96]
	stp	q2, q3, [sp, #128]
	stp	q4, q5, [sp, #160]
	stp	q6, q7, [sp, #192]

	bl	object_getClass

	adrp	x19, .Lsel_forwardingTargetForSelector_
	add	x19, x19, :lo12:.Lsel_forwardingTargetForSelector_

	mov	x1, x19
	bl	class_respondsToSelector

	cbz	x0, 0f

	ldr	x0, [sp, #16]
	mov	x1, x19
	bl	objc_msg_lookup

	mov	x1, x19
	mov	x19, x0
	ldp	x0, x2, [sp, #16]
	blr	x19

	cbz	x0, 0f
	ldr	x1, [sp, #16]
	cmp	x0, x1
	b.eq	0f

	mov	x19, x0
	ldr	x1, [sp, #24]
	bl	objc_msg_lookup

	mov	x16, x0
	mov	x0, x19

	/* Restore all arguments, x8 and x19, but not x0 */
	ldr	x1, [sp, #24]
	ldp	x2, x3, [sp, #32]
	ldp	x4, x5, [sp, #48]
	ldp	x6, x7, [sp, #64]
	ldp	x8, x19, [sp, #80]

	/* Restore all foating point arguments */
	ldp	q0, q1, [sp, #96]
	ldp	q2, q3, [sp, #128]
	ldp	q4, q5, [sp, #160]
	ldp	q6, q7, [sp, #192]

	ldp	fp, lr, [sp], #224
	br	x16

0:
	ldp	x0, x1, [sp, #16]
	ldr	x19, [sp, #88]

	ldp	fp, lr, [sp], #224
	b	OFMethodNotFound
.def OFForward
.scl 2
.type 32
.endef
.def OFForward_stret
.scl 2
.type 32
.endef

.Linit:
#ifdef HAVE_BTI
	bti	c
#endif

	adrp	x0, .Lmodule
	add	x0, x0, :lo12:.Lmodule
	b	__objc_exec_class

.section .ctors, "aw"
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
	.short 0, 0
	.long 0
	.xword 0
.Lmodule:
	.long 8, 32
	.xword 0, .Lsymtab
