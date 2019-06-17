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

#import "OFInvertedCharacterSet.h"
#import "OFString.h"

#import "OFOutOfRangeException.h"

@implementation OFInvertedCharacterSet
- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_initWithCharacterSet: (OFCharacterSet *)characterSet
{
	self = [super init];

	_characterSet = [characterSet retain];
	_characterIsMember = (bool (*)(id, SEL, of_unichar_t))
	    [_characterSet methodForSelector: @selector(characterIsMember:)];

	return self;
}

- (void)dealloc
{
	[_characterSet release];

	[super dealloc];
}

- (bool)characterIsMember: (of_unichar_t)character
{
	return !_characterIsMember(_characterSet, @selector(characterIsMember:),
	    character);
}

- (OFCharacterSet *)invertedSet
{
	return [[_characterSet retain] autorelease];
}
@end
