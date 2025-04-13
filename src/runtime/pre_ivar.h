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

enum objc_object_info {
	OBJC_OBJECT_INFO_WEAK_REFERENCES = 0x1,
	OBJC_OBJECT_INFO_ASSOCIATIONS = 0x02
};

struct objc_pre_ivars {
#ifdef OF_MSDOS
	ptrdiff_t offset;
#endif
	volatile int retainCount;
	volatile unsigned int info;
#if !defined(OF_HAVE_ATOMIC_OPS) && !defined(OF_AMIGAOS)
	OFSpinlock retainCountSpinlock;
#endif
};

#define OBJC_PRE_IVARS_ALIGNED \
	OFRoundUpToPowerOf2(sizeof(struct objc_pre_ivars), OF_BIGGEST_ALIGNMENT)
#define OBJC_PRE_IVARS(obj)					\
	((struct objc_pre_ivars *)(void *)((char *)obj -	\
	    OBJC_PRE_IVARS_ALIGNED))
