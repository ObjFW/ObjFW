/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#define OF_NOTIFICATION_CENTER_M

#include "config.h"

#import "OFNotificationCenter.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFSet.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"

@interface OFDefaultNotificationCenter: OFNotificationCenter
@end

@interface OFNotificationCenterHandle: OFObject
{
@public
	OFNotificationName _name;
	id _observer;
	SEL _selector;
	unsigned long _selectorHash;
#ifdef OF_HAVE_BLOCKS
	OFNotificationCenterBlock _block;
#endif
	id _object;
}

- (instancetype)initWithName: (OFNotificationName)name
		    observer: (id)observer
		    selector: (SEL)selector
		      object: (id)object;
#ifdef OF_HAVE_BLOCKS
- (instancetype)initWithName: (OFNotificationName)name
		      object: (id)object
		       block: (OFNotificationCenterBlock)block;
#endif
@end

static OFNotificationCenter *defaultCenter;

@implementation OFNotificationCenterHandle
- (instancetype)initWithName: (OFNotificationName)name
		    observer: (id)observer
		    selector: (SEL)selector
		      object: (id)object
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		_name = [name copy];
		_observer = observer;
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

#ifdef OF_HAVE_BLOCKS
- (instancetype)initWithName: (OFNotificationName)name
		      object: (id)object
		       block: (OFNotificationCenterBlock)block
{
	self = [super init];

	@try {
		_name = [name copy];
		_object = [object retain];
		_block = [block copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

- (void)dealloc
{
	[_name release];
	[_object release];
#ifdef OF_HAVE_BLOCKS
	[_block release];
#endif

	[super dealloc];
}

- (bool)isEqual: (OFNotificationCenterHandle *)handle
{
	if (![handle isKindOfClass: [OFNotificationCenterHandle class]])
		return false;

	if (![handle->_name isEqual: _name])
		return false;

	if (handle->_observer != _observer &&
	    ![handle->_observer isEqual: _observer])
		return false;

	if (handle->_selector != _selector &&
	    !sel_isEqual(handle->_selector, _selector))
		return false;

#ifdef OF_HAVE_BLOCKS
	if (handle->_block != _block)
		return false;
#endif

	if (handle->_object != _object && ![handle->_object isEqual: _object])
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _name.hash);
	OFHashAddHash(&hash, [_observer hash]);
	OFHashAddHash(&hash, _selectorHash);
#ifdef OF_HAVE_BLOCKS
	if (_block != NULL)
		OFHashAddHash(&hash, (unsigned long)(uintptr_t)_block);
#endif
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
		_handles = [[OFMutableDictionary alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_handles release];

	[super dealloc];
}

- (void)of_addObserver: (OFNotificationCenterHandle *)handle
{
	@synchronized (_handles) {
		OFMutableSet *handlesForName =
		    [_handles objectForKey: handle->_name];

		if (handlesForName == nil) {
			handlesForName = [OFMutableSet set];
			[_handles setObject: handlesForName
				     forKey: handle->_name];
		}

		[handlesForName addObject: handle];
	}
}

- (void)addObserver: (id)observer
	   selector: (SEL)selector
	       name: (OFNotificationName)name
	     object: (id)object
{
	void *pool = objc_autoreleasePoolPush();

	[self of_addObserver:
	    [[[OFNotificationCenterHandle alloc] initWithName: name
						     observer: observer
						     selector: selector
						       object: object]
	    autorelease]];

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_HAVE_BLOCKS
- (id)addObserverForName: (OFNotificationName)name
		  object: (id)object
	      usingBlock: (OFNotificationCenterBlock)block
{
	void *pool = objc_autoreleasePoolPush();
	OFNotificationCenterHandle *handle =
	    [[[OFNotificationCenterHandle alloc] initWithName: name
						       object: object
							block: block]
	    autorelease];

	[self of_addObserver: handle];

	[handle retain];

	objc_autoreleasePoolPop(pool);

	return [handle autorelease];
}
#endif

- (void)removeObserver: (id)handle_
{
	OFNotificationCenterHandle *handle;
	void *pool;

	if (![handle_ isKindOfClass: [OFNotificationCenterHandle class]])
		@throw [OFInvalidArgumentException exception];

	handle = handle_;
	pool = objc_autoreleasePoolPush();

	if (![handle isKindOfClass: [OFNotificationCenterHandle class]])
		@throw [OFInvalidArgumentException exception];

	@synchronized (_handles) {
		OFNotificationName name = [[handle->_name copy] autorelease];
		OFMutableSet *handlesForName = [_handles objectForKey: name];

		[handlesForName removeObject: handle];

		if (handlesForName.count == 0)
			[_handles removeObjectForKey: name];
	}

	objc_autoreleasePoolPop(pool);
}

- (void)removeObserver: (id)observer
	      selector: (SEL)selector
		  name: (OFNotificationName)name
		object: (id)object
{
	void *pool = objc_autoreleasePoolPush();

	[self removeObserver:
	    [[[OFNotificationCenterHandle alloc] initWithName: name
						     observer: observer
						     selector: selector
						       object: object]
	    autorelease]];

	objc_autoreleasePoolPop(pool);
}

- (void)postNotification: (OFNotification *)notification
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableArray *matchedHandles = [OFMutableArray array];

	@synchronized (_handles) {
		for (OFNotificationCenterHandle *handle in
		    [_handles objectForKey: notification.name])
			if (handle->_object == nil ||
			    handle->_object == notification.object)
				[matchedHandles addObject: handle];
	}

	for (OFNotificationCenterHandle *handle in matchedHandles) {
#ifdef OF_HAVE_BLOCKS
		if (handle->_block != NULL)
			handle->_block(notification);
		else {
#endif
			void (*callback)(id, SEL, OFNotification *) =
			    (void (*)(id, SEL, OFNotification *))
			    [handle->_observer methodForSelector:
			    handle->_selector];

			callback(handle->_observer, handle->_selector,
			    notification);
#ifdef OF_HAVE_BLOCKS
		}
#endif
	}

	objc_autoreleasePoolPop(pool);
}

- (void)postNotificationName: (OFNotificationName)name
		      object: (nullable id)object
{
	[self postNotificationName: name object: object userInfo: nil];
}

- (void)postNotificationName: (OFNotificationName)name
		      object: (nullable id)object
		    userInfo: (nullable OFDictionary *)userInfo
{
	void *pool = objc_autoreleasePoolPush();

	[self postNotification:
	    [OFNotification notificationWithName: name
					  object: object
					userInfo: userInfo]];

	objc_autoreleasePoolPop(pool);
}
@end

@implementation OFDefaultNotificationCenter
OF_SINGLETON_METHODS
@end
