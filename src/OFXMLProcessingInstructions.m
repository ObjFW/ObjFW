/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#import "OFXMLProcessingInstructions.h"
#import "OFString.h"
#import "OFXMLElement.h"

#import "OFInvalidArgumentException.h"

#import "autorelease.h"

@implementation OFXMLProcessingInstructions
+ (instancetype)processingInstructionsWithString: (OFString*)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

- initWithString: (OFString*)string
{
	self = [super init];

	@try {
		processingInstructions = [string copy];
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
		void *pool = objc_autoreleasePoolPush();

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException
			    exceptionWithClass: [self class]
				      selector: _cmd];

		processingInstructions = [[element stringValue] copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (BOOL)isEqual: (id)object
{
	OFXMLProcessingInstructions *otherProcessingInstructions;

	if (![object isKindOfClass: [OFXMLProcessingInstructions class]])
		return NO;

	otherProcessingInstructions = object;

	return ([otherProcessingInstructions->processingInstructions
	    isEqual: processingInstructions]);
}

- (uint32_t)hash
{
	return [processingInstructions hash];
}

- (OFString*)stringValue
{
	return @"";
}

- (OFString*)XMLString
{
	return [OFString stringWithFormat: @"<?%@?>", processingInstructions];
}

- (OFString*)XMLStringWithIndentation: (unsigned int)indentation
{
	return [OFString stringWithFormat: @"<?%@?>", processingInstructions];
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
			ret = [OFString stringWithFormat:
			    @"%s<?%@?>",
			    whitespaces,
			    processingInstructions];
		} @finally {
			[self freeMemory: whitespaces];
		}
	} else
		ret = [OFString stringWithFormat: @"<?%@?>",
						  processingInstructions];

	return ret;
}

- (OFString*)description
{
	return [OFString stringWithFormat: @"<?%@?>", processingInstructions];
}

- (OFXMLElement*)XMLElementBySerializing
{
	return [OFXMLElement elementWithName: [self className]
				   namespace: OF_SERIALIZATION_NS
				 stringValue: processingInstructions];
}
@end
