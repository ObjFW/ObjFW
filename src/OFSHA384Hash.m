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

#import "OFSHA384Hash.h"

static const size_t digestSize = 48;

@implementation OFSHA384Hash
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
	_iVars->state[0] = 0xCBBB9D5DC1059ED8;
	_iVars->state[1] = 0x629A292A367CD507;
	_iVars->state[2] = 0x9159015A3070DD17;
	_iVars->state[3] = 0x152FECD8F70E5939;
	_iVars->state[4] = 0x67332667FFC00B31;
	_iVars->state[5] = 0x8EB44A8768581511;
	_iVars->state[6] = 0xDB0C2E0D64F98FA7;
	_iVars->state[7] = 0x47B5481DBEFA4FA4;
}
@end
