/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
 *   Jonathan Schleifer <js@heap.zone>
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
.macro generate_lookup name not_found
\name:
	beqz	$a0, 0f

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
	beqz	$t0, \not_found
#endif

	move	$v0, $t0
	j	$ra

0:
#ifdef OF_PIC
	addiu	$v0, $t9, nil_method-\name
#else
	la	$v0, nil_method
#endif
	j	$ra

#ifdef OF_PIC
1:
	lui	$gp, %hi(_gp_disp)
	addiu	$gp, $gp, %lo(_gp_disp)
	addu	$gp, $gp, $t9
	addiu	$gp, $gp, 1b-\name

	lw	$t9, %call16(\not_found)($gp)
	jr	$t9
#endif
.type \name, %function
.size \name, .-\name
.endm

.macro generate_lookup_super name lookup
\name:
	lw	$t0, 0($a0)
	beqz	$t0, 0f

	lw	$t0, 4($a0)
	lw	$t0, 32($t0)

	b	.Lmain_\lookup

0:
#ifdef OF_PIC
	addiu	$v0, $t9, nil_method-\name
#else
	la	$v0, nil_method
#endif
	j	$ra
.type \name, %function
.size \name, .-\name
.endm

generate_lookup objc_msg_lookup objc_method_not_found
generate_lookup objc_msg_lookup_stret objc_method_not_found_stret
generate_lookup_super objc_msg_lookup_super objc_msg_lookup
generate_lookup_super objc_msg_lookup_super_stret objc_msg_lookup_stret

nil_method:
	move	$v0, $zero
	j	$ra

#ifdef OF_LINUX
.section .note.GNU-stack, "", %progbits
#endif
