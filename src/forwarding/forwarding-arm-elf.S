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
	stmfd	sp!, {r0-r3, lr}
	fstmfdd	sp!, {d0-d7}

	ldr	r1, sel_forwardingTargetForSelector_$indirect_L0
.L0:
	add	r1, pc
	stmfd	sp!, {r1}
	bl	objc_msg_lookup(PLT)
	ldmfd	sp!, {r1}

	mov	r12, r0
	ldr	r0, [sp, #64]
	ldr	r2, [sp, #68]
	blx	r12

	str	r0, [sp, #64]
	ldr	r1, [sp, #68]
	bl	objc_msg_lookup(PLT)

	mov	r12, r0
	fldmfdd	sp!, {d0-d7}
	ldmfd	sp!, {r0-r3, lr}

	bx	r12
.type of_forward, %function
.size of_forward, .-of_forward

of_forward_stret:
	stmfd	sp!, {r0-r3, lr}
	fstmfdd	sp!, {d0-d7}

	mov	r0, r1
	ldr	r1, sel_forwardingTargetForSelector_$indirect_L1
.L1:
	add	r1, pc
	stmfd	sp!, {r1}
	bl	objc_msg_lookup(PLT)
	ldmfd	sp!, {r1}

	mov	r12, r0
	ldr	r0, [sp, #68]
	ldr	r2, [sp, #72]
	blx	r12

	str	r0, [sp, #68]
	ldr	r1, [sp, #72]
	bl	objc_msg_lookup_stret(PLT)

	mov	r12, r0
	fldmfdd	sp!, {d0-d7}
	ldmfd	sp!, {r0-r3, lr}

	bx	r12
.type of_forward_stret, %function
.size of_forward_stret, .-of_forward_stret

init:
	ldr	r0, module_indirect_L2
.L2:
	add	r0, pc
	b	__objc_exec_class(PLT)

sel_forwardingTargetForSelector_$indirect_L0:
	.long sel_forwardingTargetForSelector_-(.L0+8)
sel_forwardingTargetForSelector_$indirect_L1:
	.long sel_forwardingTargetForSelector_-(.L1+8)
module_indirect_L2:
	.long module-(.L2+8)

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
