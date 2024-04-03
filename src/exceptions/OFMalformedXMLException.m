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

#import "OFMalformedXMLException.h"
#import "OFString.h"
#import "OFXMLParser.h"

@implementation OFMalformedXMLException
@synthesize parser = _parser;

+ (instancetype)exceptionWithParser: (OFXMLParser *)parser
{
	return [[[self alloc] initWithParser: parser] autorelease];
}

- (instancetype)init
{
	return [self initWithParser: nil];
}

- (instancetype)initWithParser: (OFXMLParser *)parser
{
	self = [super init];

	_parser = [parser retain];

	return self;
}

- (void)dealloc
{
	[_parser release];

	[super dealloc];
}

- (OFString *)description
{
	if (_parser != nil)
		return [OFString stringWithFormat:
		    @"An XML parser of type %@ encountered malformed XML in "
		    @"line %zu!", _parser.class, _parser.lineNumber];
	else
		return @"An XML parser encountered malformed XML!";
}
@end
