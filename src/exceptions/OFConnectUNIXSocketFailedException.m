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

#import "OFConnectUNIXSocketFailedException.h"
#import "OFString.h"

@implementation OFConnectUNIXSocketFailedException
@synthesize path = _path;

+ (instancetype)exceptionWithSocket: (id)sock errNo: (int)errNo
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithPath: (OFString *)path
			   socket: (id)sock
			    errNo: (int)errNo
{
	return objc_autoreleaseReturnValue([[self alloc] initWithPath: path
							       socket: sock
								errNo: errNo]);
}

- (instancetype)initWithSocket: (id)sock errNo: (int)errNo
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithPath: (OFString *)path
		      socket: (id)sock
		       errNo: (int)errNo
{
	self = [super initWithSocket: sock errNo: errNo];

	@try {
		_path = [path copy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_path);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"A connection to %@ could not be established in socket of type "
	    @"%@: %@",
	    _path, [_socket class], OFStrError(_errNo)];
}
@end
