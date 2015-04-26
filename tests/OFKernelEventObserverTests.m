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

#import "TestsAppDelegate.h"

static OFString *module = @"OFKernelEventObserverSocket";
static OFKernelEventObserver *observer;
static int events = 0;
static id expectedObject;
static bool readData = false;

@interface ObserverDelegate: OFObject
- (void)objectIsReadyForReading: (id)object;
@end

@implementation ObserverDelegate
- (void)objectIsReadyForReading: (id)object
{
	events++;

	OF_ENSURE(object == expectedObject);

	if ([object isListening]) {
		OFTCPSocket *client = [object accept];

		[observer addObjectForReading: client];
		[client writeBuffer: "0"
			     length: 1];

		return;
	} else if (readData) {
		char buf;

		[object readIntoBuffer: &buf
				length: 1];

		OF_ENSURE(buf == '0');
	}
}
@end

@implementation TestsAppDelegate (OFKernelEventObserverTests)
- (void)kernelEventObserverTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	ObserverDelegate *delegate =
	    [[[ObserverDelegate alloc] init] autorelease];
	OFTCPSocket *sock1 = [OFTCPSocket socket];
	OFTCPSocket *sock2 = [OFTCPSocket socket];
	uint16_t port;

	port = [sock1 bindToHost: @"127.0.0.1"
			    port: 0];
	[sock1 listen];

	TEST(@"+[observer]",
	    (observer = [OFKernelEventObserver observer]) &&
	    R([observer setDelegate: delegate]))

	TEST(@"-[addObjectForReading:]",
	    R([observer addObjectForReading: sock1]))

	[sock2 connectToHost: @"127.0.0.1"
			port: port];
	TEST(@"-[observe] waiting for connection",
	    (expectedObject = sock1) &&
	    [observer observeForTimeInterval: 0.01] == 1)

	TEST(@"-[observe] waiting for data",
	    (expectedObject = sock2) &&
	    R([observer addObjectForReading: sock2]) &&
	    [observer observeForTimeInterval: 0.01] == 1)

	TEST(@"-[observe] keeping event until read",
	    R(readData = true) && [observer observeForTimeInterval: 0.01] == 1)

	TEST(@"-[observe] time out due to no events",
	    R(readData = false) && [observer observeForTimeInterval: 0.01] == 0)

	TEST(@"-[observe] correct number of events", events == 3)

	[pool drain];
}
@end
