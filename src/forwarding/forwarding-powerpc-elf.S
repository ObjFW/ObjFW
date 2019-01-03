/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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
	stwu	%r1, -112(%r1)
	mflr	%r0
	stw	%r0, 116(%r1)

	/* Save all arguments */
	stw	%r3, 8(%r1)
	stw	%r4, 12(%r1)
	stw	%r5, 16(%r1)
	stw	%r6, 20(%r1)
	stw	%r7, 24(%r1)
	stw	%r8, 28(%r1)
	stw	%r9, 32(%r1)
	stw	%r10, 36(%r1)

	/* Save all floating point arguments */
	stfd	%f1, 40(%r1)
	stfd	%f2, 48(%r1)
	stfd	%f3, 56(%r1)
	stfd	%f4, 64(%r1)
	stfd	%f5, 72(%r1)
	stfd	%f6, 80(%r1)
	stfd	%f7, 88(%r1)
	stfd	%f8, 96(%r1)

	bl	object_getClass@plt

	lis	%r4, sel_forwardingTargetForSelector_@ha
	la	%r4, sel_forwardingTargetForSelector_@l(%r4)
	bl	class_respondsToSelector@plt

	cmpwi	%r3, 0
	beq-	0f

	lwz	%r3, 8(%r1)
	lis	%r4, sel_forwardingTargetForSelector_@ha
	la	%r4, sel_forwardingTargetForSelector_@l(%r4)
	bl	objc_msg_lookup@plt
	mtctr	%r3

	lwz	%r3, 8(%r1)
	lis	%r4, sel_forwardingTargetForSelector_@ha
	la	%r4, sel_forwardingTargetForSelector_@l(%r4)
	lwz	%r5, 12(%r1)
	bctrl

	cmpwi	%r3, 0
	beq-	0f
	lwz	%r4, 8(%r1)
	cmpw	%r3, %r4
	beq-	0f

	stw	%r3, 8(%r1)

	lwz	%r4, 12(%r1)
	bl	objc_msg_lookup@plt
	mtctr	%r3

	/* Restore all arguments */
	lwz	%r3, 8(%r1)
	lwz	%r4, 12(%r1)
	lwz	%r5, 16(%r1)
	lwz	%r6, 20(%r1)
	lwz	%r7, 24(%r1)
	lwz	%r8, 28(%r1)
	lwz	%r9, 32(%r1)
	lwz	%r10, 36(%r1)

	/* Restore all floating point arguments */
	lfd	%f1, 40(%r1)
	lfd	%f2, 48(%r1)
	lfd	%f3, 56(%r1)
	lfd	%f4, 64(%r1)
	lfd	%f5, 72(%r1)
	lfd	%f6, 80(%r1)
	lfd	%f7, 88(%r1)
	lfd	%f8, 96(%r1)

	lwz	%r0, 116(%r1)
	mtlr	%r0
	addi	%r1, %r1, 112
	bctr

0:
	lwz	%r3, 8(%r1)
	lwz	%r4, 12(%r1)

	lwz	%r0, 116(%r1)
	mtlr	%r0
	addi	%r1, %r1, 112

	b	of_method_not_found@plt
.type of_forward, @function
.size of_forward, .-of_forward

of_forward_stret:
	stwu	%r1, -112(%r1)
	mflr	%r0
	stw	%r0, 116(%r1)

	/* Save all arguments */
	stw	%r3, 8(%r1)
	stw	%r4, 12(%r1)
	stw	%r5, 16(%r1)
	stw	%r6, 20(%r1)
	stw	%r7, 24(%r1)
	stw	%r8, 28(%r1)
	stw	%r9, 32(%r1)
	stw	%r10, 36(%r1)

	/* Save all floating point arguments */
	stfd	%f1, 40(%r1)
	stfd	%f2, 48(%r1)
	stfd	%f3, 56(%r1)
	stfd	%f4, 64(%r1)
	stfd	%f5, 72(%r1)
	stfd	%f6, 80(%r1)
	stfd	%f7, 88(%r1)
	stfd	%f8, 96(%r1)

	mr	%r3, %r4
	bl	object_getClass@plt

	lis	%r4, sel_forwardingTargetForSelector_@ha
	la	%r4, sel_forwardingTargetForSelector_@l(%r4)
	bl	class_respondsToSelector@plt

	cmpwi	%r3, 0
	beq-	0f

	lwz	%r3, 12(%r1)
	lis	%r4, sel_forwardingTargetForSelector_@ha
	la	%r4, sel_forwardingTargetForSelector_@l(%r4)
	bl	objc_msg_lookup@plt
	mtctr	%r3

	lwz	%r3, 12(%r1)
	lis	%r4, sel_forwardingTargetForSelector_@ha
	la	%r4, sel_forwardingTargetForSelector_@l(%r4)
	lwz	%r5, 16(%r1)
	bctrl

	cmpwi	%r3, 0
	beq-	0f
	lwz	%r4, 12(%r1)
	cmpw	%r3, %r4
	beq-	0f

	stw	%r3, 12(%r1)

	lwz	%r4, 16(%r1)
	bl	objc_msg_lookup_stret@plt
	mtctr	%r3

	/* Restore all arguments */
	lwz	%r3, 8(%r1)
	lwz	%r4, 12(%r1)
	lwz	%r5, 16(%r1)
	lwz	%r6, 20(%r1)
	lwz	%r7, 24(%r1)
	lwz	%r8, 28(%r1)
	lwz	%r9, 32(%r1)
	lwz	%r10, 36(%r1)

	/* Restore all floating point arguments */
	lfd	%f1, 40(%r1)
	lfd	%f2, 48(%r1)
	lfd	%f3, 56(%r1)
	lfd	%f4, 64(%r1)
	lfd	%f5, 72(%r1)
	lfd	%f6, 80(%r1)
	lfd	%f7, 88(%r1)
	lfd	%f8, 96(%r1)

	lwz	%r0, 116(%r1)
	mtlr	%r0
	addi	%r1, %r1, 112
	bctr

0:
	lwz	%r3, 8(%r1)
	lwz	%r4, 12(%r1)
	lwz	%r5, 16(%r1)

	lwz	%r0, 116(%r1)
	mtlr	%r0
	addi	%r1, %r1, 112

	b	of_method_not_found_stret@plt
.type of_forward_stret, @function
.size of_forward_stret, .-of_forward_stret

init:
	lis	%r3, module@ha
	la	%r3, module@l(%r3)
	b	__objc_exec_class@plt

.section .ctors, "aw", @progbits
	.long init

.section .rodata
str_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section .data
sel_forwardingTargetForSelector_:
	.long str_forwardingTargetForSelector_, 0
	.long 0, 0
symtab:
	.long 0, sel_forwardingTargetForSelector_
	.short 0, 0
	.long 0
	.long 0
module:
	.long 8, 16, 0, symtab

#ifdef OF_LINUX
.section .note.GNU-stack, "", @progbits
#endif
