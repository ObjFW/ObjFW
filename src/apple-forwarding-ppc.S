/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
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

.globl _of_forward
.globl _of_forward_stret

.section __TEXT, __cstring, cstring_literals
L_str_forwardingTargetForSelector:
	.asciz "forwardingTargetForSelector:"

.section __OBJC, __message_refs, literal_pointers, no_dead_strip
L_sel_forwardingTargetForSelector:
	.long L_str_forwardingTargetForSelector

.section __OBJC, __image_info
	.long 0, 0

.section __TEXT, __text, regular, pure_instructions
_of_forward:
.set FS, 176
	mflr	r0
	stw	r0, 8(r1)
	stwu	r1, -FS(r1)

	/* Save all arguments */
	stw	r3, FS+24(r1)
	stw	r4, FS+28(r1)
	stw	r5, FS+32(r1)
	stw	r6, FS+36(r1)
	stw	r7, FS+40(r1)
	stw	r8, FS+44(r1)
	stw	r9, FS+48(r1)
	stw	r10, FS+52(r1)

	/* Save all floating point arguments */
	stfd	f1, 56(r1)
	stfd	f2, 64(r1)
	stfd	f3, 72(r1)
	stfd	f4, 80(r1)
	stfd	f5, 88(r1)
	stfd	f6, 96(r1)
	stfd	f7, 104(r1)
	stfd	f8, 112(r1)
	stfd	f9, 120(r1)
	stfd	f10, 128(r1)
	stfd	f11, 136(r1)
	stfd	f12, 144(r1)
	stfd	f13, 152(r1)

	bl	_object_getClass

	bl	L0
L0:
	mflr	r4
	addis	r4, r4, ha16(L_sel_forwardingTargetForSelector-L0)
	lwz	r4, lo16(L_sel_forwardingTargetForSelector-L0)(r4)
	stw	r4, 160(r1)
	bl	_class_respondsToSelector
	cmpwi	r3, 0
	beq-	fail

	lwz	r3, FS+24(r1)
	lwz	r4, 160(r1)
	lwz	r5, FS+28(r1)
	bl	_objc_msgSend

	cmpwi	r3, 0
	beq-	fail

	lwz	r0, FS+24(r1)
	beq-	fail

	mr	r4, r3

	/* Restore all arguments, except r3 */
	lwz	r4, FS+28(r1)
	lwz	r5, FS+32(r1)
	lwz	r6, FS+36(r1)
	lwz	r7, FS+40(r1)
	lwz	r8, FS+44(r1)
	lwz	r9, FS+48(r1)
	lwz	r10, FS+52(r1)

	/* Restore all floating point arguments */
	lfd	f1, 56(r1)
	lfd	f2, 64(r1)
	lfd	f3, 72(r1)
	lfd	f4, 80(r1)
	lfd	f5, 88(r1)
	lfd	f6, 96(r1)
	lfd	f7, 104(r1)
	lfd	f8, 112(r1)
	lfd	f9, 120(r1)
	lfd	f10, 128(r1)
	lfd	f11, 136(r1)
	lfd	f12, 144(r1)
	lfd	f13, 152(r1)

	addi	r1, r1, FS
	lwz	r0, 8(r1)
	mtlr	r0

	b	_objc_msgSend

fail:
	lwz	r3, FS+24(r1)
	lwz	r4, FS+28(r1)

	addi	r1, r1, FS
	lwz	r0, 8(r1)
	mtlr	r0

	b	_of_method_not_found

_of_forward_stret:
.set FS, 176
	mflr	r0
	stw	r0, 8(r1)
	stwu	r1, -FS(r1)

	/* Save all arguments */
	stw	r3, FS+24(r1)
	stw	r4, FS+28(r1)
	stw	r5, FS+32(r1)
	stw	r6, FS+36(r1)
	stw	r7, FS+40(r1)
	stw	r8, FS+44(r1)
	stw	r9, FS+48(r1)
	stw	r10, FS+52(r1)

	/* Save all floating point arguments */
	stfd	f1, 56(r1)
	stfd	f2, 64(r1)
	stfd	f3, 72(r1)
	stfd	f4, 80(r1)
	stfd	f5, 88(r1)
	stfd	f6, 96(r1)
	stfd	f7, 104(r1)
	stfd	f8, 112(r1)
	stfd	f9, 120(r1)
	stfd	f10, 128(r1)
	stfd	f11, 136(r1)
	stfd	f12, 144(r1)
	stfd	f13, 152(r1)

	mr	r3, r4
	bl	_object_getClass

	bl	L1
L1:
	mflr	r4
	addis	r4, r4, ha16(L_sel_forwardingTargetForSelector-L1)
	lwz	r4, lo16(L_sel_forwardingTargetForSelector-L1)(r4)
	stw	r4, 160(r1)
	bl	_class_respondsToSelector
	cmpwi	r3, 0
	beq-	fail_stret

	lwz	r3, FS+28(r1)
	lwz	r4, 160(r1)
	lwz	r5, FS+32(r1)
	bl	_objc_msgSend

	cmpwi	r3, 0
	beq-	fail_stret

	lwz	r0, FS+28(r1)
	beq-	fail_stret

	mr	r4, r3

	/* Restore all arguments, except r4 */
	lwz	r3, FS+24(r1)
	lwz	r5, FS+32(r1)
	lwz	r6, FS+36(r1)
	lwz	r7, FS+40(r1)
	lwz	r8, FS+44(r1)
	lwz	r9, FS+48(r1)
	lwz	r10, FS+52(r1)

	/* Restore all floating point arguments */
	lfd	f1, 56(r1)
	lfd	f2, 64(r1)
	lfd	f3, 72(r1)
	lfd	f4, 80(r1)
	lfd	f5, 88(r1)
	lfd	f6, 96(r1)
	lfd	f7, 104(r1)
	lfd	f8, 112(r1)
	lfd	f9, 120(r1)
	lfd	f10, 128(r1)
	lfd	f11, 136(r1)
	lfd	f12, 144(r1)
	lfd	f13, 152(r1)

	addi	r1, r1, FS
	lwz	r0, 8(r1)
	mtlr	r0

	b	_objc_msgSend_stret

fail_stret:
	lwz	r3, FS+28(r1)
	lwz	r4, FS+32(r1)

	addi	r1, r1, FS
	lwz	r0, 8(r1)
	mtlr	r0

	b	_of_method_not_found
