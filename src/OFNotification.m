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

#import "OFNotification.h"
#import "OFDictionary.h"
#import "OFString.h"

@implementation OFNotification
@synthesize name = _name, object = _object, userInfo = _userInfo;

+ (instancetype)notificationWithName: (OFNotificationName)name
			      object: (id)object
{
	return [[[self alloc] initWithName: name object: object] autorelease];
}

+ (instancetype)notificationWithName: (OFNotificationName)name
			      object: (id)object
			    userInfo: (OFDictionary *)userInfo
{
	return [[[self alloc] initWithName: name
				    object: object
				  userInfo: userInfo] autorelease];
}

- (instancetype)initWithName: (OFNotificationName)name object: (id)object
{
	return [self initWithName: name object: object userInfo: nil];
}

- (instancetype)initWithName: (OFNotificationName)name
		      object: (id)object
		    userInfo: (OFDictionary *)userInfo
{
	self = [super init];

	@try {
		_name = [name copy];
		_object = [object retain];
		_userInfo = [userInfo copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_name release];
	[_object release];
	[_userInfo release];

	[super dealloc];
}

- (id)copy
{
	return [self retain];
}
@end
