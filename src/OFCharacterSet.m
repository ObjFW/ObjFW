/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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
#import "OFCharacterSet_bitset.h"
#import "OFCharacterSet_invertedSet.h"
#import "OFCharacterSet_range.h"

static struct {
	Class isa;
} placeholder;

@interface OFCharacterSet_placeholder: OFCharacterSet
@end

@implementation OFCharacterSet_placeholder
- (instancetype)init
{
	return (id)[[OFCharacterSet_bitset alloc] init];
}

- (instancetype)initWithCharactersInString: (OFString *)characters
{
	return (id)[[OFCharacterSet_bitset alloc]
	    initWithCharactersInString: characters];
}

- (instancetype)initWithRange: (of_range_t)range
{
	return (id)[[OFCharacterSet_range alloc] initWithRange: range];
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

	placeholder.isa = [OFCharacterSet_placeholder class];
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
	return [[[OFCharacterSet_invertedSet alloc]
	    of_initWithCharacterSet: self] autorelease];
}
@end
