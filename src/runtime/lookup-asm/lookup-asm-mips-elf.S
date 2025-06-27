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

.globl objc_msg_lookup
.globl objc_msg_lookup_stret
.globl objc_msg_lookup_super
.globl objc_msg_lookup_super_stret

.section .text
.macro GENERATE_LOOKUP name notFound
\name:
	beqz	$a0, 0f

	andi	$t0, $a0, 1
	bnez	$t0, .LtaggedPointer_\name

	lw	$t0, 0($a0)
	lw	$t0, 32($t0)

.Lmain_\name:
#ifdef OF_BIG_ENDIAN
# ifdef OF_SELUID24
	lbu	$t1, 1($a1)
# endif
	lbu	$t2, 2($a1)
	lbu	$t3, 3($a1)
#else
# ifdef OF_SELUID24
	lbu	$t1, 2($a1)
# endif
	lbu	$t2, 1($a1)
	lbu	$t3, 0($a1)
#endif

#ifdef OF_SELUID24
	sll	$t1, $t1, 2
#endif
	sll	$t2, $t2, 2
	sll	$t3, $t3, 2

#ifdef OF_SELUID24
	addu	$t0, $t0, $t1
	lw	$t0, 0($t0)
#endif
	addu	$t0, $t0, $t2
	lw	$t0, 0($t0)
	addu	$t0, $t0, $t3
	lw	$t0, 0($t0)

#ifdef OF_PIC
	beqz	$t0, 1f
#else
	beqz	$t0, \notFound
#endif

	move	$v0, $t0
	jr	$ra

0:
#ifdef OF_PIC
	addiu	$v0, $t9, .LnilMethod-\name
#else
	la	$v0, .LnilMethod
#endif
	jr	$ra

#ifdef OF_PIC
1:
	lui	$gp, %hi(_gp_disp)
	addiu	$gp, $gp, %lo(_gp_disp)
	addu	$gp, $gp, $t9
	addiu	$gp, $gp, 1b-\name

	lw	$t9, %call16(\notFound)($gp)
	jr	$t9
#endif

.LtaggedPointer_\name:
#ifdef OF_PIC
0:
	lui	$gp, %hi(_gp_disp)
	addiu	$gp, $gp, %lo(_gp_disp)
	addu	$gp, $gp, $t9
	addiu	$gp, $gp, 0b-\name

	lw	$t0, %got(_objc_taggedPointerSecret)($gp)
#else
	la	$t0, _objc_taggedPointerSecret
#endif
	lw	$t0, 0($t0)
	xor	$t0, $a0, $t0
	and	$t0, $t0, 0xE
	sll	$t0, $t0, 1

#ifdef OF_PIC
	lw	$t1, %got(_objc_taggedPointerClasses)($gp)
#else
	la	$t1, _objc_taggedPointerClasses
#endif
	addu	$t0, $t1, $t0
	ld	$t0, ($t0)
	ld	$t0, 32($t0)

	b	.Lmain_\name
.type \name, %function
.size \name, .-\name
.endm

.macro GENERATE_LOOKUP_SUPER name lookup
\name:
	move	$t0, $a0
	lw	$a0, 0($a0)
	beqz	$a0, 0f

	lw	$t0, 4($t0)
	lw	$t0, 32($t0)

	addiu	$t9, $t9, \lookup-\name
	b	.Lmain_\lookup

0:
#ifdef OF_PIC
	addiu	$v0, $t9, .LnilMethod-\name
#else
	la	$v0, .LnilMethod
#endif
	jr	$ra
.type \name, %function
.size \name, .-\name
.endm

GENERATE_LOOKUP objc_msg_lookup _objc_methodNotFound
GENERATE_LOOKUP objc_msg_lookup_stret _objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER objc_msg_lookup_super objc_msg_lookup
GENERATE_LOOKUP_SUPER objc_msg_lookup_super_stret objc_msg_lookup_stret

.LnilMethod:
	move	$v0, $zero
	jr	$ra

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", %progbits
#endif
