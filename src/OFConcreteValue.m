/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFConcreteValue.h"
#import "OFMethodSignature.h"
#import "OFString.h"

#import "OFOutOfRangeException.h"

@implementation OFConcreteValue
- (instancetype)initWithBytes: (const void *)bytes
		     objCType: (const char *)objCType
{
	self = [super initWithBytes: bytes objCType: objCType];

	@try {
		_size = OFSizeOfTypeEncoding(objCType);
		_objCType = _OFStrDup(objCType);
		_bytes = OFAllocMemory(1, _size);
		memcpy(_bytes, bytes, _size);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	OFFreeMemory(_bytes);
	OFFreeMemory(_objCType);

	[super dealloc];
}

- (const char *)objCType
{
	return _objCType;
}

- (void)getValue: (void *)value size: (size_t)size
{
	if (size != _size)
		@throw [OFOutOfRangeException exception];

	memcpy(value, _bytes, _size);
}
@end
