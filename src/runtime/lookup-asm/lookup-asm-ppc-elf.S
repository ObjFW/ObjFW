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
	cmpwi	%r3, 0
	beq-	ret_nil

	lwz	%r5, 0(%r3)
	lwz	%r5, 32(%r5)

.Lmain_\name:
	lwz	%r8, 0(%r4)
#ifdef OF_SELUID24
	rlwinm	%r6, %r8, 18, 0x3FC
#endif
	rlwinm	%r7, %r8, 26, 0x3FC
	rlwinm	%r8, %r8, 2, 0x3FC

#ifdef OF_SELUID24
	lwzx	%r5, %r5, %r6
#endif
	lwzx	%r5, %r5, %r7
	lwzx	%r5, %r5, %r8

	cmpwi	%r5, 0
	beq-	0f

	mr	%r3, %r5
	blr

0:
	b	\not_found@plt
.type \name, %function
.size \name, .-\name
.endm

.macro generate_lookup_super name lookup
\name:
	mr	%r5, %r3
	lwz	%r3, 0(%r3)
	cmpwi	%r3, 0
	beq-	ret_nil

	lwz	%r5, 4(%r5)
	lwz	%r5, 32(%r5)

	b	.Lmain_\lookup
.type \name, %function
.size \name, .-\name
.endm

generate_lookup objc_msg_lookup objc_method_not_found
generate_lookup objc_msg_lookup_stret objc_method_not_found_stret
generate_lookup_super objc_msg_lookup_super objc_msg_lookup
generate_lookup_super objc_msg_lookup_super_stret objc_msg_lookup_stret

ret_nil:
	mflr	%r0
	bl	get_pc
	mtlr	%r0
0:
	addi	%r3, %r3, nil_method-0b
	blr

nil_method:
	li	%r3, 0
	blr

get_pc:
	mflr	%r3
	blr

#ifdef OF_LINUX
.section .note.GNU-stack, "", %progbits
#endif
