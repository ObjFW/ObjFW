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

#import "OFCharacterSet.h"
#import "OFBitSetCharacterSet.h"
#import "OFInvertedCharacterSet.h"
#import "OFRangeCharacterSet.h"

static struct {
	Class isa;
} placeholder;

static OFCharacterSet *whitespaceCharacterSet = nil;

@interface OFPlaceholderCharacterSet: OFCharacterSet
@end

@interface OFWhitespaceCharacterSet: OFCharacterSet
- (instancetype)of_init;
@end

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

- (instancetype)initWithRange: (of_range_t)range
{
	return (id)[[OFRangeCharacterSet alloc] initWithRange: range];
}

- (instancetype)retain
{
	return self;
}

- (instancetype)autorelease
{
	return self;
}

- (void)release
{
}

- (void)dealloc
{
	OF_DEALLOC_UNSUPPORTED
}
@end

@implementation OFCharacterSet
+ (void)initialize
{
	if (self != [OFCharacterSet class])
		return;

	placeholder.isa = [OFPlaceholderCharacterSet class];
}

+ (instancetype)alloc
{
	if (self == [OFCharacterSet class])
		return (id)&placeholder;

	return [super alloc];
}

+ (instancetype)characterSetWithCharactersInString: (OFString *)characters
{
	return [[[self alloc] initWithCharactersInString: characters]
	    autorelease];
}

+ (instancetype)characterSetWithRange: (of_range_t)range
{
	return [[[self alloc] initWithRange: range] autorelease];
}

+ (OFCharacterSet *)whitespaceCharacterSet
{
	return [OFWhitespaceCharacterSet whitespaceCharacterSet];
}

- (instancetype)init
{
	if ([self isMemberOfClass: [OFCharacterSet class]]) {
		@try {
			[self doesNotRecognizeSelector: _cmd];
		} @catch (id e) {
			[self release];
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

- (instancetype)initWithRange: (of_range_t)range
{
	OF_INVALID_INIT_METHOD
}

- (bool)characterIsMember: (of_unichar_t)character
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFCharacterSet *)invertedSet
{
	return [[[OFInvertedCharacterSet alloc]
	    of_initWithCharacterSet: self] autorelease];
}
@end

@implementation OFWhitespaceCharacterSet
+ (void)initialize
{
	if (self != [OFWhitespaceCharacterSet class])
		return;

	whitespaceCharacterSet = [[OFWhitespaceCharacterSet alloc] of_init];
}

+ (OFCharacterSet *)whitespaceCharacterSet
{
	return whitespaceCharacterSet;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_init
{
	return [super init];
}

- (instancetype)autorelease
{
	return self;
}

- (instancetype)retain
{
	return self;
}

- (void)release
{
}

- (unsigned int)retainCount
{
	return OF_RETAIN_COUNT_MAX;
}

- (bool)characterIsMember: (of_unichar_t)character
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
@end
