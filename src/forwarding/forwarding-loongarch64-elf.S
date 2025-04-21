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

.globl OFForward
.globl OFForward_stret

.section .text
OFForward:
	addi.d	$sp, $sp, -144
	st.d	$ra, $sp, 0

	st.d	$a0, $sp, 8
	st.d	$a1, $sp, 16
	st.d	$a2, $sp, 24
	st.d	$a3, $sp, 32
	st.d	$a4, $sp, 40
	st.d	$a5, $sp, 48
	st.d	$a6, $sp, 56
	st.d	$a7, $sp, 64

	fst.d	$fa0, $sp, 72
	fst.d	$fa1, $sp, 80
	fst.d	$fa2, $sp, 88
	fst.d	$fa3, $sp, 96
	fst.d	$fa4, $sp, 104
	fst.d	$fa5, $sp, 112
	fst.d	$fa6, $sp, 120
	fst.d	$fa7, $sp, 128

	bl	%plt(object_getClass)

	la.local $a1, .Lsel_forwardingTargetForSelector_
	bl	%plt(class_respondsToSelector)
	beqz	$a0, 0f

	ld.d	$a0, $sp, 8
	la.local $a1, .Lsel_forwardingTargetForSelector_
	bl	%plt(objc_msg_lookup)
	move	$t0, $a0

	ld.d	$a0, $sp, 8
	la.local $a1, .Lsel_forwardingTargetForSelector_
	ld.d	$a2, $sp, 16
	jirl	$ra, $t0, 0

	beqz	$a0, 0f
	ld.d	$t0, $sp, 8
	beq	$t0, $a0, 0f

	st.d	$a0, $sp, 8

	ld.d	$a1, $sp, 16
	bl	%plt(objc_msg_lookup)
	move	$t0, $a0

	fld.d	$fa7, $sp, 128
	fld.d	$fa6, $sp, 120
	fld.d	$fa5, $sp, 112
	fld.d	$fa4, $sp, 104
	fld.d	$fa3, $sp, 96
	fld.d	$fa2, $sp, 88
	fld.d	$fa1, $sp, 80
	fld.d	$fa0, $sp, 72

	ld.d	$a7, $sp, 64
	ld.d	$a6, $sp, 56
	ld.d	$a5, $sp, 48
	ld.d	$a4, $sp, 40
	ld.d	$a3, $sp, 32
	ld.d	$a2, $sp, 24
	ld.d	$a1, $sp, 16
	ld.d	$a0, $sp, 8

	ld.d	$ra, $sp, 0
	addi.d	$sp, $sp, 144

	jr	$t0

0:
	ld.d	$a1, $sp, 16
	ld.d	$a0, $sp, 8

	ld.d	$ra, $sp, 0
	addi.d	$sp, $sp, 144

	b	%plt(OFMethodNotFound)
.type OFForward, @function
.size OFForward, .-OFForward

OFForward_stret:
	addi.d	$sp, $sp, -144
	st.d	$ra, $sp, 0

	st.d	$a0, $sp, 8
	st.d	$a1, $sp, 16
	st.d	$a2, $sp, 24
	st.d	$a3, $sp, 32
	st.d	$a4, $sp, 40
	st.d	$a5, $sp, 48
	st.d	$a6, $sp, 56
	st.d	$a7, $sp, 64

	fst.d	$fa0, $sp, 72
	fst.d	$fa1, $sp, 80
	fst.d	$fa2, $sp, 88
	fst.d	$fa3, $sp, 96
	fst.d	$fa4, $sp, 104
	fst.d	$fa5, $sp, 112
	fst.d	$fa6, $sp, 120
	fst.d	$fa7, $sp, 128

	move	$a0, $a1
	bl	%plt(object_getClass)

	la.local $a1, .Lsel_forwardingTargetForSelector_
	bl	%plt(class_respondsToSelector)
	beqz	$a0, 0f

	ld.d	$a0, $sp, 16
	la.local $a1, .Lsel_forwardingTargetForSelector_
	bl	%plt(objc_msg_lookup)
	move	$t0, $a0

	ld.d	$a0, $sp, 16
	la.local $a1, .Lsel_forwardingTargetForSelector_
	ld.d	$a2, $sp, 24
	jirl	$ra, $t0, 0

	beqz	$a0, 0f
	ld.d	$t0, $sp, 16
	beq	$t0, $a0, 0f

	st.d	$a0, $sp, 16

	ld.d	$a1, $sp, 24
	bl	%plt(objc_msg_lookup_stret)
	move	$t0, $a0

	fld.d	$fa7, $sp, 128
	fld.d	$fa6, $sp, 120
	fld.d	$fa5, $sp, 112
	fld.d	$fa4, $sp, 104
	fld.d	$fa3, $sp, 96
	fld.d	$fa2, $sp, 88
	fld.d	$fa1, $sp, 80
	fld.d	$fa0, $sp, 72

	ld.d	$a7, $sp, 64
	ld.d	$a6, $sp, 56
	ld.d	$a5, $sp, 48
	ld.d	$a4, $sp, 40
	ld.d	$a3, $sp, 32
	ld.d	$a2, $sp, 24
	ld.d	$a1, $sp, 16
	ld.d	$a0, $sp, 8

	ld.d	$ra, $sp, 0
	addi.d	$sp, $sp, 144

	jr	$t0

0:
	ld.d	$a2, $sp, 24
	ld.d	$a1, $sp, 16
	ld.d	$a0, $sp, 8

	ld.d	$ra, $sp, 0
	addi.d	$sp, $sp, 144

	b	%plt(OFMethodNotFound_stret)
.type OFForward_stret, @function
.size OFForward_stret, .-OFForward_stret

.Linit:
	la.local $a0, .Lmodule
	b	%plt(__objc_exec_class)

.section .init_array, "aw"
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
