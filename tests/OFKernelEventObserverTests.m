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

#include "config.h"

#import "ObjFW.h"
#import "ObjFWTest.h"

#ifdef HAVE_KQUEUE
# import "OFKqueueKernelEventObserver.h"
#endif
#ifdef HAVE_EPOLL
# import "OFEpollKernelEventObserver.h"
#endif
#ifdef HAVE_POLL
# import "OFPollKernelEventObserver.h"
#endif
#ifdef HAVE_SELECT
# import "OFSelectKernelEventObserver.h"
#endif

@interface OFKernelEventObserverTests: OTTestCase
    <OFKernelEventObserverDelegate>
{
	OFTCPSocket *_server, *_client, *_accepted;
	OFKernelEventObserver *_observer;
	size_t _events;
}
@end

static const size_t numExpectedEvents = 3;

@implementation OFKernelEventObserverTests
- (void)setUp
{
	OFSocketAddress address;

	[super setUp];

	_server = [[OFTCPSocket alloc] init];
	address = [_server bindToHost: @"127.0.0.1" port: 0];
	[_server listen];

	_client = [[OFTCPSocket alloc] init];
	[_client connectToHost: @"127.0.0.1"
			  port: OFSocketAddressIPPort(&address)];
	[_client writeBuffer: "0" length: 1];
}

- (void)dealloc
{
	[_client release];
	[_server release];
	[_accepted release];
	[_observer release];

	[super dealloc];
}

- (void)testKernelEventObserverWithClass: (Class)class
{
	bool deadlineExceeded = false;
	OFDate *deadline;

	_observer = [[class alloc] init];
	_observer.delegate = self;
	[_observer addObjectForReading: _server];

	deadline = [OFDate dateWithTimeIntervalSinceNow: 1];

	while (_events < numExpectedEvents) {
		if (deadline.timeIntervalSinceNow < 0) {
			deadlineExceeded = true;
			break;
		}

		[_observer observeForTimeInterval: 0.01];
	}

	OTAssertFalse(deadlineExceeded);
	OTAssertEqual(_events, numExpectedEvents);
}

- (void)objectIsReadyForReading: (id)object
{
	char buffer;

	switch (_events++) {
	case 0:
		OTAssertEqual(object, _server);

		_accepted = [[object accept] retain];
		[_observer addObjectForReading: _accepted];
		break;
	case 1:
		OTAssert(object, _accepted);

		OTAssertEqual([object readIntoBuffer: &buffer length: 1], 1);
		OTAssertEqual(buffer, '0');

		[_client close];
		break;
	case 2:
		OTAssertEqual(object,  _accepted);

		OTAssertEqual([object readIntoBuffer: &buffer length: 1], 0);
		break;
	default:
		OTAssert(false);
	}
}

#ifdef HAVE_SELECT
- (void)testSelectKernelEventObserver
{
	[self testKernelEventObserverWithClass:
	    [OFSelectKernelEventObserver class]];
}
#endif

#ifdef HAVE_POLL
- (void)testPollKernelEventObserver
{
	[self testKernelEventObserverWithClass:
	    [OFPollKernelEventObserver class]];
}
#endif

#ifdef HAVE_EPOLL
- (void)testEpollKernelEventObserver
{
	[self testKernelEventObserverWithClass:
	    [OFEpollKernelEventObserver class]];
}
#endif

#ifdef HAVE_KQUEUE
- (void)testKqueueKernelEventObserver
{
	[self testKernelEventObserverWithClass:
	    [OFKqueueKernelEventObserver class]];
}
#endif
@end
