/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <string.h>

#import "OFXMLComment.h"
#import "OFString.h"
#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"

#import "OFInvalidArgumentException.h"

@implementation OFXMLComment
+ commentWithString: (OFString*)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

- initWithString: (OFString*)string
{
	self = [super init];

	@try {
		comment = [string copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithSerialization: (OFXMLElement*)element
{
	self = [super init];

	@try {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		comment = [[element stringValue] copy];

		[pool release];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (BOOL)isEqual: (id)object
{
	OFXMLComment *otherComment;

	if (![object isKindOfClass: [OFXMLComment class]])
		return NO;

	otherComment = object;

	return ([otherComment->comment isEqual: comment]);
}

- (uint32_t)hash
{
	return [comment hash];
}

- (OFString*)stringValue
{
	return @"";
}

- (OFString*)XMLString
{
	return [OFString stringWithFormat: @"<!--%@-->", comment];
}

- (OFString*)XMLStringWithIndentation: (unsigned int)indentation
{
	return [OFString stringWithFormat: @"<!--%@-->", comment];
}

- (OFString*)XMLStringWithIndentation: (unsigned int)indentation
				level: (unsigned int)level
{
	OFString *ret;

	if (indentation > 0 && level > 0) {
		char *whitespaces = [self allocMemoryWithSize:
		    (level * indentation) + 1];
		memset(whitespaces, ' ', level * indentation);
		whitespaces[level * indentation] = 0;

		@try {
			ret = [OFString stringWithFormat: @"%s<!--%@-->",
							  whitespaces,
							  comment];
		} @finally {
			[self freeMemory: whitespaces];
		}
	} else
		ret = [OFString stringWithFormat: @"<!--%@-->", comment];

	return ret;
}

- (OFString*)description
{
	return [OFString stringWithFormat: @"<!--%@-->", comment];
}

- (OFXMLElement*)XMLElementBySerializing
{
	return [OFXMLElement elementWithName: [self className]
				   namespace: OF_SERIALIZATION_NS
				 stringValue: comment];
}
@end
