/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import <Foundation/NSDictionary.h>

#import "OFDictionary_NSDictionary.h"

#import "NSBridging.h"
#import "OFBridging.h"

#import "OFInitializationFailedException.h"

@implementation OFDictionary_NSDictionary
- initWithNSDictionary: (NSDictionary *)dictionary
{
	self = [super init];

	@try {
		if (dictionary == nil)
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

		_dictionary = [dictionary retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (id)objectForKey: (id)key
{
	id object;

	if ([(OFObject *)key conformsToProtocol: @protocol(OFBridging)])
		key = [key NSObject];

	object = [_dictionary objectForKey: key];

	if ([(NSObject *)object conformsToProtocol: @protocol(NSBridging)])
		return [object OFObject];

	return object;
}

- (size_t)count
{
	return [_dictionary count];
}
@end
