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

#import "OFLoadPluginFailedException.h"
#import "OFString.h"

@implementation OFLoadPluginFailedException
@synthesize path = _path, error = _error;

+ (instancetype)exceptionWithPath: (OFString *)path error: (OFString *)error
{
	return [[[self alloc] initWithPath: path error: error] autorelease];
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithPath: (OFString *)path error: (OFString *)error
{
	self = [super init];

	@try {
		_path = [path copy];
		_error = [error copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_path release];
	[_error release];

	[super dealloc];
}

- (OFString *)description
{
	if (_error != nil)
		return [OFString stringWithFormat:
		    @"Failed to load plugin %@: %@", _path, _error];
	else
		return [OFString stringWithFormat:
		    @"Failed to load plugin: %@", _path];
}
@end
