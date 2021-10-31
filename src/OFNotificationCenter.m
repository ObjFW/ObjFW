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

#import "OFNotificationCenter.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
#endif
#import "OFSet.h"
#import "OFString.h"

@interface OFDefaultNotificationCenter: OFNotificationCenter
@end

@interface OFNotificationRegistration: OFObject
{
@public
	id _observer;
	SEL _selector;
	unsigned long _selectorHash;
	id _object;
}

- (instancetype)initWithObserver: (id)observer
			selector: (SEL)selector
			  object: (id)object;
@end

static OFNotificationCenter *defaultCenter;

@implementation OFNotificationRegistration
- (instancetype)initWithObserver: (id)observer
			selector: (SEL)selector
			  object: (id)object
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		_observer = [observer retain];
		_selector = selector;
		_object = [object retain];

		_selectorHash = [[OFString stringWithUTF8String:
		    sel_getName(_selector)] hash];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_observer release];
	[_object release];

	[super dealloc];
}

- (bool)isEqual: (OFNotificationRegistration *)registration
{
	if (![registration isKindOfClass: [OFNotificationRegistration class]])
		return false;

	if (![registration->_observer isEqual: _observer])
		return false;

	if (!sel_isEqual(registration->_selector, _selector))
		return false;

	if (registration->_object != _object &&
	    ![registration->_object isEqual: _object])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, [_observer hash]);
	OFHashAddHash(&hash, _selectorHash);
	OFHashAddHash(&hash, [_object hash]);

	OFHashFinalize(&hash);

	return hash;
}
@end

@implementation OFNotificationCenter
+ (void)initialize
{
	if (self != [OFNotificationCenter class])
		return;

	defaultCenter = [[OFDefaultNotificationCenter alloc] init];
}

+ (OFNotificationCenter *)defaultCenter
{
	return defaultCenter;
}

- (instancetype)init
{
	self = [super init];

	@try {
#ifdef OF_HAVE_THREADS
		_mutex = [[OFMutex alloc] init];
#endif
		_notifications = [[OFMutableDictionary alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
#ifdef OF_HAVE_THREADS
	[_mutex release];
#endif
	[_notifications release];

	[super dealloc];
}

- (void)addObserver: (id)observer
	   selector: (SEL)selector
	       name: (OFNotificationName)name
	     object: (id)object
{
	void *pool = objc_autoreleasePoolPush();
	OFNotificationRegistration *registration =
	    [[[OFNotificationRegistration alloc]
	    initWithObserver: observer
		    selector: selector
		      object: object] autorelease];

#ifdef OF_HAVE_THREADS
	[_mutex lock];
	@try {
		OFMutableSet *notificationsForName =
		    [_notifications objectForKey: name];

		if (notificationsForName == nil) {
			notificationsForName = [OFMutableSet set];
			[_notifications setObject: notificationsForName
					   forKey: name];
		}

		[notificationsForName addObject: registration];
#endif
#ifdef OF_HAVE_THREADS
	} @finally {
		[_mutex unlock];
	}
#endif

	objc_autoreleasePoolPop(pool);
}

- (void)removeObserver: (id)observer
	      selector: (SEL)selector
		  name: (OFNotificationName)name
		object: (id)object
{
	void *pool = objc_autoreleasePoolPush();
	OFNotificationRegistration *registration =
	    [[[OFNotificationRegistration alloc]
	    initWithObserver: observer
		    selector: selector
		      object: object] autorelease];

#ifdef OF_HAVE_THREADS
	[_mutex lock];
	@try {
		[[_notifications objectForKey: name]
		    removeObject: registration];
#endif
#ifdef OF_HAVE_THREADS
	} @finally {
		[_mutex unlock];
	}
#endif

	objc_autoreleasePoolPop(pool);
}

- (void)postNotification: (OFNotification *)notification
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
	@try {
		for (OFNotificationRegistration *registration in
		    [_notifications objectForKey: notification.name]) {
			void (*callback)(id, SEL, OFNotification *);

			if (registration->_object != nil &&
			    registration->_object != notification.object)
				continue;

			callback = (void (*)(id, SEL, OFNotification *))
			    [registration->_observer methodForSelector:
			    registration->_selector];
			callback(registration->_observer,
			    registration->_selector, notification);
		}
#endif
#ifdef OF_HAVE_THREADS
	} @finally {
		[_mutex unlock];
	}
#endif
}
@end

@implementation OFDefaultNotificationCenter
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
	return OFMaxRetainCount;
}
@end
