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

#import "OFCharacterSet.h"
#import "OFBitSetCharacterSet.h"
#import "OFInvertedCharacterSet.h"
#import "OFOnce.h"
#import "OFRangeCharacterSet.h"

@interface OFPlaceholderCharacterSet: OFCharacterSet
@end

@interface OFWhitespaceCharacterSet: OFCharacterSet
@end

@interface OFControlCharacterSet: OFCharacterSet
@end

static struct {
	Class isa;
} placeholder;

static OFCharacterSet *whitespaceCharacterSet;
static OFCharacterSet *controlCharacterSet;

static void
initWhitespaceCharacterSet(void)
{
	whitespaceCharacterSet = [[OFWhitespaceCharacterSet alloc] init];
}

static void
initControlCharacterSet(void)
{
	controlCharacterSet = [[OFControlCharacterSet alloc] init];
}

@implementation OFPlaceholderCharacterSet
- (instancetype)init
{
	return (id)[[OFBitSetCharacterSet alloc] init];
}

- (instancetype)initWithCharactersInString: (OFString *)characters
{
	return (id)[[OFBitSetCharacterSet alloc]
	    initWithCharactersInString: characters];
}

- (instancetype)initWithRange: (OFRange)range
{
	return (id)[[OFRangeCharacterSet alloc] initWithRange: range];
}

OF_SINGLETON_METHODS
@end

@implementation OFCharacterSet
+ (void)initialize
{
	if (self == [OFCharacterSet class])
		object_setClass((id)&placeholder,
		    [OFPlaceholderCharacterSet class]);
}

+ (instancetype)alloc
{
	if (self == [OFCharacterSet class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)characterSetWithCharactersInString: (OFString *)characters
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithCharactersInString: characters]);
}

+ (instancetype)characterSetWithRange: (OFRange)range
{
	return objc_autoreleaseReturnValue([[self alloc] initWithRange: range]);
}

+ (OFCharacterSet *)whitespaceCharacterSet
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initWhitespaceCharacterSet);

	return whitespaceCharacterSet;
}

+ (OFCharacterSet *)controlCharacterSet
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFOnce(&onceControl, initControlCharacterSet);

	return controlCharacterSet;
}

- (instancetype)init
{
	if ([self isMemberOfClass: [OFCharacterSet class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
		} @catch (id e) {
			objc_release(self);
			@throw e;
		}

		abort();
	}

	return [super init];
}

- (instancetype)initWithCharactersInString: (OFString *)characters
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithRange: (OFRange)range
{
	OF_INVALID_INIT_METHOD
}

- (bool)characterIsMember: (OFUnichar)character
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFCharacterSet *)invertedSet
{
	return objc_autoreleaseReturnValue(
	    [[OFInvertedCharacterSet alloc] initWithCharacterSet: self]);
}
@end

@implementation OFWhitespaceCharacterSet
- (bool)characterIsMember: (OFUnichar)character
{
	switch (character) {
	case 0x0009:
	case 0x0020:
	case 0x00A0:
	case 0x1680:
	case 0x2000:
	case 0x2001:
	case 0x2002:
	case 0x2003:
	case 0x2004:
	case 0x2005:
	case 0x2006:
	case 0x2007:
	case 0x2008:
	case 0x2009:
	case 0x200A:
	case 0x202F:
	case 0x205F:
	case 0x3000:
		return true;
	default:
		return false;
	}
}

OF_SINGLETON_METHODS
@end

@implementation OFControlCharacterSet
- (bool)characterIsMember: (OFUnichar)character
{
	if (character <= 0x1F)
		return true;

	if (character >= 0x7F && character <= 0x9F)
		return true;

	return false;
}

OF_SINGLETON_METHODS
@end
