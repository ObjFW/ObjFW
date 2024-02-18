/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "ObjFW.h"
#import "ObjFWTest.h"

static const OFNotificationName notificationName =
    @"OFNotificationCenterTestName";
static const OFNotificationName otherNotificationName =
    @"OFNotificationCenterTestOtherName";

@interface OFNotificationCenterTests: OTTestCase
@end

@interface OFNotificationCenterTestClass: OFObject
{
@public
	id _expectedObject;
	int _received;
}

- (void)handleNotification: (OFNotification *)notification;
@end

@implementation OFNotificationCenterTestClass
- (void)handleNotification: (OFNotification *)notification
{
	OFEnsure([notification.name isEqual: notificationName]);
	OFEnsure(_expectedObject == nil ||
	    notification.object == _expectedObject);

	_received++;
}
@end

@implementation OFNotificationCenterTests
- (void)testNotificationCenter
{
	OFNotificationCenter *center = [OFNotificationCenter defaultCenter];
	OFNotificationCenterTestClass *test1, *test2, *test3, *test4;
	OFNotification *notification;

	test1 = [[[OFNotificationCenterTestClass alloc] init] autorelease];
	test1->_expectedObject = self;
	test2 = [[[OFNotificationCenterTestClass alloc] init] autorelease];
	test3 = [[[OFNotificationCenterTestClass alloc] init] autorelease];
	test3->_expectedObject = self;
	test4 = [[[OFNotificationCenterTestClass alloc] init] autorelease];

	/* First one intentionally added twice to test deduplication. */
	[center addObserver: test1
		   selector: @selector(handleNotification:)
		       name: notificationName
		     object: self];
	[center addObserver: test1
		   selector: @selector(handleNotification:)
		       name: notificationName
		     object: self];
	[center addObserver: test2
		   selector: @selector(handleNotification:)
		       name: notificationName
		     object: nil];
	[center addObserver: test3
		   selector: @selector(handleNotification:)
		       name: otherNotificationName
		     object: self];
	[center addObserver: test4
		   selector: @selector(handleNotification:)
		       name: otherNotificationName
		     object: nil];

	notification = [OFNotification notificationWithName: notificationName
						     object: nil];
	[center postNotification: notification];
	OTAssertEqual(test1->_received, 0);
	OTAssertEqual(test2->_received, 1);
	OTAssertEqual(test3->_received, 0);
	OTAssertEqual(test4->_received, 0);

	notification = [OFNotification notificationWithName: notificationName
						     object: self];
	[center postNotification: notification];
	OTAssertEqual(test1->_received, 1);
	OTAssertEqual(test2->_received, 2);
	OTAssertEqual(test3->_received, 0);
	OTAssertEqual(test4->_received, 0);

	notification = [OFNotification notificationWithName: notificationName
						     object: @"foo"];
	[center postNotification: notification];
	OTAssertEqual(test1->_received, 1);
	OTAssertEqual(test2->_received, 3);
	OTAssertEqual(test3->_received, 0);
	OTAssertEqual(test4->_received, 0);

#ifdef OF_HAVE_BLOCKS
	__block bool received = false;
	id handle;

	notification = [OFNotification notificationWithName: notificationName
						     object: self];
	handle = [center addObserverForName: notificationName
				     object: self
				 usingBlock: ^ (OFNotification *notification_) {
		OTAssertEqual(notification_, notification);
		OTAssertFalse(received);
		received = true;
	    }];
	[center postNotification: notification];
	OTAssertTrue(received);
	OTAssertEqual(test1->_received, 2);
	OTAssertEqual(test2->_received, 4);
	OTAssertEqual(test3->_received, 0);
	OTAssertEqual(test4->_received, 0);

	/* Act like the block test didn't happen. */
	[center removeObserver: handle];
	test1->_received--;
	test2->_received--;
#endif

	[center removeObserver: test1
		      selector: @selector(handleNotification:)
			  name: notificationName
			object: self];
	[center removeObserver: test2
		      selector: @selector(handleNotification:)
			  name: notificationName
			object: nil];
	[center removeObserver: test3
		      selector: @selector(handleNotification:)
			  name: otherNotificationName
			object: self];
	[center removeObserver: test4
		      selector: @selector(handleNotification:)
			  name: otherNotificationName
			object: nil];

	notification = [OFNotification notificationWithName: notificationName
						     object: self];
	[center postNotification: notification];
	OTAssertEqual(test1->_received, 1);
	OTAssertEqual(test2->_received, 3);
	OTAssertEqual(test3->_received, 0);
	OTAssertEqual(test4->_received, 0);
}
@end
