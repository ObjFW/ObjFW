/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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
	OFStreamSocket *_server, *_client, *_accepted;
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

#ifdef OF_HAVE_IPX
	@try {
#endif
		OFTCPSocket *server = [OFTCPSocket socket];
		address = [server bindToHost: @"127.0.0.1" port: 0];

		_server = objc_retain(server);
#ifdef OF_HAVE_IPX
	} @catch (OFBindIPSocketFailedException *e) {
		if (e.errNo != EAFNOSUPPORT)
			@throw e;

		OFSPXStreamSocket *server = [OFSPXStreamSocket socket];
		static const unsigned char zeroNode[IPX_NODE_LEN] = { 0 };
		address = [server bindToNetwork: 0 node: zeroNode port: 0];

		_server = objc_retain(server);
	}
#endif

	[_server listen];

	if ([_server isKindOfClass: [OFTCPSocket class]]) {
		OFTCPSocket *client = [OFTCPSocket socket];
		[client connectToHost: @"127.0.0.1"
				 port: OFSocketAddressIPPort(&address)];

		_client = objc_retain(client);
#ifdef OF_HAVE_IPX
	} else if ([_server isKindOfClass: [OFSPXStreamSocket class]]) {
		OFSPXStreamSocket *client = [OFSPXStreamSocket socket];

		unsigned char node[IPX_NODE_LEN];
		OFSocketAddressGetIPXNode(&address, node);
		[client connectToNetwork: OFSocketAddressIPXNetwork(&address)
				    node: node
				    port: OFSocketAddressIPXPort(&address)];

		_client = objc_retain(client);
#endif
	}


	[_client writeBuffer: "0" length: 1];
}

- (void)dealloc
{
	objc_release(_client);
	objc_release(_server);
	objc_release(_accepted);
	objc_release(_observer);

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

		_accepted = objc_retain([object accept]);
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
