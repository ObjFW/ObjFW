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
