/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#define returnTypeNormal	0
#define returnTypeStret		1
#define returnTypeX87		2
#define returnTypeComplexX87	3
#define returnTypeJmp		4
#define returnTypeJmpStret	5

#define numGPRIn	6
#define numGPROut	2
#define numSSEInOut	8
#define numX87Out	2

#define offsetGPRIn		0
#define offsetGPROut		(offsetGPRIn + numGPRIn * 8)
#define offsetSSEInOut		(offsetGPROut + numGPROut * 8)
#define offsetX87Out		(offsetSSEInOut + numSSEInOut * 16)
#define offsetNumSSEUsed	(offsetX87Out + numX87Out * 16)
#define offsetReturnType	(offsetNumSSEUsed + 1)
#define offsetStackSize		(offsetReturnType + 7)
#define offsetStack		(offsetStackSize + 8)
