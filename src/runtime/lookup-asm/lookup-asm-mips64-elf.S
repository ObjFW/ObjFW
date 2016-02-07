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

	ld	$t0, 0($a0)
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
	lbu	$t3, 0($a1)
#endif

#ifdef OF_SELUID24
	sll	$t1, $t1, 3
#endif
	sll	$t2, $t2, 3
	sll	$t3, $t3, 3

#ifdef OF_SELUID24
	daddu	$t0, $t0, $t1
	ld	$t0, 0($t0)
#endif
	daddu	$t0, $t0, $t2
	ld	$t0, 0($t0)
	daddu	$t0, $t0, $t3
	ld	$t0, 0($t0)

	beqz	$t0, 1f

	move	$v0, $t0
	j	$ra

0:
	lui	$v0, %hi(%neg(%gp_rel(\name)))
	daddu	$v0, $v0, $t9
	daddiu	$v0, $v0, %lo(%neg(%gp_rel(\name)))
	ld	$v0, %got_disp(nil_method)($v0)
	j	$ra

1:
	daddiu	$sp, $sp, -32
	sd	$gp, 16($sp)
	lui	$gp, %hi(%neg(%gp_rel(\name)))
	daddu	$gp, $gp, $t9
	daddiu	$gp, $gp, %lo(%neg(%gp_rel(\name)))
	sd	$ra, 24($sp)

	jal	\not_found

	ld	$ra, 24($sp)
	ld	$gp, 16($sp)
	daddiu	$sp, $sp, 32
	j	$ra
.type \name, %function
.size \name, .-\name
.endm

.macro generate_lookup_super name lookup
\name:
	ld	$t0, 0($a0)
	beqz	$t0, 0f

	ld	$t0, 8($a0)
	ld	$t0, 64($t0)

	b	.Lmain_\lookup

0:
	lui	$v0, %hi(%neg(%gp_rel(\name)))
	daddu	$v0, $v0, $t9
	daddiu	$v0, $v0, %lo(%neg(%gp_rel(\name)))
	ld	$v0, %got_disp(nil_method)($v0)
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
