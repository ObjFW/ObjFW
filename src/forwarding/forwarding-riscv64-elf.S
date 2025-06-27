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

_OFForward:
	addi	sp, sp, -144
	sd	ra, 8(sp)

	sd	a0, 16(sp)
	sd	a1, 24(sp)
	sd	a2, 32(sp)
	sd	a3, 40(sp)
	sd	a4, 48(sp)
	sd	a5, 56(sp)
	sd	a6, 64(sp)
	sd	a7, 72(sp)

	fsd	fa0, 80(sp)
	fsd	fa1, 88(sp)
	fsd	fa2, 96(sp)
	fsd	fa3, 104(sp)
	fsd	fa4, 112(sp)
	fsd	fa5, 120(sp)
	fsd	fa6, 128(sp)
	fsd	fa7, 136(sp)

	call	object_getClass@plt

	lla	a1, .Lsel_forwardingTargetForSelector_
	call	class_respondsToSelector@plt
	beqz	a0, 0f

	ld	a0, 16(sp)
	lla	a1, .Lsel_forwardingTargetForSelector_
	call	objc_msg_lookup@plt

	mv	t0, a0
	ld	a0, 16(sp)
	lla	a1, .Lsel_forwardingTargetForSelector_
	ld	a2, 24(sp)
	jalr	t0

	beqz	a0, 0f
	ld	t0, 16(sp)
	beq	a0, t0, 0f

	sd	a0, 16(sp)

	ld	a1, 24(sp)
	call	objc_msg_lookup@plt
	mv	t0, a0

	fld	fa7, 136(sp)
	fld	fa6, 128(sp)
	fld	fa5, 120(sp)
	fld	fa4, 112(sp)
	fld	fa3, 104(sp)
	fld	fa2, 96(sp)
	fld	fa1, 88(sp)
	fld	fa0, 80(sp)

	ld	a7, 72(sp)
	ld	a6, 64(sp)
	ld	a5, 56(sp)
	ld	a4, 48(sp)
	ld	a3, 40(sp)
	ld	a2, 32(sp)
	ld	a1, 24(sp)
	ld	a0, 16(sp)

	ld	ra, 8(sp)

	add	sp, sp, 144

	jr	t0

0:
	ld	a1, 24(sp)
	ld	a0, 16(sp)

	ld	ra, 8(sp)

	add	sp, sp, 144

	tail	OFMethodNotFound@plt
.type _OFForward, @function
.size _OFForward, .-_OFForward

_OFForward_stret:
	addi	sp, sp, -144
	sd	ra, 8(sp)

	sd	a0, 16(sp)
	sd	a1, 24(sp)
	sd	a2, 32(sp)
	sd	a3, 40(sp)
	sd	a4, 48(sp)
	sd	a5, 56(sp)
	sd	a6, 64(sp)
	sd	a7, 72(sp)

	fsd	fa0, 80(sp)
	fsd	fa1, 88(sp)
	fsd	fa2, 96(sp)
	fsd	fa3, 104(sp)
	fsd	fa4, 112(sp)
	fsd	fa5, 120(sp)
	fsd	fa6, 128(sp)
	fsd	fa7, 136(sp)

	mv	a0, a1
	call	object_getClass@plt

	lla	a1, .Lsel_forwardingTargetForSelector_
	call	class_respondsToSelector@plt
	beqz	a0, 0f

	ld	a0, 24(sp)
	lla	a1, .Lsel_forwardingTargetForSelector_
	call	objc_msg_lookup@plt

	mv	t0, a0
	ld	a0, 24(sp)
	lla	a1, .Lsel_forwardingTargetForSelector_
	ld	a2, 32(sp)
	jalr	t0

	beqz	a0, 0f
	ld	t0, 24(sp)
	beq	a0, t0, 0f

	sd	a0, 24(sp)

	ld	a1, 32(sp)
	call	objc_msg_lookup_stret@plt
	mv	t0, a0

	fld	fa7, 136(sp)
	fld	fa6, 128(sp)
	fld	fa5, 120(sp)
	fld	fa4, 112(sp)
	fld	fa3, 104(sp)
	fld	fa2, 96(sp)
	fld	fa1, 88(sp)
	fld	fa0, 80(sp)

	ld	a7, 72(sp)
	ld	a6, 64(sp)
	ld	a5, 56(sp)
	ld	a4, 48(sp)
	ld	a3, 40(sp)
	ld	a2, 32(sp)
	ld	a1, 24(sp)
	ld	a0, 16(sp)

	ld	ra, 8(sp)

	add	sp, sp, 144

	jr	t0

0:
	ld	a2, 32(sp)
	ld	a1, 24(sp)
	ld	a0, 16(sp)

	ld	ra, 8(sp)

	add	sp, sp, 144

	tail	OFMethodNotFound_stret@plt
.type _OFForward_stret, @function
.size _OFForward_stret, .-_OFForward_stret

.Linit:
	lla	a0, .Lmodule
	tail	__objc_exec_class@plt

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
