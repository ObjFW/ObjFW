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

.globl of_forward
.globl of_forward_stret

.section .text
of_forward:
#ifdef __PIC__
	lui	$gp, %hi(_gp_disp)
	addiu	$gp, $gp, %lo(_gp_disp)
	addu	$gp, $gp, $t9
#endif

	addiu	$sp, $sp, -72

	/*
	 * O32: The registers for floating point arguments don't need to be
	 * saved, as the ABI specifies that all remaining arguments are passed
	 * in integer registers if the first argument is passed in an integer
	 * register. This is always the case, as the first argument is always
	 * self.
	 */
	sw	$gp, 0($sp)
	sw	$ra, 4($sp)
	sw	$a0, 8($sp)
	sw	$a1, 12($sp)
	sw	$a2, 16($sp)
	sw	$a3, 20($sp)
#ifdef __mips_eabi
	/* For some reason, $a4-$a8 are not always defined */
	sw	$8, 24($sp)
	sw	$9, 28($sp)
	sw	$10, 32($sp)
	sw	$11, 36($sp)

	swc1	$f12, 40($sp)
	swc1	$f13, 44($sp)
	swc1	$f14, 48($sp)
	swc1	$f15, 52($sp)
	swc1	$f16, 56($sp)
	swc1	$f17, 60($sp)
	swc1	$f18, 64($sp)
	swc1	$f19, 68($sp)
#endif

#ifdef __PIC__
	lw	$a1, %got(sel_forwardingTargetForSelector_)($gp)
#else
	lui	$a1, %hi(sel_forwardingTargetForSelector_)
#endif
	addiu	$a1, $a1, %lo(sel_forwardingTargetForSelector_)
#ifdef __PIC__
	lw	$t9, %call16(objc_msg_lookup)($gp)
	jalr	$t9
#else
	jal	objc_msg_lookup
#endif

	lw	$gp, 0($sp)
	lw	$a0, 8($sp)
#ifdef __PIC__
	lw	$a1, %got(sel_forwardingTargetForSelector_)($gp)
#else
	lui	$a1, %hi(sel_forwardingTargetForSelector_)
#endif
	addiu	$a1, $a1, %lo(sel_forwardingTargetForSelector_)
	lw	$a2, 12($sp)
#ifdef __PIC__
	move	$t9, $v0
	jalr	$t9
#else
	jalr	$v0
#endif
	sw	$v0, 8($sp)

	lw	$gp, 0($sp)
	move	$a0, $v0
	lw	$a1, 12($sp)
#ifdef __PIC__
	lw	$t9, %call16(objc_msg_lookup)($gp)
	jalr	$t9
#else
	jal	objc_msg_lookup
#endif

#ifdef __mips_eabi
	lwc1	$f19, 68($sp)
	lwc1	$f18, 64($sp)
	lwc1	$f17, 60($sp)
	lwc1	$f16, 56($sp)
	lwc1	$f15, 52($sp)
	lwc1	$f14, 48($sp)
	lwc1	$f13, 44($sp)
	lwc1	$f12, 40($sp)

	lw	$11, 36($sp)
	lw	$10, 32($sp)
	lw	$9, 28($sp)
	lw	$8, 24($sp)
#endif
	lw	$a3, 20($sp)
	lw	$a2, 16($sp)
	lw	$a1, 12($sp)
	lw	$a0, 8($sp)
	lw	$ra, 4($sp)

	addiu	$sp, $sp, 72

#ifdef __PIC__
	move	$t9, $v0
	jr	$t9
#else
	jr	$v0
#endif
.type of_forward, %function
.size of_forward, .-of_forward

of_forward_stret:
#ifdef __PIC__
	lui	$gp, %hi(_gp_disp)
	addiu	$gp, $gp, %lo(_gp_disp)
	addu	$gp, $gp, $t9
#endif

	addiu	$sp, $sp, -72

	/*
	 * O32: The registers for floating point arguments don't need to be
	 * saved, as the ABI specifies that all remaining arguments are passed
	 * in integer registers if the first argument is passed in an integer
	 * register. This is always the case, as the first argument is always
	 * self.
	 */
	sw	$gp, 0($sp)
	sw	$ra, 4($sp)
	sw	$a0, 8($sp)
	sw	$a1, 12($sp)
	sw	$a2, 16($sp)
	sw	$a3, 20($sp)
#ifdef __mips_eabi
	/* For some reason, $a4-$a8 are not always defined */
	sw	$8, 24($sp)
	sw	$9, 28($sp)
	sw	$10, 32($sp)
	sw	$11, 36($sp)

	swc1	$f12, 40($sp)
	swc1	$f13, 44($sp)
	swc1	$f14, 48($sp)
	swc1	$f15, 52($sp)
	swc1	$f16, 56($sp)
	swc1	$f17, 60($sp)
	swc1	$f18, 64($sp)
	swc1	$f19, 68($sp)
#endif

	move	$a0, $a1
#ifdef __PIC__
	lw	$a1, %got(sel_forwardingTargetForSelector_)($gp)
#else
	lui	$a1, %hi(sel_forwardingTargetForSelector_)
#endif
	addiu	$a1, $a1, %lo(sel_forwardingTargetForSelector_)
#ifdef __PIC__
	lw	$t9, %call16(objc_msg_lookup)($gp)
	jalr	$t9
#else
	jal	objc_msg_lookup
#endif

	lw	$gp, 0($sp)
	lw	$a0, 12($sp)
#ifdef __PIC__
	lw	$a1, %got(sel_forwardingTargetForSelector_)($gp)
#else
	lui	$a1, %hi(sel_forwardingTargetForSelector_)
#endif
	addiu	$a1, $a1, %lo(sel_forwardingTargetForSelector_)
	lw	$a2, 16($sp)
#ifdef __PIC__
	move	$t9, $v0
	jalr	$t9
#else
	jalr	$v0
#endif
	sw	$v0, 12($sp)

	lw	$gp, 0($sp)
	move	$a0, $v0
	lw	$a1, 16($sp)
#ifdef __PIC__
	lw	$t9, %call16(objc_msg_lookup_stret)($gp)
	jalr	$t9
#else
	jal	objc_msg_lookup_stret
#endif

#ifdef __mips_eabi
	lwc1	$f19, 68($sp)
	lwc1	$f18, 64($sp)
	lwc1	$f17, 60($sp)
	lwc1	$f16, 56($sp)
	lwc1	$f15, 52($sp)
	lwc1	$f14, 48($sp)
	lwc1	$f13, 44($sp)
	lwc1	$f12, 40($sp)

	lw	$11, 36($sp)
	lw	$10, 32($sp)
	lw	$9, 28($sp)
	lw	$8, 24($sp)
#endif
	lw	$a3, 20($sp)
	lw	$a2, 16($sp)
	lw	$a1, 12($sp)
	lw	$a0, 8($sp)
	lw	$ra, 4($sp)

	addiu	$sp, $sp, 72

#ifdef __PIC__
	move	$t9, $v0
	jr	$t9
#else
	jr	$v0
#endif
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

.section .ctors, "a", %progbits
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
