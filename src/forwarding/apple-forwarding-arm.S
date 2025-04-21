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

.globl _OFForward
.globl _OFForward_stret

.section __TEXT, __objc_methname, cstring_literals
Lstr_forwardingTargetForSelector_:
	.asciz "forwardingTargetForSelector:"

.section __DATA, __objc_selrefs, literal_pointers, no_dead_strip
Lsel_forwardingTargetForSelector_:
	.long str_forwardingTargetForSelector_

.section __DATA, __objc_imageinfo, regular, no_dead_strip
	.long 0, 0

.section __TEXT, __text, regular, pure_instructions
.arm
.align 2
_OFForward:
	stmfd	sp!, {r0-r4, lr}
	vstmdb	sp!, {d0-d7}

	ldr	r4, Lsel_forwardingTargetForSelector_$indirect_L0
L0:
	ldr	r4, [pc, r4]

	blx	_object_getClass

	mov	r1, r4
	blx	_class_respondsToSelector

	cmp	r0, #0
	beq	0f

	ldr	r0, [sp, #64]
	mov	r1, r4
	ldr	r2, [sp, #68]
	blx	_objc_msgSend

	cmp	r0, #0
	beq	0f
	ldr	r1, [sp, #64]
	cmp	r0, r1
	beq	0f

	vldmia	sp!, {d0-d7}
	add	sp, sp, #4	@ throw away r0
	ldmfd	sp!, {r1-r4, lr}

	b	_objc_msgSend

0:
	vldmia	sp!, {d0-d7}
	ldmfd	sp!, {r0-r4, lr}
	b	_OFMethodNotFound

.data_region
Lsel_forwardingTargetForSelector_$indirect_L0:
	.long Lsel_forwardingTargetForSelector_-(L0+8)
.end_data_region

.align 2
_OFForward_stret:
	stmfd	sp!, {r0-r4, lr}
	vstmdb	sp!, {d0-d7}

	ldr	r4, Lsel_forwardingTargetForSelector_$indirect_L1
L1:
	ldr	r4, [pc, r4]

	mov	r0, r1
	blx	_object_getClass

	mov	r1, r4
	blx	_class_respondsToSelector

	cmp	r0, #0
	beq	0f

	ldr	r0, [sp, #68]
	mov	r1, r4
	ldr	r2, [sp, #72]
	blx	_objc_msgSend

	cmp	r0, #0
	beq	0f
	ldr	r1, [sp, #68]
	cmp	r0, r1
	beq	0f

	mov	r1, r0

	vldmia	sp!, {d0-d7}
	ldmfd	sp!, {r0}
	add	sp, sp, #4	@ throw away r1
	ldmfd	sp!, {r2-r4, lr}

	b	_objc_msgSend_stret

0:
	vldmia	sp!, {d0-d7}
	ldmfd	sp!, {r0-r4, lr}
	b	_OFMethodNotFound_stret

.data_region
Lsel_forwardingTargetForSelector_$indirect_L1:
	.long Lsel_forwardingTargetForSelector_-(L1+8)
.end_data_region
