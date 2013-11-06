/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFDeflate64Stream.h"

static const uint_fast8_t numDistanceCodes = 32;
static const uint8_t lengthCodes[29] = {
	/* indices are -257, values -3 */
	0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40, 48, 56,
	64, 80, 96, 112, 128, 160, 192, 224, 0
};
static const uint8_t lengthExtraBits[29] = {
	0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4,
	5, 5, 5, 5, 16
};
static const uint16_t distanceCodes[32] = {
	1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385,
	513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577,
	32769, 49153
};
static const uint8_t distanceExtraBits[32] = {
	0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10,
	10, 11, 11, 12, 12, 13, 13, 14, 14
};

@implementation OFDeflate64Stream
- initWithStream: (OFStream*)stream
{
	self = [super initWithStream: stream];

	_slidingWindowMask = 0xFFFF;
	_codes.numDistanceCodes = numDistanceCodes;
	_codes.lengthCodes = lengthCodes;
	_codes.lengthExtraBits = lengthExtraBits;
	_codes.distanceCodes = distanceCodes;
	_codes.distanceExtraBits = distanceExtraBits;

	return self;
}
@end
