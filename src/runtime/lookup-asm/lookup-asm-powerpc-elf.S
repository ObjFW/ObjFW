/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

	andi.	%r0, %r3, 1
	bne-	.Ltagged_pointer_\name

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
#ifdef OF_PIC
	stwu	%r1, -16(%r1)
	mflr	%r0	
	stw	%r0, 20(%r1)
	stw	%r30, 8(%r1)

	bl	0f
0:
	mflr	%r30
	addis	%r30, %r30, .Lbiased_got2-0b@ha
	addi	%r30, %r30, .Lbiased_got2-0b@l

	lwz	%r0, .Lgot_\not_found-.Lbiased_got2(%r30)
	mtctr	%r0

	lwz	%r30, 8(%r1)
	lwz	%r0, 20(%r1)
	addi	%r1, %r1, 16
	mtlr	%r0

	bctr
#else
	b	\not_found
#endif

.Ltagged_pointer_\name:
#if defined(OF_PIC)
	mflr	%r7
	bl	0f
0:
	mflr	%r6
	mtlr	%r7
	addis	%r6, %r6, .Lbiased_got2-0b@ha
	addi	%r6, %r6, .Lbiased_got2-0b@l

	lwz	%r5, .Lgot_objc_tagged_pointer_secret-.Lbiased_got2(%r6)
	lwz	%r5, 0(%r5)
#elif defined(OF_BASEREL)
	addis	%r5, %r13, objc_tagged_pointer_secret@drel@ha
	lwz	%r5, objc_tagged_pointer_secret@drel@l(%r5)
#else
	lis	%r5, objc_tagged_pointer_secret@ha
	lwz	%r5, objc_tagged_pointer_secret@l(%r5)
#endif
	xor	%r5, %r3, %r5
	rlwinm	%r5, %r5, 1, 0x1C

#if defined(OF_PIC)
	lwz	%r6, .Lgot_objc_tagged_pointer_classes-.Lbiased_got2(%r6)
#elif defined(OF_BASEREL)
	addis	%r6, %r13, objc_tagged_pointer_classes@drel@ha
	addi	%r6, %r6, objc_tagged_pointer_classes@drel@l
#else
	lis	%r6, objc_tagged_pointer_classes@ha
	addi	%r6, %r6, objc_tagged_pointer_classes@l
#endif
	lwzx	%r5, %r6, %r5
	lwz	%r5, 32(%r5)

	b	.Lmain_\name
.type \name, @function
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
.type \name, @function
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

#ifdef OF_PIC
.section .got2, "aw"
.Lbiased_got2 = .+0x8000
.Lgot_objc_method_not_found:
	.long objc_method_not_found
.Lgot_objc_method_not_found_stret:
	.long objc_method_not_found_stret
.Lgot_objc_tagged_pointer_secret:
	.long objc_tagged_pointer_secret
.Lgot_objc_tagged_pointer_classes:
	.long objc_tagged_pointer_classes
#endif

#ifdef OF_LINUX
.section .note.GNU-stack, "", @progbits
#endif
