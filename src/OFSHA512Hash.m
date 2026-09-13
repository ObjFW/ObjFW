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

#import "OFSHA512Hash.h"

static const size_t digestSize = 64;

@implementation OFSHA512Hash
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
	_ivars->state[0] = 0x6A09E667F3BCC908;
	_ivars->state[1] = 0xBB67AE8584CAA73B;
	_ivars->state[2] = 0x3C6EF372FE94F82B;
	_ivars->state[3] = 0xA54FF53A5F1D36F1;
	_ivars->state[4] = 0x510E527FADE682D1;
	_ivars->state[5] = 0x9B05688C2B3E6C1F;
	_ivars->state[6] = 0x1F83D9ABFB41BD6B;
	_ivars->state[7] = 0x5BE0CD19137E2179;
}
@end
