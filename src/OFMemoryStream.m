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

#include "config.h"

#include <errno.h>

#import "OFMemoryStream.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"
#import "OFWriteFailedException.h"
#import "OFSeekFailedException.h"

@implementation OFMemoryStream
+ (instancetype)streamWithMemoryAddress: (void *)address
				   size: (size_t)size
			       writable: (bool)writable
{
	return [[[self alloc] initWithMemoryAddress: address
					       size: size
					   writable: writable] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithMemoryAddress: (void *)address
				 size: (size_t)size
			     writable: (bool)writable
{
	self = [super init];

	@try {
		if (size > SSIZE_MAX || (ssize_t)size != (OFStreamOffset)size)
			@throw [OFOutOfRangeException exception];

		_address = address;
		_size = size;
		_writable = writable;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	if (SIZE_MAX - _position < length || _position + length > _size)
		length = _size - _position;

	memcpy(buffer, _address + _position, length);
	_position += length;

	return length;
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
{
	size_t bytesWritten = length;

	if (!_writable)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: 0
							     errNo: EBADF];

	if (SIZE_MAX - _position < length || _position + length > _size)
		bytesWritten = _size - _position;

	memcpy(_address + _position, buffer, bytesWritten);
	_position += bytesWritten;

	if (bytesWritten != length)
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: bytesWritten
							     errNo: EFBIG];

	return bytesWritten;
}

- (bool)lowlevelIsAtEndOfStream
{
	return (_position == _size);
}

- (OFStreamOffset)lowlevelSeekToOffset: (OFStreamOffset)offset
				whence: (OFSeekWhence)whence
{
	OFStreamOffset new;

	switch (whence) {
	case OFSeekSet:
		new = offset;
		break;
	case OFSeekCurrent:
		new = (OFStreamOffset)_position + offset;
		break;
	case OFSeekEnd:
		new = (OFStreamOffset)_size + offset;
		break;
	default:
		@throw [OFInvalidArgumentException exception];
	}

	if (new < 0 || new > (OFStreamOffset)_size)
		@throw [OFSeekFailedException exceptionWithStream: self
							   offset: offset
							   whence: whence
							    errNo: EINVAL];

	return (_position = (size_t)new);
}
@end
