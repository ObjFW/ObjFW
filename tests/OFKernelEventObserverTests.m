/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#include "config.h"

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

#import "TestsAppDelegate.h"

#define EXPECTED_EVENTS 3

static OFString *module;

@interface ObserverTest: OFObject <OFKernelEventObserverDelegate>
{
@public
	TestsAppDelegate *_testsAppDelegate;
	OFKernelEventObserver *_observer;
	OFTCPSocket *_server, *_client, *_accepted;
	size_t _events;
	int _fails;
}

- (void)run;
@end

@implementation ObserverTest
- (instancetype)initWithTestsAppDelegate: (TestsAppDelegate *)testsAppDelegate
{
	self = [super init];

	@try {
		uint16_t port;

		_testsAppDelegate = testsAppDelegate;

		_server = [[OFTCPSocket alloc] init];
		port = [_server bindToHost: @"127.0.0.1"
				      port: 0];
		[_server listen];

		_client = [[OFTCPSocket alloc] init];
		[_client connectToHost: @"127.0.0.1"
				  port: port];

		[_client writeBuffer: "0"
			      length: 1];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_server release];
	[_client release];
	[_accepted release];

	[super dealloc];
}

- (void)run
{
	OFDate *deadline;
	bool deadlineExceeded = false;

	[_testsAppDelegate outputTesting: @"-[observe] with listening socket"
				inModule: module];

	deadline = [OFDate dateWithTimeIntervalSinceNow: 1];
	while (_events < EXPECTED_EVENTS) {
		if (deadline.timeIntervalSinceNow < 0) {
			deadlineExceeded = true;
			break;
		}

		[_observer observeForTimeInterval: 0.01];
	}

	if (!deadlineExceeded)
		[_testsAppDelegate
		    outputSuccess: @"-[observe] not exceeding deadline"
			 inModule: module];
	else {
		[_testsAppDelegate
		    outputFailure: @"-[observe] not exceeding deadline"
			 inModule: module];
		_fails++;
	}

	if (_events == EXPECTED_EVENTS)
		[_testsAppDelegate
		    outputSuccess: @"-[observe] handling all events"
			 inModule: module];
	else {
		[_testsAppDelegate
		    outputFailure: @"-[observe] handling all events"
			 inModule: module];
		_fails++;
	}
}

- (void)objectIsReadyForReading: (id)object
{
	char buf;

	switch (_events++) {
	case 0:
		if (object == _server)
			[_testsAppDelegate
			    outputSuccess: @"-[observe] with listening socket"
				 inModule: module];
		else {
			[_testsAppDelegate
			    outputFailure: @"-[observe] with listening socket"
				 inModule: module];
			_fails++;
		}

		_accepted = [[object accept] retain];
		[_observer addObjectForReading: _accepted];

		[_testsAppDelegate
		    outputTesting: @"-[observe] with data ready to read"
			 inModule: module];

		break;
	case 1:
		if (object == _accepted &&
		    [object readIntoBuffer: &buf
				    length: 1] == 1 && buf == '0')
			[_testsAppDelegate
			    outputSuccess: @"-[observe] with data ready to read"
				 inModule: module];
		else {
			[_testsAppDelegate
			    outputFailure: @"-[observe] with data ready to read"
				 inModule: module];
			_fails++;
		}

		[_client close];

		[_testsAppDelegate
		    outputTesting: @"-[observe] with closed connection"
			 inModule: module];

		break;
	case 2:
		if (object == _accepted &&
		    [object readIntoBuffer: &buf
				    length: 1] == 0)
			[_testsAppDelegate
			    outputSuccess: @"-[observe] with closed connection"
				 inModule: module];
		else {
			[_testsAppDelegate
			    outputFailure: @"-[observe] with closed connection"
				 inModule: module];
			_fails++;
		}

		break;
	default:
		OF_ENSURE(0);
	}
}
@end

@implementation TestsAppDelegate (OFKernelEventObserverTests)
- (void)kernelEventObserverTestsWithClass: (Class)class
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	ObserverTest *test;

	module = [class className];
	test = [[[ObserverTest alloc]
	    initWithTestsAppDelegate: self] autorelease];

	TEST(@"+[observer]", (test->_observer = [class observer]))
	test->_observer.delegate = test;

	TEST(@"-[addObjectForReading:]",
	    R([test->_observer addObjectForReading: test->_server]))

	[test run];
	_fails += test->_fails;

	[pool drain];
}

- (void)kernelEventObserverTests
{
#ifdef HAVE_SELECT
	[self kernelEventObserverTestsWithClass:
	    [OFSelectKernelEventObserver class]];
#endif

#ifdef HAVE_POLL
	[self kernelEventObserverTestsWithClass:
	    [OFPollKernelEventObserver class]];
#endif

#ifdef HAVE_EPOLL
	[self kernelEventObserverTestsWithClass:
	    [OFEpollKernelEventObserver class]];
#endif

#ifdef HAVE_KQUEUE
	[self kernelEventObserverTestsWithClass:
	    [OFKqueueKernelEventObserver class]];
#endif
}
@end
