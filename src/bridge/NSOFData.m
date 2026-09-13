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

#import "NSOFData.h"
#import "OFData.h"

#import "OFOutOfRangeException.h"

@implementation NSOFData
- (instancetype)initWithOFData: (OFData *)data
{
	if ((self = [super init]) != nil)
		_data = objc_retain(data);

	return self;
}

- (void)dealloc
{
	objc_release(_data);

	[super dealloc];
}

- (const void *)bytes
{
	return _data.items;
}

- (NSUInteger)length
{
	size_t length = _data.count * _data.itemSize;

	if (length > NSUIntegerMax)
		@throw [OFOutOfRangeException exception];

	return length;
}
@end
