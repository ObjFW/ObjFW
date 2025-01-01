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

#import "OFOpenItemFailedException.h"
#import "OFIRI.h"
#import "OFString.h"

@implementation OFOpenItemFailedException
@synthesize IRI = _IRI, path = _path, mode = _mode, errNo = _errNo;

+ (instancetype)exceptionWithIRI: (OFIRI *)IRI
			    mode: (OFString *)mode
			   errNo: (int)errNo
{
	return [[[self alloc] initWithIRI: IRI
				     mode: mode
				    errNo: errNo] autorelease];
}

+ (instancetype)exceptionWithPath: (OFString *)path
			     mode: (OFString *)mode
			    errNo: (int)errNo
{
	return [[[self alloc] initWithPath: path
				      mode: mode
				     errNo: errNo] autorelease];
}

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)initWithIRI: (OFIRI *)IRI
		       mode: (OFString *)mode
		      errNo: (int)errNo
{
	self = [super init];

	@try {
		_IRI = [IRI copy];
		_mode = [mode copy];
		_errNo = errNo;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithPath: (OFString *)path
			mode: (OFString *)mode
		       errNo: (int)errNo
{
	self = [super init];

	@try {
		_path = [path copy];
		_mode = [mode copy];
		_errNo = errNo;
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
	[_IRI release];
	[_path release];
	[_mode release];

	[super dealloc];
}

- (OFString *)description
{
	id item = nil;

	if (_IRI != nil)
		item = _IRI;
	else if (_path != nil)
		item = _path;

	if (_mode != nil)
		return [OFString stringWithFormat:
		    @"Failed to open file %@ with mode %@: %@",
		    item, _mode, OFStrError(_errNo)];
	else
		return [OFString stringWithFormat:
		    @"Failed to open item %@: %@", item, OFStrError(_errNo)];
}
@end
