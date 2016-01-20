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

.globl of_forward
.globl of_forward_stret

.section .text
of_forward:
of_forward_stret:
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

	bl	object_getClass

	adrp	x19, sel_forwardingTargetForSelector_
	add	x19, x19, :lo12:sel_forwardingTargetForSelector_

	mov	x1, x19
	bl	class_respondsToSelector

	cbz	x0, 0f

	ldr	x0, [sp]
	mov	x1, x19
	bl	objc_msg_lookup

	mov	x1, x19
	mov	x19, x0
	ldp	x0, x2, [sp]
	blr	x19

	cbz	x0, 0f
	ldr	x1, [sp]
	cmp	x0, x1
	b.eq	0f

	mov	x19, x0
	ldr	x1, [sp, #8]
	bl	objc_msg_lookup

	mov	x16, x0
	mov	x0, x19

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

	br	x16

0:
	ldp	x0, x1, [sp]
	ldr	x19, [sp, #72]

	mov	sp, fp
	ldp	fp, lr, [sp], #208

	b	of_method_not_found
.type of_forward, %function
.size of_forward, .-of_forward
.type of_forward_stret, %function
.size of_forward_stret, .-of_forward_stret

init:
	adrp	x0, module
	add	x0, x0, :lo12:module
	b	__objc_exec_class

.section .init_array, "aw", %init_array
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
	.short 0, 0
	.long 4
	.xword 0
module:
	.xword 8, 32, 0, symtab

#ifdef OF_LINUX
.section .note.GNU-stack, "", %progbits
#endif
