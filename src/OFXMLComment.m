/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#include <string.h>

#import "OFXMLComment.h"
#import "OFXMLNode+Private.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@implementation OFXMLComment
@synthesize text = _text;

+ (instancetype)commentWithText: (OFString *)text
{
	return objc_autoreleaseReturnValue([[self alloc] initWithText: text]);
}

- (instancetype)initWithText: (OFString *)text
{
	self = [super of_init];

	@try {
		_text = [text copy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_text);

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
@end
