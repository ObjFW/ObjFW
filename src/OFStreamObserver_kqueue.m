/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#define EVENTLIST_SIZE 64

@implementation OFStreamObserver_kqueue
- init
{
	self = [super init];

	@try {
		if ((kernelQueue = kqueue()) == -1)
			@throw [OFInitializationFailedException
			    exceptionWithClass: isa];

		changeList = [[OFDataArray alloc] initWithItemSize:
		    sizeof(struct kevent)];

		[self _addFileDescriptorForReading: cancelFD[0]];
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

- (void)_addFileDescriptorForReading: (int)fd
{
	struct kevent event;

	EV_SET(&event, fd, EVFILT_READ, EV_ADD, 0, 0, 0);
	[changeList addItem: &event];
}

- (void)_addFileDescriptorForWriting: (int)fd
{
	struct kevent event;

	EV_SET(&event, fd, EVFILT_WRITE, EV_ADD, 0, 0, 0);
	[changeList addItem: &event];
}

- (void)_removeFileDescriptorForReading: (int)fd
{
	struct kevent event;

	EV_SET(&event, fd, EVFILT_READ, EV_DELETE, 0, 0, 0);
	[changeList addItem: &event];
}

- (void)_removeFileDescriptorForWriting: (int)fd
{
	struct kevent event;

	EV_SET(&event, fd, EVFILT_WRITE, EV_DELETE, 0, 0, 0);
	[changeList addItem: &event];
}

- (BOOL)observeWithTimeout: (int)timeout
{
	struct timespec timespec = { timeout, 0 };
	struct kevent eventList[EVENTLIST_SIZE];
	int i, events;

	[self _processQueue];

	if ([self _processCache])
		return YES;

	events = kevent(kernelQueue, [changeList cArray],
	    (int)[changeList count], eventList, EVENTLIST_SIZE,
	    (timeout == -1 ? NULL : &timespec));

	if (events == -1) {
		switch (errno) {
		case EINTR:
			return NO;
		case ENOMEM:
			@throw [OFOutOfMemoryException exceptionWithClass: isa];
		default:
			assert(0);
		}
	}

	[changeList removeNItems: [changeList count]];

	if (events == 0)
		return NO;

	for (i = 0; i < events; i++) {
		if (eventList[i].ident == cancelFD[0]) {
			char buffer;

			assert(read(cancelFD[0], &buffer, 1) > 0);

			continue;
		}

		if (eventList[i].flags & EV_ERROR) {
			[delegate streamDidReceiveException:
			    FDToStream[eventList[i].ident]];
			continue;
		}

		switch (eventList[i].filter) {
		case EVFILT_READ:
			[delegate streamIsReadyForReading:
			    FDToStream[eventList[i].ident]];
			break;
		case EVFILT_WRITE:
			[delegate streamIsReadyForWriting:
			    FDToStream[eventList[i].ident]];
		default:
			assert(0);
		}
	}

	return YES;
}
@end
