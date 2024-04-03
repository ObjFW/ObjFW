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

#include <string.h>

#import "OFXMLProcessingInstruction.h"
#import "OFString.h"
#import "OFXMLAttribute.h"
#import "OFXMLNode+Private.h"

#import "OFInvalidArgumentException.h"

@implementation OFXMLProcessingInstruction
@synthesize target = _target, text = _text;

+ (instancetype)processingInstructionWithTarget: (OFString *)target
					   text: (OFString *)text
{
	return [[[self alloc] initWithTarget: target
					text: text] autorelease];
}

- (instancetype)initWithTarget: (OFString *)target
			  text: (OFString *)text
{
	self = [super of_init];

	@try {
		_target = [target copy];
		_text = [text copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_target release];
	[_text release];

	[super dealloc];
}

- (bool)isEqual: (id)object
{
	OFXMLProcessingInstruction *processingInstruction;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFXMLProcessingInstruction class]])
		return false;

	processingInstruction = object;

	if (![processingInstruction->_target isEqual: _target])
		return false;

	if (processingInstruction->_text != _text &&
	    ![processingInstruction->_text isEqual: _text])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);
	OFHashAddHash(&hash, _target.hash);
	OFHashAddHash(&hash, _text.hash);
	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)stringValue
{
	return @"";
}

- (OFString *)XMLString
{
	if (_text.length > 0)
		return [OFString stringWithFormat: @"<?%@ %@?>",
						   _target, _text];
	else
		return [OFString stringWithFormat: @"<?%@?>", _target];
}

- (OFString *)description
{
	return self.XMLString;
}
@end
