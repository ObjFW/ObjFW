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

.globl __OFForward
.globl __OFForward_stret
.private_extern __OFForward
.private_extern __OFForward_stret

.section __TEXT, __cstring, cstring_literals
Lstr_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section __OBJC, __message_refs
Lsel_forwardingTargetForSelector_:
	.long Lstr_forwardingTargetForSelector_

.section __OBJC, __image_info
	.long 0, 0

.section __TEXT, __text, regular, pure_instructions
__OFForward:
	mflr	r0
	stw	r0, 8(r1)
	stwu	r1, -192(r1)

	/*
	 * Save all arguments and r13.
	 *
	 * We can dump two parameters in the parameter area as we know that
	 * space has been reserved for at least two parameters.
	 */
	stw	r3, 216(r1)
	stw	r4, 220(r1)
	stw	r5, 56(r1)
	stw	r6, 60(r1)
	stw	r7, 64(r1)
	stw	r8, 68(r1)
	stw	r9, 72(r1)
	stw	r10, 76(r1)
	stw	r13, 80(r1)

	/* Save all floating point arguments */
	stfd	f1, 88(r1)
	stfd	f2, 96(r1)
	stfd	f3, 104(r1)
	stfd	f4, 112(r1)
	stfd	f5, 120(r1)
	stfd	f6, 128(r1)
	stfd	f7, 136(r1)
	stfd	f8, 144(r1)
	stfd	f9, 152(r1)
	stfd	f10, 160(r1)
	stfd	f11, 168(r1)
	stfd	f12, 176(r1)
	stfd	f13, 184(r1)

	bl	_object_getClass

	bl	0f
0:
	mflr	r13
	addis	r13, r13, ha16(Lsel_forwardingTargetForSelector_-0b)
	lwz	r13, lo16(Lsel_forwardingTargetForSelector_-0b)(r13)

	mr	r4, r13
	bl	_class_respondsToSelector

	cmpwi	r3, 0
	beq-	0f

	lwz	r3, 216(r1)
	mr	r4, r13
	lwz	r5, 220(r1)
	bl	_objc_msgSend

	cmpwi	r3, 0
	beq-	0f
	lwz	r4, 216(r1)
	cmpw	r3, r4
	beq-	0f

	/* Restore all arguments and r13, except r3 */
	lwz	r4, 220(r1)
	lwz	r5, 56(r1)
	lwz	r6, 60(r1)
	lwz	r7, 64(r1)
	lwz	r8, 68(r1)
	lwz	r9, 72(r1)
	lwz	r10, 76(r1)
	lwz	r13, 80(r1)

	/* Restore all floating point arguments */
	lfd	f1, 88(r1)
	lfd	f2, 96(r1)
	lfd	f3, 104(r1)
	lfd	f4, 112(r1)
	lfd	f5, 120(r1)
	lfd	f6, 128(r1)
	lfd	f7, 136(r1)
	lfd	f8, 144(r1)
	lfd	f9, 152(r1)
	lfd	f10, 160(r1)
	lfd	f11, 168(r1)
	lfd	f12, 176(r1)
	lfd	f13, 184(r1)

	addi	r1, r1, 192
	lwz	r0, 8(r1)
	mtlr	r0

	b	_objc_msgSend

0:
	lwz	r3, 216(r1)
	lwz	r4, 220(r1)

	addi	r1, r1, 192
	lwz	r0, 8(r1)
	mtlr	r0

	b	_OFMethodNotFound

__OFForward_stret:
	mflr	r0
	stw	r0, 8(r1)
	stwu	r1, -184(r1)

	/*
	 * Save all arguments and r13.
	 *
	 * We can dump three parameters in the parameter area as we know that
	 * space has been reserved for at least three parameters.
	 */
	stw	r3, 208(r1)
	stw	r4, 212(r1)
	stw	r5, 216(r1)
	stw	r6, 56(r1)
	stw	r7, 60(r1)
	stw	r8, 64(r1)
	stw	r9, 68(r1)
	stw	r10, 72(r1)
	stw	r13, 76(r1)

	/* Save all floating point arguments */
	stfd	f1, 80(r1)
	stfd	f2, 88(r1)
	stfd	f3, 96(r1)
	stfd	f4, 104(r1)
	stfd	f5, 112(r1)
	stfd	f6, 120(r1)
	stfd	f7, 128(r1)
	stfd	f8, 136(r1)
	stfd	f9, 144(r1)
	stfd	f10, 152(r1)
	stfd	f11, 160(r1)
	stfd	f12, 168(r1)
	stfd	f13, 176(r1)

	mr	r3, r4
	bl	_object_getClass

	bl	0f
0:
	mflr	r13
	addis	r13, r13, ha16(Lsel_forwardingTargetForSelector_-0b)
	lwz	r13, lo16(Lsel_forwardingTargetForSelector_-0b)(r13)

	mr	r4, r13
	bl	_class_respondsToSelector

	cmpwi	r3, 0
	beq-	0f

	lwz	r3, 212(r1)
	mr	r4, r13
	lwz	r5, 216(r1)
	bl	_objc_msgSend

	cmpwi	r3, 0
	beq-	0f
	lwz	r4, 212(r1)
	cmpw	r3, r4
	beq-	0f

	mr	r4, r3

	/* Restore all arguments and r13, except r4 */
	lwz	r3, 208(r1)
	lwz	r5, 216(r1)
	lwz	r6, 56(r1)
	lwz	r7, 60(r1)
	lwz	r8, 64(r1)
	lwz	r9, 68(r1)
	lwz	r10, 72(r1)
	lwz	r13, 76(r1)

	/* Restore all floating point arguments */
	lfd	f1, 80(r1)
	lfd	f2, 88(r1)
	lfd	f3, 96(r1)
	lfd	f4, 104(r1)
	lfd	f5, 112(r1)
	lfd	f6, 120(r1)
	lfd	f7, 128(r1)
	lfd	f8, 136(r1)
	lfd	f9, 144(r1)
	lfd	f10, 152(r1)
	lfd	f11, 160(r1)
	lfd	f12, 168(r1)
	lfd	f13, 176(r1)

	addi	r1, r1, 184
	lwz	r0, 8(r1)
	mtlr	r0

	b	_objc_msgSend_stret

0:
	lwz	r3, 208(r1)
	lwz	r4, 212(r1)
	lwz	r5, 216(r1)

	addi	r1, r1, 184
	lwz	r0, 8(r1)
	mtlr	r0

	b	_OFMethodNotFound_stret
