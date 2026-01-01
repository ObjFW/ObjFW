/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#ifdef HAVE_VFP2
.fpu vfp
#endif

.globl _OFForward
.globl _OFForward_stret
.internal _OFForward
.internal _OFForward_stret

.section .text
_OFForward:
#ifdef HAVE_VFP2
	vstmdb	sp!, {d0-d7}
#endif
	stmfd	sp!, {r0-r4, lr}

	ldr	r4, .Lsel_forwardingTargetForSelector_$indirect_.L0
.L0:
	add	r4, pc

	bl	object_getClass(PLT)

	mov	r1, r4
	bl	class_respondsToSelector(PLT)

	cmp	r0, #0
	beq	0f

	ldr	r0, [sp, #0]
	mov	r1, r4
	bl	objc_msg_lookup(PLT)

	mov	r12, r0
	ldr	r0, [sp, #0]
	mov	r1, r4
	ldr	r2, [sp, #4]
#ifdef HAVE_BLX
	blx	r12
#else
	mov	lr, pc
	bx	r12
#endif

	cmp	r0, #0
	beq	0f
	ldr	r1, [sp, #0]
	cmp	r0, r1
	beq	0f

	str	r0, [sp, #0]
	ldr	r1, [sp, #4]
	bl	objc_msg_lookup(PLT)

	mov	r12, r0
	ldmfd	sp!, {r0-r4, lr}
#ifdef HAVE_VFP2
	vldmia	sp!, {d0-d7}
#endif

	bx	r12

0:
	ldmfd	sp!, {r0-r4, lr}
#ifdef HAVE_VFP2
	vldmia	sp!, {d0-d7}
#endif
	b	OFMethodNotFound(PLT)
.type _OFForward, %function
.size _OFForward, .-_OFForward

_OFForward_stret:
#ifdef HAVE_VFP2
	vstmdb	sp!, {d0-d7}
#endif
	stmfd	sp!, {r0-r4, lr}

	ldr	r4, .Lsel_forwardingTargetForSelector_$indirect_.L1
.L1:
	add	r4, pc

	mov	r0, r1
	bl	object_getClass(PLT)

	mov	r1, r4
	bl	class_respondsToSelector(PLT)

	cmp	r0, #0
	beq	0f

	ldr	r0, [sp, #4]
	mov	r1, r4
	bl	objc_msg_lookup(PLT)

	mov	r12, r0
	ldr	r0, [sp, #4]
	mov	r1, r4
	ldr	r2, [sp, #8]
#ifdef HAVE_BLX
	blx	r12
#else
	mov	lr, pc
	bx	r12
#endif

	cmp	r0, #0
	beq	0f
	ldr	r1, [sp, #4]
	cmp	r0, r1
	beq	0f

	str	r0, [sp, #4]
	ldr	r1, [sp, #8]
	bl	objc_msg_lookup_stret(PLT)

	mov	r12, r0
	ldmfd	sp!, {r0-r4, lr}
#ifdef HAVE_VFP2
	vldmia	sp!, {d0-d7}
#endif

	bx	r12

0:
	ldmfd	sp!, {r0-r4, lr}
#ifdef HAVE_VFP2
	vldmia	sp!, {d0-d7}
#endif
	b	OFMethodNotFound_stret(PLT)
.type _OFForward_stret, %function
.size _OFForward_stret, .-_OFForward_stret

.Linit:
	ldr	r0, .Lmodule$indirect_.L2
.L2:
	add	r0, pc
	b	__objc_exec_class(PLT)

.Lsel_forwardingTargetForSelector_$indirect_.L0:
	.long .Lsel_forwardingTargetForSelector_-(.L0+8)
.Lsel_forwardingTargetForSelector_$indirect_.L1:
	.long .Lsel_forwardingTargetForSelector_-(.L1+8)
.Lmodule$indirect_.L2:
	.long .Lmodule-(.L2+8)

.section .init_array, "aw", %init_array
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
