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
	stwu	%r1, -112(%r1)
	mflr	%r0
	stw	%r0, 116(%r1)
#ifdef OF_PIC
	stw	%r30, 104(%r1)

	bl	0f
0:
	mflr	%r30
	addis	%r30, %r30, .Lbiased_got2-0b@ha
	addi	%r30, %r30, .Lbiased_got2-0b@l
#endif

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

#ifdef OF_PIC
	bl	object_getClass+0x8000@plt

	lwz	%r4, .Lgot_sel_forwardingTargetForSelector_-.Lbiased_got2(%r30)
	bl	class_respondsToSelector+0x8000@plt
#else
	bl	object_getClass

	lis	%r4, .Lsel_forwardingTargetForSelector_@ha
	la	%r4, .Lsel_forwardingTargetForSelector_@l(%r4)
	bl	class_respondsToSelector
#endif

	cmpwi	%r3, 0
	beq-	0f

	lwz	%r3, 8(%r1)
#ifdef OF_PIC
	lwz	%r4, .Lgot_sel_forwardingTargetForSelector_-.Lbiased_got2(%r30)
	bl	objc_msg_lookup+0x8000@plt
#else
	lis	%r4, .Lsel_forwardingTargetForSelector_@ha
	la	%r4, .Lsel_forwardingTargetForSelector_@l(%r4)
	bl	objc_msg_lookup
#endif
	mtctr	%r3

	lwz	%r3, 8(%r1)
#ifdef OF_PIC
	lwz	%r4, .Lgot_sel_forwardingTargetForSelector_-.Lbiased_got2(%r30)
#else
	lis	%r4, .Lsel_forwardingTargetForSelector_@ha
	la	%r4, .Lsel_forwardingTargetForSelector_@l(%r4)
#endif
	lwz	%r5, 12(%r1)
	bctrl

	cmpwi	%r3, 0
	beq-	0f
	lwz	%r4, 8(%r1)
	cmpw	%r3, %r4
	beq-	0f

	stw	%r3, 8(%r1)

	lwz	%r4, 12(%r1)
#ifdef OF_PIC
	bl	objc_msg_lookup+0x8000@plt
#else
	bl	objc_msg_lookup
#endif
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

#ifdef OF_PIC
	lwz	%r30, 104(%r1)
#endif
	lwz	%r0, 116(%r1)
	mtlr	%r0
	addi	%r1, %r1, 112
	bctr

0:
	lwz	%r3, 8(%r1)
	lwz	%r4, 12(%r1)

#ifdef OF_PIC
	lwz	%r0, .Lgot_OFMethodNotFound-.Lbiased_got2(%r30)
	mtctr	%r0
	lwz	%r30, 104(%r1)
#endif

	lwz	%r0, 116(%r1)
	mtlr	%r0
	addi	%r1, %r1, 112

#ifdef OF_PIC
	bctr
#else
	b	OFMethodNotFound
#endif
.type OFForward, @function
.size OFForward, .-OFForward

OFForward_stret:
	stwu	%r1, -112(%r1)
	mflr	%r0
	stw	%r0, 116(%r1)
#ifdef OF_PIC
	stw	%r30, 104(%r1)

	bl	0f
0:
	mflr	%r30
	addis	%r30, %r30, .Lbiased_got2-0b@ha
	addi	%r30, %r30, .Lbiased_got2-0b@l
#endif

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
#ifdef OF_PIC
	bl	object_getClass+0x8000@plt

	lwz	%r4, .Lgot_sel_forwardingTargetForSelector_-.Lbiased_got2(%r30)
	bl	class_respondsToSelector+0x8000@plt
#else
	bl	object_getClass

	lis	%r4, .Lsel_forwardingTargetForSelector_@ha
	la	%r4, .Lsel_forwardingTargetForSelector_@l(%r4)
	bl	class_respondsToSelector
#endif

	cmpwi	%r3, 0
	beq-	0f

	lwz	%r3, 12(%r1)
#ifdef OF_PIC
	lwz	%r4, .Lgot_sel_forwardingTargetForSelector_-.Lbiased_got2(%r30)
	bl	objc_msg_lookup+0x8000@plt
#else
	lis	%r4, .Lsel_forwardingTargetForSelector_@ha
	la	%r4, .Lsel_forwardingTargetForSelector_@l(%r4)
	bl	objc_msg_lookup
#endif
	mtctr	%r3

	lwz	%r3, 12(%r1)
#ifdef OF_PIC
	lwz	%r4, .Lgot_sel_forwardingTargetForSelector_-.Lbiased_got2(%r30)
#else
	lis	%r4, .Lsel_forwardingTargetForSelector_@ha
	la	%r4, .Lsel_forwardingTargetForSelector_@l(%r4)
#endif
	lwz	%r5, 16(%r1)
	bctrl

	cmpwi	%r3, 0
	beq-	0f
	lwz	%r4, 12(%r1)
	cmpw	%r3, %r4
	beq-	0f

	stw	%r3, 12(%r1)

	lwz	%r4, 16(%r1)
#ifdef OF_PIC
	bl	objc_msg_lookup_stret+0x8000@plt
#else
	bl	objc_msg_lookup_stret
#endif
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

#ifdef OF_PIC
	lwz	%r30, 104(%r1)
#endif
	lwz	%r0, 116(%r1)
	mtlr	%r0
	addi	%r1, %r1, 112
	bctr

0:
	lwz	%r3, 8(%r1)
	lwz	%r4, 12(%r1)
	lwz	%r5, 16(%r1)

#ifdef OF_PIC
	lwz	%r0, .Lgot_OFMethodNotFound_stret-.Lbiased_got2(%r30)
	mtctr	%r0
	lwz	%r30, 104(%r1)
#endif

	lwz	%r0, 116(%r1)
	mtlr	%r0
	addi	%r1, %r1, 112

#ifdef OF_PIC
	bctr
#else
	b	OFMethodNotFound_stret
#endif
.type OFForward_stret, @function
.size OFForward_stret, .-OFForward_stret

.Linit:
	stwu	%r1, -16(%r1)
	mflr	%r0
	stw	%r0, 20(%r1)
#ifdef OF_PIC
	stw	%r30, 8(%r1)

	bl	0f
0:
	mflr	%r30
	addis	%r30, %r30, .Lbiased_got2-0b@ha
	addi	%r30, %r30, .Lbiased_got2-0b@l

	lwz	%r3, .Lgot_module-.Lbiased_got2(%r30)
	bl	__objc_exec_class+0x8000@plt

	lwz	%r30, 8(%r1)
#else
	lis	%r3, .Lmodule@ha
	la	%r3, .Lmodule@l(%r3)
	bl	__objc_exec_class
#endif

	lwz	%r0, 20(%r1)
	addi	%r1, %r1, 16
	mtlr	%r0
	blr

.section .ctors, "aw", @progbits
	.long .Linit

.section .rodata
.Lstr_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section .data
.Lsel_forwardingTargetForSelector_:
	.long .Lstr_forwardingTargetForSelector_, 0
	.long 0, 0
.Lsymtab:
	.long 0, .Lsel_forwardingTargetForSelector_
	.short 0, 0
	.long 0
	.long 0
.Lmodule:
	.long 8, 16, 0, .Lsymtab

#ifdef OF_PIC
.section .got2, "aw"
.Lbiased_got2 = .+0x8000
.Lgot_module:
	.long .Lmodule
.Lgot_sel_forwardingTargetForSelector_:
	.long .Lsel_forwardingTargetForSelector_
.Lgot_OFMethodNotFound:
	.long OFMethodNotFound
.Lgot_OFMethodNotFound_stret:
	.long OFMethodNotFound_stret
#endif

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", @progbits
#endif
