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

#import "TestsAppDelegate.h"

static OFString *const module = @"OFNotificationCenter";
static const OFNotificationName notificationName =
    @"OFNotificationCenterTestName";
static const OFNotificationName otherNotificationName =
    @"OFNotificationCenterTestOtherName";

@interface OFNotificationCenterTest: OFObject
{
@public
	id _expectedObject;
	int _received;
}

- (void)handleNotification: (OFNotification *)notification;
@end

@implementation OFNotificationCenterTest
- (void)handleNotification: (OFNotification *)notification
{
	OFEnsure([notification.name isEqual: notificationName]);
	OFEnsure(_expectedObject == nil ||
	    notification.object == _expectedObject);

	_received++;
}
@end

@implementation TestsAppDelegate (OFNotificationCenterTests)
- (void)notificationCenterTests
{
	void *pool = objc_autoreleasePoolPush();
	OFNotificationCenter *center = [OFNotificationCenter defaultCenter];
	OFNotificationCenterTest *test1, *test2, *test3, *test4;
	OFNotification *notification;

	test1 =
	    [[[OFNotificationCenterTest alloc] init] autorelease];
	test1->_expectedObject = self;
	test2 =
	    [[[OFNotificationCenterTest alloc] init] autorelease];
	test3 =
	    [[[OFNotificationCenterTest alloc] init] autorelease];
	test3->_expectedObject = self;
	test4 =
	    [[[OFNotificationCenterTest alloc] init] autorelease];

	/* First one intentionally added twice to test deduplication. */
	TEST(@"-[addObserver:selector:name:object:]",
	    R([center addObserver: test1
			 selector: @selector(handleNotification:)
			     name: notificationName
			   object: self]) &&
	    R([center addObserver: test1
			 selector: @selector(handleNotification:)
			     name: notificationName
			   object: self]) &&
	    R([center addObserver: test2
			 selector: @selector(handleNotification:)
			     name: notificationName
			   object: nil]) &&
	    R([center addObserver: test3
			 selector: @selector(handleNotification:)
			     name: otherNotificationName
			   object: self]) &&
	    R([center addObserver: test4
			 selector: @selector(handleNotification:)
			     name: otherNotificationName
			   object: nil]))

	notification = [OFNotification notificationWithName: notificationName
						     object: nil];
	TEST(@"-[postNotification:] #1",
	    R([center postNotification: notification]) &&
	    test1->_received == 0 && test2->_received == 1 &&
	    test3->_received == 0 && test4->_received == 0)

	notification = [OFNotification notificationWithName: notificationName
						     object: self];
	TEST(@"-[postNotification:] #2",
	    R([center postNotification: notification]) &&
	    test1->_received == 1 && test2->_received == 2 &&
	    test3->_received == 0 && test4->_received == 0)

	notification = [OFNotification notificationWithName: notificationName
						     object: @"foo"];
	TEST(@"-[postNotification:] #3",
	    R([center postNotification: notification]) &&
	    test1->_received == 1 && test2->_received == 3 &&
	    test3->_received == 0 && test4->_received == 0)

#ifdef OF_HAVE_BLOCKS
	__block bool received = false;
	OFNotificationCenterHandle *handle;

	notification = [OFNotification notificationWithName: notificationName
						     object: self];
	TEST(@"-[addObserverForName:object:usingBlock:]",
	    (handle = [center addObserverForName: notificationName
					  object: self
				      usingBlock: ^ (OFNotification *notif) {
		OFEnsure(notif == notification && !received);
		received = true;
	    }]) && R([center postNotification: notification]) && received &&
	    test1->_received == 2 && test2->_received == 4 &&
	    test3->_received == 0 && test4->_received == 0)

	/* Act like the block test didn't happen. */
	[center removeObserver: handle];
	test1->_received--;
	test2->_received--;
#endif

	TEST(@"-[removeObserver:selector:name:object:]",
	    R([center removeObserver: test1
			    selector: @selector(handleNotification:)
				name: notificationName
			      object: self]) &&
	    R([center removeObserver: test2
			    selector: @selector(handleNotification:)
				name: notificationName
			      object: nil]) &&
	    R([center removeObserver: test3
			    selector: @selector(handleNotification:)
				name: otherNotificationName
			      object: self]) &&
	    R([center removeObserver: test4
			    selector: @selector(handleNotification:)
				name: otherNotificationName
			      object: nil]))

	notification = [OFNotification notificationWithName: notificationName
						     object: self];
	TEST(@"-[postNotification:] with no observers",
	    R([center postNotification: notification]) &&
	    test1->_received == 1 && test2->_received == 3 &&
	    test3->_received == 0 && test4->_received == 0)

	objc_autoreleasePoolPop(pool);
}
@end
