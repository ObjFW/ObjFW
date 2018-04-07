/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#include "config.h"

#import "OFSHA224Hash.h"

@implementation OFSHA224Hash
+ (size_t)digestSize
{
	return 28;
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
