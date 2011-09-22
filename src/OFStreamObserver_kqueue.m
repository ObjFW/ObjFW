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

#include <assert.h>

#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>

#import "OFStreamObserver_kqueue.h"
#import "OFDataArray.h"

#import "OFInitializationFailedException.h"
#import "OFOutOfMemoryException.h"

@interface OFStreamObserver_kqueue (addEventForFileDescriptor)
- (void)_addEventForFileDescriptor: (int)fd
			    filter: (int16_t)filter;
@end

@implementation OFStreamObserver_kqueue
- init
{
	self = [super init];

	@try {
		if ((kernelQueue = kqueue()) == -1)
			@throw [OFInitializationFailedException
			    newWithClass: isa];

		[self _addEventForFileDescriptor: cancelFD[0]
					  filter: EVFILT_READ];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	close(kernelQueue);

	[super dealloc];
}

- (void)_addEventForFileDescriptor: (int)fd
			    filter: (int16_t)filter
{
	struct kevent event, result;

	eventList = [self resizeMemory: eventList
			      toNItems: FDs + 1
				ofSize: sizeof(struct kevent)];

	EV_SET(&event, fd, filter, EV_ADD | EV_RECEIPT, 0, 0, 0);

	if (kevent(kernelQueue, &event, 1, &result, 1, NULL) != 1 ||
	    result.data != 0)
		/* FIXME: Find a better exception */
		@throw [OFInitializationFailedException newWithClass: isa];

	FDs++;
}

- (void)_removeEventForFileDescriptor: (int)fd
			       filter: (int16_t)filter
{
	struct kevent event, result;

	EV_SET(&event, fd, filter, EV_DELETE | EV_RECEIPT, 0, 0, 0);

	if (kevent(kernelQueue, &event, 1, &result, 1, NULL) != 1)
		/* FIXME: Find a better exception */
		@throw [OFInitializationFailedException newWithClass: isa];

	@try {
		eventList = [self resizeMemory: eventList
				      toNItems: FDs - 1
					ofSize: sizeof(struct kevent)];
	} @catch (OFOutOfMemoryException *e) {
		/* We don't care, as we only made it smaller */
		[e release];
	}

	FDs--;
}

- (void)_addFileDescriptorForReading: (int)fd
{
	[self _addEventForFileDescriptor: fd
				  filter: EVFILT_READ];
}

- (void)_addFileDescriptorForWriting: (int)fd
{
	[self _addEventForFileDescriptor: fd
				  filter: EVFILT_WRITE];
}

- (void)_removeFileDescriptorForReading: (int)fd
{
	[self _removeEventForFileDescriptor: fd
				     filter: EVFILT_READ];
}

- (void)_removeFileDescriptorForWriting: (int)fd
{
	[self _removeEventForFileDescriptor: fd
				     filter: EVFILT_WRITE];
}

- (BOOL)observeWithTimeout: (int)timeout
{
	struct timespec timespec = { timeout, 0 };
	int i, events;

	[self _processQueue];

	if ([self _processCache])
		return YES;

	events = kevent(kernelQueue, NULL, 0, eventList, FDs,
	    (timeout == -1 ? NULL : &timespec));

	if (events == -1)
		/* FIXME: Throw something */;
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
