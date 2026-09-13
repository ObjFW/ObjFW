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

	return OFFromBigEndianDouble(OFBitConvertUInt64ToDouble(OFToBigEndian64(
	    value)));
}

OF_SINGLETON_METHODS
@end
#endif
