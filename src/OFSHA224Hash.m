/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#import "OFSHA224Hash.h"

static const size_t digestSize = 28;

@implementation OFSHA224Hash
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
	_ivars->state[0] = 0xC1059ED8;
	_ivars->state[1] = 0x367CD507;
	_ivars->state[2] = 0x3070DD17;
	_ivars->state[3] = 0xF70E5939;
	_ivars->state[4] = 0xFFC00B31;
	_ivars->state[5] = 0x68581511;
	_ivars->state[6] = 0x64F98FA7;
	_ivars->state[7] = 0xBEFA4FA4;
}
@end
