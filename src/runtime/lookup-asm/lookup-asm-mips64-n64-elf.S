/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

	ld	$t0, ($a0)
	ld	$t0, 64($t0)

.Lmain_\name:
#ifdef OF_BIG_ENDIAN
# ifdef OF_SELUID24
	lbu	$t1, 5($a1)
# endif
	lbu	$t2, 6($a1)
	lbu	$t3, 7($a1)
#else
# ifdef OF_SELUID24
	lbu	$t1, 2($a1)
# endif
	lbu	$t2, 1($a1)
	lbu	$t3, ($a1)
#endif

#ifdef OF_SELUID24
	sll	$t1, $t1, 3
#endif
	sll	$t2, $t2, 3
	sll	$t3, $t3, 3

#ifdef OF_SELUID24
	daddu	$t0, $t0, $t1
	ld	$t0, ($t0)
#endif
	daddu	$t0, $t0, $t2
	ld	$t0, ($t0)
	daddu	$t0, $t0, $t3
	ld	$t0, ($t0)

	beqz	$t0, 1f

	move	$v0, $t0
	jr	$ra

0:
	lui	$v0, %hi(%neg(%gp_rel(\name)))
	daddiu	$v0, $v0, %lo(%neg(%gp_rel(\name)))
	daddu	$v0, $v0, $t9
	ld	$v0, %got_disp(.LnilMethod)($v0)
	jr	$ra

1:
	lui	$t0, %hi(%neg(%gp_rel(\name)))
	daddiu	$t0, $t0, %lo(%neg(%gp_rel(\name)))
	daddu	$t0, $t0, $t9
	ld	$t9, %got_disp(\notFound)($t0)
	jr	$t9

.LtaggedPointer_\name:
	lui	$t0, %hi(%neg(%gp_rel(\name)))
	daddiu	$t0, $t0, %lo(%neg(%gp_rel(\name)))
	daddu	$t0, $t0, $t9

	ld	$t1, %got_disp(objc_taggedPointerSecret)($t0)
	ld	$t1, 0($t1)
	xor	$t1, $a0, $t1
	and	$t1, $t1, 0xE
	dsll	$t1, $t1, 2

	ld	$t0, %got_disp(objc_taggedPointerClasses)($t0)
	daddu	$t0, $t0, $t1
	ld	$t0, ($t0)
	ld	$t0, 64($t0)

	b	.Lmain_\name
.type \name, %function
.size \name, .-\name
.endm

.macro GENERATE_LOOKUP_SUPER name lookup
\name:
	move	$t0, $a0
	ld	$a0, ($a0)
	beqz	$a0, 0f

	ld	$t0, 8($t0)
	ld	$t0, 64($t0)

	daddiu	$t9, $t9, \lookup-\name
	b	.Lmain_\lookup

0:
	lui	$v0, %hi(%neg(%gp_rel(\name)))
	daddiu	$v0, $v0, %lo(%neg(%gp_rel(\name)))
	daddu	$v0, $v0, $t9
	ld	$v0, %got_disp(.LnilMethod)($v0)
	jr	$ra
.type \name, %function
.size \name, .-\name
.endm

GENERATE_LOOKUP objc_msg_lookup objc_methodNotFound
GENERATE_LOOKUP objc_msg_lookup_stret objc_methodNotFound_stret
GENERATE_LOOKUP_SUPER objc_msg_lookup_super objc_msg_lookup
GENERATE_LOOKUP_SUPER objc_msg_lookup_super_stret objc_msg_lookup_stret

.LnilMethod:
	move	$v0, $zero
	jr	$ra

#if defined(OF_LINUX) || defined(OF_HAIKU) || defined(OF_HURD)
.section .note.GNU-stack, "", %progbits
#endif
