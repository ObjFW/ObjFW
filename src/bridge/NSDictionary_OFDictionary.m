/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "NSDictionary_OFDictionary.h"
#import "OFDictionary.h"

#import "NSBridging.h"
#import "OFBridging.h"

@implementation NSDictionary_OFDictionary
- initWithOFDictionary: (OFDictionary*)dictionary_
{
	if ((self = [super init]) != nil) {
		@try {
			dictionary = [dictionary_ retain];
		} @catch (id e) {
			return nil;
		}
	}

	return self;
}

- (id)objectForKey: (id)key
{
	id object;

	if ([key conformsToProtocol: @protocol(NSBridging)])
		key = [key OFObject];

	object = [dictionary objectForKey: key];

	if ([object conformsToProtocol: @protocol(OFBridging)])
		return [object NSObject];

	return object;
}

- (size_t)count
{
	return [dictionary count];
}
@end
