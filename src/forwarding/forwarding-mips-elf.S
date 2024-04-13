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

#ifdef OF_PIC
.macro j_pic symbol
	lw	$t9, %call16(\symbol)($gp)
	jr	$t9
.endm
.macro jal_pic symbol
	lw	$t9, %call16(\symbol)($gp)
	jalr	$t9
.endm
#else
.macro j_pic symbol
	j	\symbol
.endm
.macro jal_pic symbol
	jal	\symbol
.endm
#endif

.section .text
OFForward:
#ifdef OF_PIC
	lui	$gp, %hi(_gp_disp)
	addiu	$gp, $gp, %lo(_gp_disp)
	addu	$gp, $gp, $t9
#endif

	addiu	$sp, $sp, -96

	/*
	 * O32: The registers for floating point arguments don't need to be
	 * saved, as the ABI specifies that all remaining arguments are passed
	 * in integer registers if the first argument is passed in an integer
	 * register. This is always the case, as the first argument is always
	 * self.
	 */
	sw	$ra, 16($sp)
	sw	$s0, 20($sp)
	sw	$s1, 24($sp)

	sw	$a0, 28($sp)
	sw	$a1, 32($sp)
	sw	$a2, 36($sp)
	sw	$a3, 40($sp)
#ifdef OF_MIPS_EABI
	/* For some reason, $a4-$a8 are not always defined */
	sw	$8, 44($sp)
	sw	$9, 48($sp)
	sw	$10, 52($sp)
	sw	$11, 56($sp)

	swc1	$f12, 60($sp)
	swc1	$f13, 64($sp)
	swc1	$f14, 68($sp)
	swc1	$f15, 72($sp)
	swc1	$f16, 76($sp)
	swc1	$f17, 80($sp)
	swc1	$f18, 84($sp)
	swc1	$f19, 88($sp)
#endif

	move	$s0, $gp
#ifdef OF_PIC
	lw	$s1, %got(.Lsel_forwardingTargetForSelector_)($gp)
#else
	lui	$s1, %hi(.Lsel_forwardingTargetForSelector_)
#endif
	addiu	$s1, $s1, %lo(.Lsel_forwardingTargetForSelector_)

	jal_pic	object_getClass

	move	$gp, $s0
	move	$a0, $v0
	move	$a1, $s1
	jal_pic	class_respondsToSelector
	beqz	$v0, 0f

	move	$gp, $s0
	lw	$a0, 28($sp)
	move	$a1, $s1
	jal_pic	objc_msg_lookup

	move	$gp, $s0
	lw	$a0, 28($sp)
	move	$a1, $s1
	lw	$a2, 32($sp)
	move	$t9, $v0
	jalr	$t9

	beqz	$v0, 0f
	lw	$t0, 28($sp)
	beq	$v0, $t0, 0f

	sw	$v0, 28($sp)

	move	$gp, $s0
	move	$a0, $v0
	lw	$a1, 32($sp)
	jal_pic	objc_msg_lookup

#ifdef OF_MIPS_EABI
	lwc1	$f19, 88($sp)
	lwc1	$f18, 84($sp)
	lwc1	$f17, 80($sp)
	lwc1	$f16, 76($sp)
	lwc1	$f15, 72($sp)
	lwc1	$f14, 68($sp)
	lwc1	$f13, 64($sp)
	lwc1	$f12, 60($sp)

	lw	$11, 56($sp)
	lw	$10, 52($sp)
	lw	$9, 48($sp)
	lw	$8, 44($sp)
#endif
	lw	$a3, 40($sp)
	lw	$a2, 36($sp)
	lw	$a1, 32($sp)
	lw	$a0, 28($sp)

	lw	$s1, 24($sp)
	lw	$s0, 20($sp)
	lw	$ra, 16($sp)

	addiu	$sp, $sp, 96

	move	$t9, $v0
	jr	$t9

0:
	move	$gp, $s0

	lw	$a1, 32($sp)
	lw	$a0, 28($sp)
	lw	$s1, 24($sp)
	lw	$s0, 20($sp)
	lw	$ra, 16($sp)

	addiu	$sp, $sp, 96

	j_pic	of_method_not_found
.type OFForward, %function
.size OFForward, .-OFForward

OFForward_stret:
#ifdef OF_PIC
	lui	$gp, %hi(_gp_disp)
	addiu	$gp, $gp, %lo(_gp_disp)
	addu	$gp, $gp, $t9
#endif

	addiu	$sp, $sp, -96

	/*
	 * O32: The registers for floating point arguments don't need to be
	 * saved, as the ABI specifies that all remaining arguments are passed
	 * in integer registers if the first argument is passed in an integer
	 * register. This is always the case, as the first argument is always
	 * self.
	 */
	sw	$ra, 16($sp)
	sw	$s0, 20($sp)
	sw	$s1, 24($sp)

	sw	$a0, 28($sp)
	sw	$a1, 32($sp)
	sw	$a2, 36($sp)
	sw	$a3, 40($sp)
#ifdef OF_MIPS_EABI
	/* For some reason, $a4-$a8 are not always defined */
	sw	$8, 44($sp)
	sw	$9, 48($sp)
	sw	$10, 52($sp)
	sw	$11, 56($sp)

	swc1	$f12, 60($sp)
	swc1	$f13, 64($sp)
	swc1	$f14, 68($sp)
	swc1	$f15, 72($sp)
	swc1	$f16, 76($sp)
	swc1	$f17, 80($sp)
	swc1	$f18, 84($sp)
	swc1	$f19, 88($sp)
#endif

	move	$s0, $gp
#ifdef OF_PIC
	lw	$s1, %got(.Lsel_forwardingTargetForSelector_)($gp)
#else
	lui	$s1, %hi(.Lsel_forwardingTargetForSelector_)
#endif
	addiu	$s1, $s1, %lo(.Lsel_forwardingTargetForSelector_)

	move	$a0, $a1
	jal_pic	object_getClass

	move	$gp, $s0
	move	$a0, $v0
	move	$a1, $s1
	jal_pic	class_respondsToSelector
	beqz	$v0, 0f

	move	$gp, $s0
	lw	$a0, 32($sp)
	move	$a1, $s1
	jal_pic	objc_msg_lookup

	move	$gp, $s0
	lw	$a0, 32($sp)
	move	$a1, $s1
	lw	$a2, 36($sp)
	move	$t9, $v0
	jalr	$t9

	beqz	$v0, 0f
	lw	$t0, 32($sp)
	beq	$v0, $t0, 0f

	sw	$v0, 32($sp)

	move	$gp, $s0
	move	$a0, $v0
	lw	$a1, 36($sp)
	jal_pic	objc_msg_lookup_stret

#ifdef OF_MIPS_EABI
	lwc1	$f19, 88($sp)
	lwc1	$f18, 84($sp)
	lwc1	$f17, 80($sp)
	lwc1	$f16, 76($sp)
	lwc1	$f15, 72($sp)
	lwc1	$f14, 68($sp)
	lwc1	$f13, 64($sp)
	lwc1	$f12, 60($sp)

	lw	$11, 56($sp)
	lw	$10, 52($sp)
	lw	$9, 48($sp)
	lw	$8, 44($sp)
#endif
	lw	$a3, 40($sp)
	lw	$a2, 36($sp)
	lw	$a1, 32($sp)
	lw	$a0, 28($sp)

	lw	$s1, 24($sp)
	lw	$s0, 20($sp)
	lw	$ra, 16($sp)

	addiu	$sp, $sp, 96

	move	$t9, $v0
	jr	$t9

0:
	move	$gp, $s0

	lw	$a2, 36($sp)
	lw	$a1, 32($sp)
	lw	$a0, 28($sp)
	lw	$s1, 24($sp)
	lw	$s0, 20($sp)
	lw	$ra, 16($sp)

	addiu	$sp, $sp, 96

	j_pic	of_method_not_found_stret
.type OFForward_stret, %function
.size OFForward_stret, .-OFForward_stret

.Linit:
#ifdef OF_PIC
	lui	$gp, %hi(_gp_disp)
	addiu	$gp, $gp, %lo(_gp_disp)
	addu	$gp, $gp, $t9

	lw	$a0, %got(.Lmodule)($gp)
	addiu	$a0, $a0, %lo(.Lmodule)
	lw	$t9, %call16(__objc_exec_class)($gp)
	jr	$t9
#else
	lui	$a0, %hi(.Lmodule)
	addiu	$a0, $a0, %lo(.Lmodule)
	j	__objc_exec_class
#endif

.section .ctors, "aw", %progbits
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

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", %progbits
#endif
