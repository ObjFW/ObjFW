/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
		if (size > SSIZE_MAX || (ssize_t)size != (OFFileOffset)size)
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

- (OFFileOffset)lowlevelSeekToOffset: (OFFileOffset)offset whence: (int)whence
{
	OFFileOffset new;

	switch (whence) {
	case SEEK_SET:
		new = offset;
		break;
	case SEEK_CUR:
		new = (OFFileOffset)_position + offset;
		break;
	case SEEK_END:
		new = (OFFileOffset)_size + offset;
		break;
	default:
		@throw [OFInvalidArgumentException exception];
	}

	if (new < 0 || new > (OFFileOffset)_size)
		@throw [OFSeekFailedException exceptionWithStream: self
							   offset: offset
							   whence: whence
							    errNo: EINVAL];

	return (_position = (size_t)new);
}
@end
