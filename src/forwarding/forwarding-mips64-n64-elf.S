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
.hidden _OFForward
.hidden _OFForward_stret

.section .text
_OFForward:
	daddiu	$sp, $sp, -128
	sd	$ra, 0($sp)
	sd	$gp, 8($sp)

	lui	$gp, %hi(%neg(%gp_rel(_OFForward)))
	daddiu	$gp, $gp, %lo(%neg(%gp_rel(_OFForward)))
	daddu	$gp, $gp, $t9

	sd	$a0, 16($sp)
	sd	$a1, 24($sp)
	sd	$a2, 32($sp)
	sd	$a3, 40($sp)
	sd	$a4, 48($sp)
	sd	$a5, 56($sp)
	sd	$a6, 64($sp)
	sd	$a7, 72($sp)

	/*
	 * f12 and f13 are never used as the first two arguments are always
	 * self and _cmd.
	 */
	sdc1	$f14, 80($sp)
	sdc1	$f15, 88($sp)
	sdc1	$f16, 96($sp)
	sdc1	$f17, 104($sp)
	sdc1	$f18, 112($sp)
	sdc1	$f19, 120($sp)

	ld	$t9, %call16(object_getClass)($gp)
	jalr	$t9

	move	$a0, $v0
	ld	$a1, %got_disp(.Lsel_forwardingTargetForSelector_)($gp)
	ld	$t9, %call16(class_respondsToSelector)($gp)
	jalr	$t9
	beqz	$v0, 0f

	ld	$a0, 16($sp)
	ld	$a1, %got_disp(.Lsel_forwardingTargetForSelector_)($gp)
	ld	$t9, %call16(objc_msg_lookup)($gp)
	jalr	$t9

	ld	$a0, 16($sp)
	ld	$a1, %got_disp(.Lsel_forwardingTargetForSelector_)($gp)
	ld	$a2, 24($sp)
	move	$t9, $v0
	jalr	$t9

	beqz	$v0, 0f
	ld	$a0, 16($sp)
	beq	$v0, $a0, 0f

	sd	$v0, 16($sp)

	move	$a0, $v0
	ld	$a1, 24($sp)
	ld	$t9, %call16(objc_msg_lookup)($gp)
	jalr	$t9

	ldc1	$f19, 120($sp)
	ldc1	$f18, 112($sp)
	ldc1	$f17, 104($sp)
	ldc1	$f16, 96($sp)
	ldc1	$f15, 88($sp)
	ldc1	$f14, 80($sp)

	ld	$a7, 72($sp)
	ld	$a6, 64($sp)
	ld	$a5, 56($sp)
	ld	$a4, 48($sp)
	ld	$a3, 40($sp)
	ld	$a2, 32($sp)
	ld	$a1, 24($sp)
	ld	$a0, 16($sp)

	ld	$gp, 8($sp)
	ld	$ra, 0($sp)
	daddiu	$sp, $sp, 128

	move	$t9, $v0
	jr	$t9

0:
	ld	$t9, %call16(OFMethodNotFound)($gp)

	ld	$a1, 24($sp)
	ld	$a0, 16($sp)

	ld	$gp, 8($sp)
	ld	$ra, 0($sp)
	daddiu	$sp, $sp, 128

	jr	$t9
.type _OFForward, @function
.size _OFForward, .-_OFForward

_OFForward_stret:
	daddiu	$sp, $sp, -128
	sd	$ra, 0($sp)
	sd	$gp, 8($sp)

	lui	$gp, %hi(%neg(%gp_rel(_OFForward_stret)))
	daddiu	$gp, $gp, %lo(%neg(%gp_rel(_OFForward_stret)))
	daddu	$gp, $gp, $t9

	sd	$a0, 16($sp)
	sd	$a1, 24($sp)
	sd	$a2, 32($sp)
	sd	$a3, 40($sp)
	sd	$a4, 48($sp)
	sd	$a5, 56($sp)
	sd	$a6, 64($sp)
	sd	$a7, 72($sp)

	/*
	 * f12 and f13 are never used as the first two arguments are always
	 * self and _cmd.
	 */
	sdc1	$f14, 80($sp)
	sdc1	$f15, 88($sp)
	sdc1	$f16, 96($sp)
	sdc1	$f17, 104($sp)
	sdc1	$f18, 112($sp)
	sdc1	$f19, 120($sp)

	move	$a0, $a1
	ld	$t9, %call16(object_getClass)($gp)
	jalr	$t9

	move	$a0, $v0
	ld	$a1, %got_disp(.Lsel_forwardingTargetForSelector_)($gp)
	ld	$t9, %call16(class_respondsToSelector)($gp)
	jalr	$t9
	beqz	$v0, 0f

	ld	$a0, 24($sp)
	ld	$a1, %got_disp(.Lsel_forwardingTargetForSelector_)($gp)
	ld	$t9, %call16(objc_msg_lookup)($gp)
	jalr	$t9

	ld	$a0, 24($sp)
	ld	$a1, %got_disp(.Lsel_forwardingTargetForSelector_)($gp)
	ld	$a2, 32($sp)
	move	$t9, $v0
	jalr	$t9

	beqz	$v0, 0f
	ld	$a0, 24($sp)
	beq	$v0, $a0, 0f

	sd	$v0, 24($sp)

	move	$a0, $v0
	ld	$a1, 32($sp)
	ld	$t9, %call16(objc_msg_lookup_stret)($gp)
	jalr	$t9

	ldc1	$f19, 120($sp)
	ldc1	$f18, 112($sp)
	ldc1	$f17, 104($sp)
	ldc1	$f16, 96($sp)
	ldc1	$f15, 88($sp)
	ldc1	$f14, 80($sp)

	ld	$a7, 72($sp)
	ld	$a6, 64($sp)
	ld	$a5, 56($sp)
	ld	$a4, 48($sp)
	ld	$a3, 40($sp)
	ld	$a2, 32($sp)
	ld	$a1, 24($sp)
	ld	$a0, 16($sp)

	ld	$gp, 8($sp)
	ld	$ra, 0($sp)
	daddiu	$sp, $sp, 128

	move	$t9, $v0
	jr	$t9

0:
	ld	$t9, %call16(OFMethodNotFound_stret)($gp)

	ld	$a2, 32($sp)
	ld	$a1, 24($sp)
	ld	$a0, 16($sp)

	ld	$gp, 8($sp)
	ld	$ra, 0($sp)
	daddiu	$sp, $sp, 128

	jr	$t9
.type _OFForward_stret, @function
.size _OFForward_stret, .-_OFForward_stret

.Linit:
	daddiu	$sp, $sp, -16
	sd	$ra, 0($sp)
	sd	$gp, 8($sp)

	lui	$gp, %hi(%neg(%gp_rel(.Linit)))
	daddiu	$gp, $gp, %lo(%neg(%gp_rel(.Linit)))
	daddu	$gp, $gp, $t9

	ld	$a0, %got_disp(.Lmodule)($gp)
	ld	$t9, %call16(__objc_exec_class)($gp)
	jalr	$t9

	ld	$gp, 8($sp)
	ld	$ra, 0($sp)
	daddiu	$sp, $sp, 16

	jr	$ra

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
