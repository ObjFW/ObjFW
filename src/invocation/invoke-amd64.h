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
