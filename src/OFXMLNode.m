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

#include <stdlib.h>

#import "OFXMLNode.h"
#import "OFString.h"

@implementation OFXMLNode
- initWithSerialization: (OFXMLElement*)element
{
	@try {
		[self doesNotRecognizeSelector: _cmd];
		abort();
	} @catch (id e) {
		[self release];
		@throw e;
	}
}

- (OFString*)stringValue
{
	[self doesNotRecognizeSelector: _cmd];
	abort();
}

- (intmax_t)decimalValue
{
	return [[self stringValue] decimalValue];
}

- (uintmax_t)hexadecimalValue
{
	return [[self stringValue] hexadecimalValue];
}

- (float)floatValue
{
	return [[self stringValue] floatValue];
}

- (double)doubleValue
{
	return [[self stringValue] doubleValue];
}

- (OFString*)XMLString
{
	return [self XMLStringWithIndentation: 0
					level: 0];
}

- (OFString*)XMLStringWithIndentation: (unsigned int)indentation
{
	return [self XMLStringWithIndentation: 0
					level: 0];
}

- (OFString*)XMLStringWithIndentation: (unsigned int)indentation
				level: (unsigned int)level
{
	[self doesNotRecognizeSelector: _cmd];
	abort();
}

- (OFString*)description
{
	return [self XMLStringWithIndentation: 2];
}

- (OFXMLElement*)XMLElementBySerializing
{
	[self doesNotRecognizeSelector: _cmd];
	abort();
}

- copy
{
	return [self retain];
}
@end
