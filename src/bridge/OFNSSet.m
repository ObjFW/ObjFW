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

#import <Foundation/NSSet.h>

#import "OFNSSet.h"
#import "NSEnumerator+OFObject.h"

#import "OFBridging.h"
#import "NSBridging.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfRangeException.h"

@implementation OFNSSet
- (instancetype)initWithNSSet: (NSSet *)set
{
	self = [super init];

	@try {
		if (set == nil)
			@throw [OFInvalidArgumentException exception];

		_set = [set retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_set release];

	[super dealloc];
}

- (bool)containsObject: (id)object
{
	void *pool = objc_autoreleasePoolPush();
	bool ret;

	if ([(OFObject *)object conformsToProtocol: @protocol(OFBridging)])
		object = [object NSObject];

	ret = [_set containsObject: object];

	objc_autoreleasePoolPop(pool);
	return ret;
}

- (size_t)count
{
	return _set.count;
}

- (OFEnumerator *)objectEnumerator
{
	return [_set objectEnumerator].OFObject;
}
@end
