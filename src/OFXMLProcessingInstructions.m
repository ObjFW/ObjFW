/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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
#import "OFXMLNode+Private.h"
#import "OFString.h"
#import "OFXMLElement.h"

#import "OFInvalidArgumentException.h"

@implementation OFXMLProcessingInstructions
+ (instancetype)processingInstructionsWithString: (OFString *)string
{
	return [[[self alloc] initWithString: string] autorelease];
}

- (instancetype)initWithString: (OFString *)string
{
	self = [super of_init];

	@try {
		_processingInstructions = [string copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	self = [super of_init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException exception];

		_processingInstructions = [[element stringValue] copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_processingInstructions release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFXMLProcessingInstructions *processingInstructions;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFXMLProcessingInstructions class]])
		return false;

	processingInstructions = object;

	return ([processingInstructions->_processingInstructions
	    isEqual: _processingInstructions]);
}

- (uint32_t)hash
{
	return [_processingInstructions hash];
}

- (OFString *)stringValue
{
	return @"";
}

- (OFString *)XMLString
{
	return [OFString stringWithFormat: @"<?%@?>", _processingInstructions];
}

- (OFString *)XMLStringWithIndentation: (unsigned int)indentation
{
	return [OFString stringWithFormat: @"<?%@?>", _processingInstructions];
}

- (OFString *)XMLStringWithIndentation: (unsigned int)indentation
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
			    @"%s<?%@?>", whitespaces, _processingInstructions];
		} @finally {
			[self freeMemory: whitespaces];
		}
	} else
		ret = [OFString stringWithFormat: @"<?%@?>",
						  _processingInstructions];

	return ret;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<?%@?>", _processingInstructions];
}

- (OFXMLElement *)XMLElementBySerializing
{
	return [OFXMLElement elementWithName: [self className]
				   namespace: OF_SERIALIZATION_NS
				 stringValue: _processingInstructions];
}
@end
