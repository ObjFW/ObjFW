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

#include "config.h"

#import "OFSubdata.h"

@implementation OFSubdata
- (instancetype)initWithData: (OFData *)data range: (OFRange)range
{
	self = [super init];

	@try {
		/* Should usually be retain, as it's useless with a copy */
		_data = [data copy];
		_range = range;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_data);

	[super dealloc];
}

- (size_t)count
{
	return _range.length;
}

- (size_t)itemSize
{
	return _data.itemSize;
}

- (const void *)items
{
	return (const unsigned char *)_data.items +
	    (_range.location * _data.itemSize);
}
@end
