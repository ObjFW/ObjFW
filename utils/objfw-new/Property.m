/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "Property.h"

#import "OFArray.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

OF_DIRECT_MEMBERS
@interface Property ()
- (void)parseString: (OFString *)string;
@end

@implementation Property
@synthesize name = _name, type = _type, attributes = _attributes;

+ (instancetype)propertyWithString: (OFString *)string
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithString: string]);
}

- (instancetype)initWithString: (OFString *)string
{
	self = [super init];

	@try {
		[self parseString: string];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)parseString: (OFString *)string
{
	void *pool = objc_autoreleasePoolPush();
	const char *UTF8String = string.UTF8String;
	size_t length = string.UTF8StringLength;
	ssize_t nameIdx = -1;
	OFMutableArray *attributes = nil;

	if (length > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	if (UTF8String[0] == '(') {
		for (size_t i = 0, level = 0; i < length; i++) {
			if (UTF8String[i] == '(')
				level++;
			else if (UTF8String[i] == ')') {
				if (--level == 0) {
					OFString *attributesString = [OFString
					    stringWithUTF8String: UTF8String + 1
							  length: i - 1];
					attributes = objc_autorelease(
					    [[attributesString
					    componentsSeparatedByString: @","]
					    mutableCopy]);

					UTF8String += i + 1;
					length += i + 1;

					while (*UTF8String == ' ' ||
					    *UTF8String == '\t') {
						UTF8String++;
						length--;
					}

					break;
				}
			}
		}
	}

	for (size_t i = 0; i < attributes.count; i++) {
		OFString *attribute = [[attributes objectAtIndex: i]
		    stringByDeletingEnclosingWhitespaces];

		[attributes replaceObjectAtIndex: i
				      withObject: attribute];
	}

	[attributes makeImmutable];
	_attributes = [attributes copy];

	for (ssize_t i = (ssize_t)length - 1; i > 0; i--) {
		if (UTF8String[i] == '*' || UTF8String[i] == ' ' ||
		    UTF8String[i] == '\t') {
			nameIdx = i + 1;
			break;
		}
	}

	if (nameIdx < 0)
		@throw [OFInvalidArgumentException exception];

	_name = [[OFString alloc] initWithUTF8String: UTF8String + nameIdx];
	_type = [[OFString alloc] initWithUTF8String: UTF8String
					      length: (size_t)nameIdx];

	objc_autoreleasePoolPop(pool);
}

- (void)dealloc
{
	objc_release(_name);
	objc_release(_type);

	[super dealloc];
}
@end
