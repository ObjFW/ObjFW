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

#include <string.h>

#import "OFXMLComment.h"
#import "OFXMLNode+Private.h"
#import "OFString.h"
#import "OFXMLElement.h"

#import "OFInvalidArgumentException.h"

@implementation OFXMLComment
@synthesize text = _text;

+ (instancetype)commentWithText: (OFString *)text
{
	return [[[self alloc] initWithText: text] autorelease];
}

- (instancetype)initWithText: (OFString *)text
{
	self = [super of_init];

	@try {
		_text = [text copy];
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

		if (![element.name isEqual: self.className] ||
		    ![element.namespace isEqual: OFSerializationNS])
			@throw [OFInvalidArgumentException exception];

		_text = [element.stringValue copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_text release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFXMLComment *comment;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFXMLComment class]])
		return false;

	comment = object;

	return ([comment->_text isEqual: _text]);
}

- (unsigned long)hash
{
	return _text.hash;
}

- (OFString *)stringValue
{
	return @"";
}

- (OFString *)XMLString
{
	return [OFString stringWithFormat: @"<!--%@-->", _text];
}

- (OFString *)description
{
	return self.XMLString;
}

- (OFXMLElement *)XMLElementBySerializing
{
	return [OFXMLElement elementWithName: self.className
				   namespace: OFSerializationNS
				 stringValue: _text];
}
@end
