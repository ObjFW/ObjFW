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

#import "NSOFSet.h"
#import "OFEnumerator+NSObject.h"
#import "OFSet.h"

#import "OFBridging.h"
#import "NSBridging.h"

#import "OFOutOfRangeException.h"

@implementation NSOFSet
- (instancetype)initWithOFSet: (OFSet *)set
{
	if ((self = [super init]) != nil)
		_set = [set retain];

	return self;
}

- (void)dealloc
{
	[_set release];

	[super dealloc];
}

- (id)member: (id)object
{
	id originalObject = object;

	if ([(NSObject *)object conformsToProtocol: @protocol(NSBridging)])
		object = [object OFObject];

	if ([_set containsObject: object])
		return originalObject;

	return nil;
}

- (NSUInteger)count
{
	size_t count = _set.count;

	if (count > NSUIntegerMax)
		@throw [OFOutOfRangeException exception];

	return (NSUInteger)count;
}

- (NSEnumerator *)objectEnumerator
{
	return [_set objectEnumerator].NSObject;
}
@end
