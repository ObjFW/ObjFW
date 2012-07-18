/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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
	cmpwi	%r3, 0
	beq	ret_nil

	lwz	%r5, 0(%r3)
	lwz	%r5, 32(%r5)

lookup:
	lbz	%r6, 1(%r4)
	lbz	%r7, 2(%r4)
	lbz	%r8, 3(%r4)

	slwi	%r6, %r6, 2
	slwi	%r7, %r7, 2
	slwi	%r8, %r8, 2

	lwzx	%r5, %r5, %r6
	lwzx	%r5, %r5, %r7
	lwzx	%r5, %r5, %r8

	cmpwi	%r5, 0
	beq	forward

	mr	%r3, %r5
	blr

forward:
	b	objc_not_found_handler@plt

objc_msg_lookup_super:
	lwz	%r5, 0(%r3)
	cmpwi	%r5, 0
	beq	ret_nil

	lwz	%r5, 4(%r3)
	lwz	%r5, 32(%r5)

	b	lookup

ret_nil:
	mflr	%r0
	bl	get_pc
	mtlr	%r0
.L1:
	addi	%r3, %r3, nil_method-.L1
	blr

nil_method:
	li	%r3, 0
	blr

get_pc:
	mflr	%r3
	blr

.type objc_msg_lookup, @function
.type objc_msg_lookup_super, @function
.size objc_msg_lookup, forward-objc_msg_lookup
.size objc_msg_lookup_super, ret_nil-objc_msg_lookup_super
