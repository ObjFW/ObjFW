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

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
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
