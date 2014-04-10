/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#include "config.h"

.globl _of_forward
.globl _of_forward_stret

.section __TEXT, __objc_methname, cstring_literals
str_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section __DATA, __objc_selrefs, literal_pointers, no_dead_strip
sel_forwardingTargetForSelector_:
	.quad str_forwardingTargetForSelector_

.section __DATA, __objc_imageinfo, regular, no_dead_strip
	.long 0, 0

.section __TEXT, __text, regular, pure_instructions
_of_forward:
_of_forward_stret:
	stp	fp, lr, [sp, #-208]!
	mov	fp, sp
	sub	sp, sp, #208

	/* Save all arguments, x8 and x19 */
	stp	x0, x1, [sp]
	stp	x2, x3, [sp, #16]
	stp	x4, x5, [sp, #32]
	stp	x6, x7, [sp, #48]
	stp	x8, x19, [sp, #64]

	/* Save all foating point arguments */
	stp	q0, q1, [sp, #80]
	stp	q2, q3, [sp, #112]
	stp	q4, q5, [sp, #144]
	stp	q6, q7, [sp, #176]

	bl	_object_getClass

	adrp	x19, sel_forwardingTargetForSelector_@PAGE
	add	x19, x19, sel_forwardingTargetForSelector_@PAGEOFF
	ldr	x19, [x19]

	mov	x1, x19
	bl	_class_respondsToSelector

	cbz	x0, 0f

	ldp	x0, x2, [sp]
	mov	x1, x19
	bl	_objc_msgSend

	cbz	x0, 0f
	ldr	x1, [sp]
	cmp	x0, x1
	b.eq	0f

	/* Restore all arguments, x8 and x19, but not x0 */
	ldr	x1, [sp, #8]
	ldp	x2, x3, [sp, #16]
	ldp	x4, x5, [sp, #32]
	ldp	x6, x7, [sp, #48]
	ldp	x8, x19, [sp, #64]

	/* Restore all foating point arguments */
	ldp	q0, q1, [sp, #80]
	ldp	q2, q3, [sp, #112]
	ldp	q4, q5, [sp, #144]
	ldp	q6, q7, [sp, #176]

	mov	sp, fp
	ldp	fp, lr, [sp], #208

	b	_objc_msgSend

0:
	ldp	x0, x1, [sp]
	ldr	x19, [sp, #72]

	mov	sp, fp
	ldp	fp, lr, [sp], #208

	b	_of_method_not_found
