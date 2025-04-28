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

.section .text
.section .opd, "aw", @progbits
_OFForward:
	.p2align 3
	.quad .Lbegin__OFForward
	.quad .TOC.@tocbase
	.quad 0
.previous
.Lbegin__OFForward:
	.cfi_startproc
	mflr	%r0
	std	%r0, 16(%r1)
	stdu	%r1, -256(%r1)
	.cfi_def_cfa_offset 256
	.cfi_offset lr, 16
	std	%r2, 40(%r1)

	/* Save all arguments */
	std	%r3, 128(%r1)
	std	%r4, 136(%r1)
	std	%r5, 144(%r1)
	std	%r6, 152(%r1)
	std	%r7, 160(%r1)
	std	%r8, 168(%r1)
	std	%r9, 176(%r1)
	std	%r10, 184(%r1)

	/* Save all floating point arguments */
	stfd	%f1, 192(%r1)
	stfd	%f2, 200(%r1)
	stfd	%f3, 208(%r1)
	stfd	%f4, 216(%r1)
	stfd	%f5, 224(%r1)
	stfd	%f6, 232(%r1)
	stfd	%f7, 240(%r1)
	stfd	%f8, 248(%r1)

	bl	object_getClass
	nop

	addis	%r4, %r2, .Lsel_forwardingTargetForSelector_@toc@ha
	addi	%r4, %r4, .Lsel_forwardingTargetForSelector_@toc@l
	bl	class_respondsToSelector
	nop

	cmpdi	%r3, 0
	beq-	0f

	ld	%r3, 128(%r1)
	addis	%r4, %r2, .Lsel_forwardingTargetForSelector_@toc@ha
	addi	%r4, %r4, .Lsel_forwardingTargetForSelector_@toc@l
	bl	objc_msg_lookup
	nop
	mr	%r12, %r3

	ld	%r3, 128(%r1)
	addis	%r4, %r2, .Lsel_forwardingTargetForSelector_@toc@ha
	addi	%r4, %r4, .Lsel_forwardingTargetForSelector_@toc@l
	ld	%r5, 136(%r1)

	ld	%r2, 8(%r12)
	ld	%r12, 0(%r12)
	mtctr	%r12
	bctrl
	ld	%r2, 40(%r1)

	cmpdi	%r3, 0
	beq-	0f
	ld	%r4, 128(%r1)
	cmpw	%r3, %r4
	beq-	0f

	std	%r3, 128(%r1)

	ld	%r4, 136(%r1)
	bl	objc_msg_lookup
	nop
	mr	%r12, %r3

	/* Restore all arguments */
	ld	%r3, 128(%r1)
	ld	%r4, 136(%r1)
	ld	%r5, 144(%r1)
	ld	%r6, 152(%r1)
	ld	%r7, 160(%r1)
	ld	%r8, 168(%r1)
	ld	%r9, 176(%r1)
	ld	%r10, 184(%r1)

	/* Restore all floating point arguments */
	lfd	%f1, 192(%r1)
	lfd	%f2, 200(%r1)
	lfd	%f3, 208(%r1)
	lfd	%f4, 216(%r1)
	lfd	%f5, 224(%r1)
	lfd	%f6, 232(%r1)
	lfd	%f7, 240(%r1)
	lfd	%f8, 248(%r1)

	addi	%r1, %r1, 256
	ld	%r0, 16(%r1)
	mtlr	%r0

	ld	%r2, 8(%r12)
	ld	%r12, 0(%r12)
	mtctr	%r12
	bctr

0:
	ld	%r3, 128(%r1)
	ld	%r4, 136(%r1)

	bl	OFMethodNotFound
	nop

	addi	%r1, %r1, 256
	lwz	%r0, 16(%r1)
	mtlr	%r0

	blr
	.cfi_endproc
.type _OFForward, @function
.size _OFForward, .-.Lbegin__OFForward

.section .opd, "aw", @progbits
_OFForward_stret:
	.p2align 3
	.quad .Lbegin__OFForward_stret
	.quad .TOC.@tocbase
	.quad 0
.previous
.Lbegin__OFForward_stret:
	.cfi_startproc
	mflr	%r0
	std	%r0, 16(%r1)
	stdu	%r1, -256(%r1)
	.cfi_def_cfa_offset 256
	.cfi_offset lr, 16
	std	%r2, 40(%r1)

	/* Save all arguments */
	std	%r3, 128(%r1)
	std	%r4, 136(%r1)
	std	%r5, 144(%r1)
	std	%r6, 152(%r1)
	std	%r7, 160(%r1)
	std	%r8, 168(%r1)
	std	%r9, 176(%r1)
	std	%r10, 184(%r1)

	/* Save all floating point arguments */
	stfd	%f1, 192(%r1)
	stfd	%f2, 200(%r1)
	stfd	%f3, 208(%r1)
	stfd	%f4, 216(%r1)
	stfd	%f5, 224(%r1)
	stfd	%f6, 232(%r1)
	stfd	%f7, 240(%r1)
	stfd	%f8, 248(%r1)

	mr	%r3, %r4
	bl	object_getClass
	nop

	addis	%r4, %r2, .Lsel_forwardingTargetForSelector_@toc@ha
	addi	%r4, %r4, .Lsel_forwardingTargetForSelector_@toc@l
	bl	class_respondsToSelector
	nop

	cmpdi	%r3, 0
	beq-	0f

	ld	%r3, 136(%r1)
	addis	%r4, %r2, .Lsel_forwardingTargetForSelector_@toc@ha
	addi	%r4, %r4, .Lsel_forwardingTargetForSelector_@toc@l
	bl	objc_msg_lookup
	nop
	mr	%r12, %r3

	ld	%r3, 136(%r1)
	addis	%r4, %r2, .Lsel_forwardingTargetForSelector_@toc@ha
	addi	%r4, %r4, .Lsel_forwardingTargetForSelector_@toc@l
	ld	%r5, 144(%r1)

	ld	%r2, 8(%r12)
	ld	%r12, 0(%r12)
	mtctr	%r12
	bctrl
	ld	%r2, 40(%r1)

	cmpdi	%r3, 0
	beq-	0f
	ld	%r4, 136(%r1)
	cmpw	%r3, %r4
	beq-	0f

	std	%r3, 136(%r1)

	ld	%r4, 144(%r1)
	bl	objc_msg_lookup_stret
	nop
	mr	%r12, %r3

	/* Restore all arguments */
	ld	%r3, 128(%r1)
	ld	%r4, 136(%r1)
	ld	%r5, 144(%r1)
	ld	%r6, 152(%r1)
	ld	%r7, 160(%r1)
	ld	%r8, 168(%r1)
	ld	%r9, 176(%r1)
	ld	%r10, 184(%r1)

	/* Restore all floating point arguments */
	lfd	%f1, 192(%r1)
	lfd	%f2, 200(%r1)
	lfd	%f3, 208(%r1)
	lfd	%f4, 216(%r1)
	lfd	%f5, 224(%r1)
	lfd	%f6, 232(%r1)
	lfd	%f7, 240(%r1)
	lfd	%f8, 248(%r1)

	addi	%r1, %r1, 256
	ld	%r0, 16(%r1)
	mtlr	%r0

	ld	%r2, 8(%r12)
	ld	%r12, 0(%r12)
	mtctr	%r12
	bctr

0:
	ld	%r3, 128(%r1)
	ld	%r4, 136(%r1)
	ld	%r5, 144(%r1)

	bl	OFMethodNotFound_stret
	nop

	addi	%r1, %r1, 256
	lwz	%r0, 16(%r1)
	mtlr	%r0

	blr
	.cfi_endproc
.type _OFForward_stret, @function
.size _OFForward_stret, .-.Lbegin__OFForward_stret

.section .opd, "aw", @progbits
.Linit:
	.p2align 3
	.quad .Lbegin_.Linit
	.quad .TOC.@tocbase
	.quad 0
.previous
.Lbegin_.Linit:
	mflr	%r0
	std	%r0, 16(%r1)
	stdu	%r1, -32(%r1)

	addis	%r3, %r2, .Lmodule@toc@ha
	addi	%r3, %r3, .Lmodule@toc@l
	bl	__objc_exec_class
	nop

	addi	%r1, %r1, 32
	ld	%r0, 16(%r1)

	mtlr	%r0
	blr

.section .ctors, "aw", @progbits
	.quad .Linit

.section .rodata
.Lstr_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section .data
.Lsel_forwardingTargetForSelector_:
	.quad .Lstr_forwardingTargetForSelector_, 0
	.quad 0, 0
.Lsymtab:
	.quad 0, .Lsel_forwardingTargetForSelector_
	.short 0, 0
	.long 0
	.quad 0
.Lmodule:
	.quad 8, 32, 0, .Lsymtab

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", @progbits
#endif
