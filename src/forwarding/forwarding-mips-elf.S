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

.globl of_forward
.globl of_forward_stret

#ifdef __PIC__
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
of_forward:
#ifdef __PIC__
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
#ifdef __mips_eabi
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
#ifdef __PIC__
	lw	$s1, %got(sel_forwardingTargetForSelector_)($gp)
#else
	lui	$s1, %hi(sel_forwardingTargetForSelector_)
#endif
	addiu	$s1, $s1, %lo(sel_forwardingTargetForSelector_)

	jal_pic	object_getClass

	move	$gp, $s0
	move	$a0, $v0
	move	$a1, $s1
	jal_pic	class_respondsToSelector
	beqz	$v0, fail

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

	beqz	$v0, fail
	lw	$t0, 28($sp)
	beq	$v0, $t0, fail

	sw	$v0, 28($sp)

	move	$gp, $s0
	move	$a0, $v0
	lw	$a1, 32($sp)
	jal_pic	objc_msg_lookup

#ifdef __mips_eabi
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

fail:
	move	$gp, $s0

	lw	$a1, 32($sp)
	lw	$a0, 28($sp)
	lw	$s1, 24($sp)
	lw	$s0, 20($sp)
	lw	$ra, 16($sp)

	addiu	$sp, $sp, 96

	j_pic	of_method_not_found
.type of_forward, %function
.size of_forward, .-of_forward

of_forward_stret:
#ifdef __PIC__
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
#ifdef __mips_eabi
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
#ifdef __PIC__
	lw	$s1, %got(sel_forwardingTargetForSelector_)($gp)
#else
	lui	$s1, %hi(sel_forwardingTargetForSelector_)
#endif
	addiu	$s1, $s1, %lo(sel_forwardingTargetForSelector_)

	move	$a0, $a1
	jal_pic	object_getClass

	move	$gp, $s0
	move	$a0, $v0
	move	$a1, $s1
	jal_pic	class_respondsToSelector
	beqz	$v0, fail_stret

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

	beqz	$v0, fail_stret
	lw	$t0, 32($sp)
	beq	$v0, $t0, fail_stret

	sw	$v0, 32($sp)

	move	$gp, $s0
	move	$a0, $v0
	lw	$a1, 36($sp)
	jal_pic	objc_msg_lookup_stret

#ifdef __mips_eabi
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

fail_stret:
	move	$gp, $s0

	lw	$a2, 36($sp)
	lw	$a1, 32($sp)
	lw	$a0, 28($sp)
	lw	$s1, 24($sp)
	lw	$s0, 20($sp)
	lw	$ra, 16($sp)

	addiu	$sp, $sp, 96

	j_pic	of_method_not_found_stret
.type of_forward_stret, %function
.size of_forward_stret, .-of_forward_stret

init:
#ifdef __PIC__
	lui	$gp, %hi(_gp_disp)
	addiu	$gp, $gp, %lo(_gp_disp)
	addu	$gp, $gp, $t9

	lw	$a0, %got(module)($gp)
	addiu	$a0, $a0, %lo(module)
	lw	$t9, %call16(__objc_exec_class)($gp)
	jr	$t9
#else
	lui	$a0, %hi(module)
	addiu	$a0, $a0, %lo(module)
	j	__objc_exec_class
#endif

.section .ctors, "aw", %progbits
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

#ifdef __linux__
.section .note.GNU-stack, "", %progbits
#endif
