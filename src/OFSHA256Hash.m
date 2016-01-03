/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#import "OFSHA256Hash.h"

@implementation OFSHA256Hash
+ (size_t)digestSize
{
	return 32;
}

- (void)OF_resetState
{
	_state[0] = 0x6A09E667;
	_state[1] = 0xBB67AE85;
	_state[2] = 0x3C6EF372;
	_state[3] = 0xA54FF53A;
	_state[4] = 0x510E527F;
	_state[5] = 0x9B05688C;
	_state[6] = 0x1F83D9AB;
	_state[7] = 0x5BE0CD19;
}
@end
