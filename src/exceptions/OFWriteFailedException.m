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

#import "OFWriteFailedException.h"
#import "OFString.h"

@implementation OFWriteFailedException
@synthesize bytesWritten = _bytesWritten;

+ (instancetype)exceptionWithObject: (id)object
		    requestedLength: (size_t)requestedLength
			      errNo: (int)errNo
{
	return [[[self alloc] initWithObject: object
			     requestedLength: requestedLength
				       errNo: errNo] autorelease];
}

+ (instancetype)exceptionWithObject: (id)object
		    requestedLength: (size_t)requestedLength
		       bytesWritten: (size_t)bytesWritten
			      errNo: (int)errNo
{
	return [[[self alloc] initWithObject: object
			     requestedLength: requestedLength
				bytesWritten: bytesWritten
				       errNo: errNo] autorelease];
}

- (instancetype)initWithObject: (id)object
	       requestedLength: (size_t)requestedLength
			 errNo: (int)errNo
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithObject: (id)object
	       requestedLength: (size_t)requestedLength
		  bytesWritten: (size_t)bytesWritten
			 errNo: (int)errNo
{
	self = [super initWithObject: object
		     requestedLength: requestedLength
			       errNo: errNo];

	_bytesWritten = bytesWritten;

	return self;
}

- (OFString *)description
{
	if (_errNo != 0)
		return [OFString stringWithFormat:
		    @"Failed to write %zu bytes (after %zu bytes written) to "
		    @"an object of type %@: %@",
		    _requestedLength, _bytesWritten, [_object class],
		    OFStrError(_errNo)];
	else
		return [OFString stringWithFormat:
		    @"Failed to write %zu bytes (after %zu bytes written) to "
		    @"an object of type %@",
		    _requestedLength, _bytesWritten, [_object class]];
}
@end
