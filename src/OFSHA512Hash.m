/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
	_iVars->state[0] = 0x6A09E667F3BCC908;
	_iVars->state[1] = 0xBB67AE8584CAA73B;
	_iVars->state[2] = 0x3C6EF372FE94F82B;
	_iVars->state[3] = 0xA54FF53A5F1D36F1;
	_iVars->state[4] = 0x510E527FADE682D1;
	_iVars->state[5] = 0x9B05688C2B3E6C1F;
	_iVars->state[6] = 0x1F83D9ABFB41BD6B;
	_iVars->state[7] = 0x5BE0CD19137E2179;
}
@end
