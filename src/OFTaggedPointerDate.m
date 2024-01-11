/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFTaggedPointerDate.h"

#if UINTPTR_MAX == UINT64_MAX
static int dateTag;

@implementation OFTaggedPointerDate
+ (void)initialize
{
	if (self == [OFTaggedPointerDate class])
		dateTag = objc_registerTaggedPointerClass(self);
}

+ (OFTaggedPointerDate *)dateWithUInt64TimeIntervalSince1970: (uint64_t)value
{
	return objc_createTaggedPointer(dateTag, value & ~(UINT64_C(4) << 60));
}

- (OFTimeInterval)timeIntervalSince1970
{
	uint64_t value = (uint64_t)object_getTaggedPointerValue(self);

	value |= UINT64_C(4) << 60;

	return OFFromBigEndianDouble(OFRawUInt64ToDouble(OFToBigEndian64(
	    value)));
}

OF_SINGLETON_METHODS
@end
#endif
