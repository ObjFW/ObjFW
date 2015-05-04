/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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

#include "config.h"

#import "OFKernelEventObserver.h"
#import "OFString.h"
#import "OFTCPSocket.h"
#import "OFAutoreleasePool.h"

#if defined(HAVE_SYS_SELECT_H) || defined(_WIN32)
# import "OFKernelEventObserver_select.h"
#endif
#if defined(HAVE_POLL_H) || defined(__wii__)
# import "OFKernelEventObserver_poll.h"
#endif
#ifdef HAVE_EPOLL
# import "OFKernelEventObserver_epoll.h"
#endif
#ifdef HAVE_KQUEUE
# import "OFKernelEventObserver_kqueue.h"
#endif

#import "TestsAppDelegate.h"

static OFString *module;
static OFKernelEventObserver *observer;
static int events;
static id expectedObject;
static bool readData, expectEOS;
static OFTCPSocket *accepted;

@interface ObserverDelegate: OFObject
- (void)objectIsReadyForReading: (id)object;
@end

@implementation ObserverDelegate
- (void)objectIsReadyForReading: (id)object
{
	events++;

	OF_ENSURE(object == expectedObject);

	if ([object isListening]) {
		accepted = [[object accept] retain];

		[accepted writeBuffer: "0"
			       length: 1];
	} else if (readData) {
		char buf;

		if (expectEOS)
			OF_ENSURE([object readIntoBuffer: &buf
						  length: 1] == 0);
		else {
			OF_ENSURE([object readIntoBuffer: &buf
						  length: 1] == 1);
			OF_ENSURE(buf == '0');
		}
	}
}
@end

@implementation TestsAppDelegate (OFKernelEventObserverTests)
- (void)kernelEventObserverTestsWithClass: (Class)class
{
	ObserverDelegate *delegate =
	    [[[ObserverDelegate alloc] init] autorelease];
	OFTCPSocket *sock1 = [OFTCPSocket socket];
	OFTCPSocket *sock2 = [OFTCPSocket socket];
	uint16_t port;

	module = [class className];
	events = 0;
	expectedObject = nil;
	readData = expectEOS = false;
	accepted = nil;

	port = [sock1 bindToHost: @"127.0.0.1"
			    port: 0];
	[sock1 listen];

	TEST(@"+[observer]",
	    (observer = [class observer]) &&
	    R([observer setDelegate: delegate]))

	TEST(@"-[addObjectForReading:]",
	    R([observer addObjectForReading: sock1]))

	[sock2 connectToHost: @"127.0.0.1"
			port: port];
	TEST(@"-[observe] waiting for connection",
	    (expectedObject = sock1) &&
	    [observer observeForTimeInterval: 0.01])
	[accepted autorelease];

	TEST(@"-[observe] waiting for data",
	    (expectedObject = sock2) &&
	    R([observer addObjectForReading: sock2]) &&
	    [observer observeForTimeInterval: 0.01])

	TEST(@"-[observe] keeping event until read",
	    R(readData = true) && [observer observeForTimeInterval: 0.01])

	TEST(@"-[observe] time out due to no events",
	    R(readData = false) && ![observer observeForTimeInterval: 0.01])

	[accepted close];
	TEST(@"-[observe] closed connection",
	    R(readData = true) && R(expectEOS = true) &&
	    [observer observeForTimeInterval: 0.01])

	TEST(@"-[observe] correct number of events", events == 4)
}

- (void)kernelEventObserverTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

#if defined(HAVE_SYS_SELECT_H) || defined(_WIN32)
	[self kernelEventObserverTestsWithClass:
	    [OFKernelEventObserver_select class]];
#endif

#if defined(HAVE_POLL_H) || defined(__wii__)
	[self kernelEventObserverTestsWithClass:
	    [OFKernelEventObserver_poll class]];
#endif

#ifdef HAVE_EPOLL
	[self kernelEventObserverTestsWithClass:
	    [OFKernelEventObserver_epoll class]];
#endif

#ifdef HAVE_KQUEUE
	[self kernelEventObserverTestsWithClass:
	    [OFKernelEventObserver_kqueue class]];
#endif

	[pool drain];
}
@end
