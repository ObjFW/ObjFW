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

#include "config.h"

.globl objc_msg_lookup
.globl objc_msg_lookup_super

.section .text
objc_msg_lookup:
	beqz	$a0, ret_nil

	lw	$t0, 0($a0)
	lw	$t0, 32($t0)

lookup:
#if defined(_MIPSEL)
# ifdef OF_SELUID24
	lbu	$t1, 2($a1)
# endif
	lbu	$t2, 1($a1)
	lbu	$t3, 0($a1)
#elif defined(_MIPSEB)
# ifdef OF_SELUID24
	lbu	$t1, 1($a1)
# endif
	lbu	$t2, 2($a1)
	lbu	$t3, 3($a1)
#else
# error Neither _MIPSEL nor _MIPSEB defined!
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

#ifdef __PIC__
	beqz	$t0, forward
#else
	beqz	$t0, objc_not_found_handler
#endif

	move	$v0, $t0
	j	$ra

ret_nil:
#ifdef __PIC__
	addiu	$v0, $t9, nil_method-objc_msg_lookup
#else
	la	$v0, nil_method
#endif
	j	$ra

#ifdef __PIC__
forward:
	lui	$gp, %hi(_gp_disp)
	addiu	$gp, $gp, %lo(_gp_disp)
	addu	$gp, $gp, $t9
	addiu	$gp, $gp, forward-objc_msg_lookup

	lw	$t9, %call16(objc_not_found_handler)($gp)
	jr	$t9
#endif
.type objc_msg_lookup, %function
.size objc_msg_lookup, .-objc_msg_lookup

objc_msg_lookup_super:
	lw	$t0, 0($a0)
	beqz	$t0, ret_nil

	lw	$t0, 4($a0)
	lw	$t0, 32($t0)

	b	lookup
.type objc_msg_lookup_super, %function
.size objc_msg_lookup_super, .-objc_msg_lookup_super

nil_method:
	move	$v0, $zero
	j	$ra

#ifdef __linux__
.section .note.GNU-stack, "", %progbits
#endif
