/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import <Foundation/NSData.h>

#import "OFNSData.h"

@implementation OFNSData
- (instancetype)initWithNSData: (NSData *)data
{
	self = [super init];

	_data = [data retain];

	return self;
}

- (void)dealloc
{
	[_data release];

	[super dealloc];
}

- (size_t)count
{
	return _data.length;
}

- (size_t)itemSize
{
	return 1;
}

- (const void *)items
{
	return _data.bytes;
}
@end
