/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
