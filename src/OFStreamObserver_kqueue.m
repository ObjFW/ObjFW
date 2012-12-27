/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#include <unistd.h>
#include <errno.h>

#include <assert.h>

#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>

#import "OFStreamObserver_kqueue.h"
#import "OFDataArray.h"

#import "OFInitializationFailedException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

#import "autorelease.h"
#import "macros.h"

#define EVENTLIST_SIZE 64

@implementation OFStreamObserver_kqueue
- init
{
	self = [super init];

	@try {
		if ((kernelQueue = kqueue()) == -1)
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

		changeList = [[OFDataArray alloc] initWithItemSize:
		    sizeof(struct kevent)];

		[self OF_addFileDescriptorForReading: cancelFD[0]];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	close(kernelQueue);
	[changeList release];

	[super dealloc];
}

- (void)OF_addFileDescriptorForReading: (int)fd
{
	struct kevent event;

	if ([changeList count] >= INT_MAX)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	EV_SET(&event, fd, EVFILT_READ, EV_ADD, 0, 0, 0);
	[changeList addItem: &event];
}

- (void)OF_addFileDescriptorForWriting: (int)fd
{
	struct kevent event;

	if ([changeList count] >= INT_MAX)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	EV_SET(&event, fd, EVFILT_WRITE, EV_ADD, 0, 0, 0);
	[changeList addItem: &event];
}

- (void)OF_removeFileDescriptorForReading: (int)fd
{
	struct kevent event;

	EV_SET(&event, fd, EVFILT_READ, EV_DELETE, 0, 0, 0);
	[changeList addItem: &event];
}

- (void)OF_removeFileDescriptorForWriting: (int)fd
{
	struct kevent event;

	EV_SET(&event, fd, EVFILT_WRITE, EV_DELETE, 0, 0, 0);
	[changeList addItem: &event];
}

- (BOOL)observeWithTimeout: (double)timeout
{
	void *pool = objc_autoreleasePoolPush();
	struct timespec timespec;
	struct kevent eventList[EVENTLIST_SIZE];
	int i, events, realEvents = 0;

	timespec.tv_sec = (time_t)timeout;
	timespec.tv_nsec = (long)((timeout - timespec.tv_sec) * 1000000000);

	[self OF_processQueue];

	if ([self OF_processCache]) {
		objc_autoreleasePoolPop(pool);
		return YES;
	}

	objc_autoreleasePoolPop(pool);

	events = kevent(kernelQueue, [changeList items],
	    (int)[changeList count], eventList, EVENTLIST_SIZE,
	    (timeout == -1 ? NULL : &timespec));

	if (events < 0)
		return NO;

	[changeList removeAllItems];

	if (events == 0)
		return NO;

	for (i = 0; i < events; i++) {
		if (eventList[i].ident == cancelFD[0]) {
			char buffer;

			OF_ENSURE(read(cancelFD[0], &buffer, 1) > 0);

			continue;
		}

		realEvents++;

		pool = objc_autoreleasePoolPush();

		if (eventList[i].flags & EV_ERROR) {
			if ([delegate respondsToSelector:
			    @selector(streamDidReceiveException:)])
				[delegate streamDidReceiveException:
				    FDToStream[eventList[i].ident]];

			objc_autoreleasePoolPop(pool);
			continue;
		}

		switch (eventList[i].filter) {
		case EVFILT_READ:
			if ([delegate respondsToSelector:
			    @selector(streamIsReadyForReading:)])
				[delegate streamIsReadyForReading:
				    FDToStream[eventList[i].ident]];
			break;
		case EVFILT_WRITE:
			if ([delegate respondsToSelector:
			    @selector(streamIsReadyForWriting:)])
				[delegate streamIsReadyForWriting:
				    FDToStream[eventList[i].ident]];
			break;
		default:
			assert(0);
		}

		objc_autoreleasePoolPop(pool);
	}

	if (realEvents == 0)
		return NO;

	return YES;
}
@end
