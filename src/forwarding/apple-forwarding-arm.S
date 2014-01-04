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

.globl _of_forward
.globl _of_forward_stret

.section __TEXT, __objc_methname, cstring_literals
L_str_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section __DATA, __objc_selrefs, literal_pointers, no_dead_strip
L_sel_forwardingTargetForSelector_:
	.long L_str_forwardingTargetForSelector_

.section __DATA, __objc_imageinfo, regular, no_dead_strip
	.long 0, 0

.section __TEXT, __text, regular, pure_instructions
.arm
.align 2
_of_forward:
	stmfd	sp!, {r0-r4, lr}
	fstmfdd	sp!, {d0-d7}

	ldr	r4, L_sel_forwardingTargetForSelector_$indirect_L0
L0:
	ldr	r4, [pc, r4]

	blx	_object_getClass

	mov	r1, r4
	blx	_class_respondsToSelector

	cmp	r0, #0
	beq	fail

	ldr	r0, [sp, #64]
	mov	r1, r4
	ldr	r2, [sp, #68]
	blx	_objc_msgSend

	cmp	r0, #0
	beq	fail
	ldr	r1, [sp, #64]
	cmp	r0, r1
	beq	fail

	fldmfdd	sp!, {d0-d7}
	add	sp, sp, #4	@ throw away r0
	ldmfd	sp!, {r1-r4, lr}

	b	_objc_msgSend

fail:
	fldmfdd	sp!, {d0-d7}
	ldmfd	sp!, {r0-r4, lr}
	b	_of_method_not_found

.align 2
_of_forward_stret:
	stmfd	sp!, {r0-r4, lr}
	fstmfdd	sp!, {d0-d7}

	ldr	r4, L_sel_forwardingTargetForSelector_$indirect_L1
L1:
	ldr	r4, [pc, r4]

	mov	r0, r1
	blx	_object_getClass

	mov	r1, r4
	blx	_class_respondsToSelector

	cmp	r0, #0
	beq	fail_stret

	ldr	r0, [sp, #68]
	mov	r1, r4
	ldr	r2, [sp, #72]
	blx	_objc_msgSend

	cmp	r0, #0
	beq	fail_stret
	ldr	r1, [sp, #68]
	cmp	r0, r1
	beq	fail_stret

	mov	r1, r0

	fldmfdd	sp!, {d0-d7}
	ldmfd	sp!, {r0}
	add	sp, sp, #4	@ throw away r1
	ldmfd	sp!, {r2-r4, lr}

	b	_objc_msgSend_stret

fail_stret:
	fldmfdd	sp!, {d0-d7}
	ldmfd	sp!, {r0-r4, lr}
	b	_of_method_not_found_stret

.data_region
L_sel_forwardingTargetForSelector_$indirect_L0:
	.long L_sel_forwardingTargetForSelector_-(L0+8)
L_sel_forwardingTargetForSelector_$indirect_L1:
	.long L_sel_forwardingTargetForSelector_-(L1+8)
.end_data_region
