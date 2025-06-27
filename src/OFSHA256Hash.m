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

#include "config.h"

#import "OFSHA256Hash.h"

static const size_t digestSize = 32;

@implementation OFSHA256Hash
+ (size_t)digestSize
{
	return digestSize;
}

- (size_t)digestSize
{
	return digestSize;
}

- (void)of_resetState
{
	_iVars->state[0] = 0x6A09E667;
	_iVars->state[1] = 0xBB67AE85;
	_iVars->state[2] = 0x3C6EF372;
	_iVars->state[3] = 0xA54FF53A;
	_iVars->state[4] = 0x510E527F;
	_iVars->state[5] = 0x9B05688C;
	_iVars->state[6] = 0x1F83D9AB;
	_iVars->state[7] = 0x5BE0CD19;
}
@end
