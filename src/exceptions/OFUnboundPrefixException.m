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

#import "OFUnboundPrefixException.h"
#import "OFString.h"
#import "OFXMLParser.h"

@implementation OFUnboundPrefixException
@synthesize prefix = _prefix, parser = _parser;

+ (instancetype)exception
{
	OF_UNRECOGNIZED_SELECTOR
}

+ (instancetype)exceptionWithPrefix: (OFString *)prefix
			     parser: (OFXMLParser *)parser
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithPrefix: prefix
				  parser: parser]);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithPrefix: (OFString *)prefix parser: (OFXMLParser *)parser
{
	self = [super init];

	@try {
		_prefix = [prefix copy];
		_parser = objc_retain(parser);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_prefix);
	objc_release(_parser);

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"An XML parser of type %@ encountered the unbound prefix %@ in "
	    @"line %zu!", _parser.class, _prefix, _parser.lineNumber];
}
@end
