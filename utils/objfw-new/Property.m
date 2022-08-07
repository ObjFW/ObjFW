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

#import "Property.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

@interface Property ()
- (void)parseString: (OFString *)string;
@end

@implementation Property
@synthesize name = _name, type = _type;

+ (instancetype)propertyWithString: (OFString *)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

- (instancetype)initWithString: (OFString *)string
{
	self = [super init];

	@try {
		[self parseString: string];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)parseString: (OFString *)string
{
	const char *UTF8String = string.UTF8String;
	size_t length = string.UTF8StringLength, nameIdx = -1;

	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	for (ssize_t i = (ssize_t)length - 1; i > 0; i--) {
		if (UTF8String[i] == '*' || UTF8String[i] == ' ' ||
		    UTF8String[i] == '\t') {
			nameIdx = i + 1;
			break;
		}
	}

	if (nameIdx < 0)
		@throw [OFInvalidArgumentException exception];

	_name = [[OFString alloc] initWithUTF8String: UTF8String + nameIdx];
	_type = [[OFString alloc] initWithUTF8String: UTF8String
					      length: (size_t)nameIdx];
}

- (void)dealloc
{
	[_name release];
	[_type release];

	[super dealloc];
}
@end
