/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "OFXMLProcessingInstruction.h"
#import "OFString.h"
#import "OFXMLAttribute.h"
#import "OFXMLElement.h"
#import "OFXMLNode+Private.h"

#import "OFInvalidArgumentException.h"

@implementation OFXMLProcessingInstruction
@synthesize target = _target, data = _data;

+ (instancetype)processingInstructionWithTarget: (OFString *)target
					   data: (OFString *)data
{
	return [[[self alloc] initWithTarget: target
					data: data] autorelease];
}

- (instancetype)initWithTarget: (OFString *)target
			  data: (OFString *)data
{
	self = [super of_init];

	@try {
		_target = [target copy];
		_data = [data copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithSerialization: (OFXMLElement *)element
{
	@try {
		void *pool = objc_autoreleasePoolPush();
		OFXMLAttribute *targetAttr;

		if (![element.name isEqual: self.className] ||
		    ![element.namespace isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException exception];

		targetAttr = [element attributeForName: @"target"
					     namespace: OF_SERIALIZATION_NS];
		if (targetAttr.stringValue.length == 0)
			@throw [OFInvalidArgumentException exception];

		self = [self initWithTarget: targetAttr.stringValue
				       data: element.stringValue];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_target release];
	[_data release];

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

	if (processingInstruction->_data != _data &&
	    ![processingInstruction->_data isEqual: _data])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OF_HASH_INIT(hash);
	OF_HASH_ADD_HASH(hash, _target.hash);
	OF_HASH_ADD_HASH(hash, _data.hash);
	OF_HASH_FINALIZE(hash);

	return hash;
}

- (OFString *)stringValue
{
	return @"";
}

- (OFString *)XMLString
{
	if (_data.length > 0)
		return [OFString stringWithFormat: @"<?%@ %@?>",
						   _target, _data];
	else
		return [OFString stringWithFormat: @"<?%@?>", _target];
}

- (OFString *)XMLStringWithIndentation: (unsigned int)indentation
{
	return self.XMLString;
}

- (OFString *)XMLStringWithIndentation: (unsigned int)indentation
				 level: (unsigned int)level
{
	if (indentation > 0 && level > 0) {
		OFString *ret;
		char *whitespaces = of_alloc((level * indentation) + 1, 1);
		memset(whitespaces, ' ', level * indentation);
		whitespaces[level * indentation] = 0;

		@try {
			if (_data.length > 0)
				ret = [OFString stringWithFormat:
				    @"%s<?%@ %@?>", whitespaces,
				    _target, _data];
			else
				ret = [OFString stringWithFormat:
				    @"%s<?%@?>", whitespaces, _target];
		} @finally {
			free(whitespaces);
		}

		return ret;
	} else
		return self.XMLString;
}

- (OFString *)description
{
	return self.XMLString;
}

- (OFXMLElement *)XMLElementBySerializing
{
	OFXMLElement *ret = [OFXMLElement elementWithName: self.className
						namespace: OF_SERIALIZATION_NS
					      stringValue: _data];
	void *pool = objc_autoreleasePoolPush();

	[ret addAttribute: [OFXMLAttribute attributeWithName: @"target"
						 stringValue: _target]];

	objc_autoreleasePoolPop(pool);

	return ret;
}
@end
