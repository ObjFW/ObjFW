/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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
	_iVars->state[0] = 0xC1059ED8;
	_iVars->state[1] = 0x367CD507;
	_iVars->state[2] = 0x3070DD17;
	_iVars->state[3] = 0xF70E5939;
	_iVars->state[4] = 0xFFC00B31;
	_iVars->state[5] = 0x68581511;
	_iVars->state[6] = 0x64F98FA7;
	_iVars->state[7] = 0xBEFA4FA4;
}
@end
