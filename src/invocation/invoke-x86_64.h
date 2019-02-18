/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#define RETURN_TYPE_NORMAL	0
#define RETURN_TYPE_STRET	1
#define RETURN_TYPE_X87		2
#define RETURN_TYPE_COMPLEX_X87	3
#define RETURN_TYPE_JMP		4
#define RETURN_TYPE_JMP_STRET	5

#define NUM_GPR_IN	6
#define NUM_GPR_OUT	2
#define NUM_SSE_INOUT	8
#define NUM_X87_OUT	2

#define OFFSET_GPR_IN		0
#define OFFSET_GPR_OUT		(OFFSET_GPR_IN + NUM_GPR_IN * 8)
#define OFFSET_SSE_INOUT	(OFFSET_GPR_OUT + NUM_GPR_OUT * 8)
#define OFFSET_X87_OUT		(OFFSET_SSE_INOUT + NUM_SSE_INOUT * 16)
#define OFFSET_NUM_SSE_USED	(OFFSET_X87_OUT + NUM_X87_OUT * 16)
#define OFFSET_RETURN_TYPE	(OFFSET_NUM_SSE_USED + 1)
#define OFFSET_STACK_SIZE	(OFFSET_RETURN_TYPE + 7)
#define OFFSET_STACK		(OFFSET_STACK_SIZE + 8)
