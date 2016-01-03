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

#import "OFKernelEventObserver_LockedQueue.h"
#import "OFArray.h"
#import "OFDataArray.h"
#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
#endif

#import "OFInitializationFailedException.h"

enum {
	QUEUE_ADD = 0,
	QUEUE_REMOVE = 1,
	QUEUE_READ = 0,
	QUEUE_WRITE = 2
};
#define QUEUE_ACTION (QUEUE_ADD | QUEUE_REMOVE)

@implementation OFKernelEventObserver_LockedQueue
- init
{
	self = [super init];

	@try {
		_queueActions = [[OFDataArray alloc]
		    initWithItemSize: sizeof(int)];
		_queueFDs = [[OFDataArray alloc] initWithItemSize: sizeof(int)];
		_queueObjects = [[OFMutableArray alloc] init];
	} @catch (id e) {
		@throw [OFInitializationFailedException
		    exceptionWithClass: [self class]];
	}

	return self;
}

- (void)dealloc
{
	[_queueActions release];
	[_queueFDs release];
	[_queueObjects release];

	[super dealloc];
}

- (void)addObjectForReading: (id <OFReadyForReadingObserving>)object
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
	@try {
#endif
		int qi = QUEUE_ADD | QUEUE_READ;
		int fd = [object fileDescriptorForReading];

		[_queueActions addItem: &qi];
		[_queueFDs addItem: &fd];
		[_queueObjects addObject: object];
#ifdef OF_HAVE_THREADS
	} @finally {
		[_mutex unlock];
	}
#endif

	[self cancel];
}

- (void)addObjectForWriting: (id <OFReadyForWritingObserving>)object
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
	@try {
#endif
		int qi = QUEUE_ADD | QUEUE_WRITE;
		int fd = [object fileDescriptorForWriting];

		[_queueActions addItem: &qi];
		[_queueFDs addItem: &fd];
		[_queueObjects addObject: object];
#ifdef OF_HAVE_THREADS
	} @finally {
		[_mutex unlock];
	}
#endif

	[self cancel];
}

- (void)removeObjectForReading: (id <OFReadyForReadingObserving>)object
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
	@try {
#endif
		int qi = QUEUE_REMOVE | QUEUE_READ;
		int fd = [object fileDescriptorForReading];

		[_queueActions addItem: &qi];
		[_queueFDs addItem: &fd];
		[_queueObjects addObject: object];
#ifdef OF_HAVE_THREADS
	} @finally {
		[_mutex unlock];
	}
#endif

	[self cancel];
}

- (void)removeObjectForWriting: (id <OFReadyForWritingObserving>)object
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
	@try {
#endif
		int qi = QUEUE_REMOVE | QUEUE_WRITE;
		int fd = [object fileDescriptorForWriting];

		[_queueActions addItem: &qi];
		[_queueFDs addItem: &fd];
		[_queueObjects addObject: object];
#ifdef OF_HAVE_THREADS
	} @finally {
		[_mutex unlock];
	}
#endif

	[self cancel];
}

- (void)OF_addObjectForReading: (id)object
		fileDescriptor: (int)fd
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)OF_addObjectForWriting: (id)object
		fileDescriptor: (int)fd
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)OF_removeObjectForReading: (id)object
		   fileDescriptor: (int)fd
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)OF_removeObjectForWriting: (id)object
		   fileDescriptor: (int)fd
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)OF_processQueue
{
#ifdef OF_HAVE_THREADS
	[_mutex lock];
	@try {
#endif
		int *queueActions = [_queueActions items];
		int *queueFDs = [_queueFDs items];
		id const *queueObjects = [_queueObjects objects];
		size_t i, count = [_queueActions count];

		OF_ENSURE([_queueFDs count] == count);
		OF_ENSURE([_queueObjects count] == count);

		for (i = 0; i < count; i++) {
			int action = queueActions[i];
			int fd = queueFDs[i];
			id object = queueObjects[i];

			switch (action) {
			case QUEUE_ADD | QUEUE_READ:
				[_readObjects addObject: object];

				[self OF_addObjectForReading: object
					      fileDescriptor: fd];

				break;
			case QUEUE_ADD | QUEUE_WRITE:
				[_writeObjects addObject: object];

				[self OF_addObjectForWriting: object
					      fileDescriptor: fd];

				break;
			case QUEUE_REMOVE | QUEUE_READ:
				[self OF_removeObjectForReading: object
						 fileDescriptor: fd];

				[_readObjects removeObjectIdenticalTo: object];

				break;
			case QUEUE_REMOVE | QUEUE_WRITE:
				[self OF_removeObjectForWriting: object
						 fileDescriptor: fd];

				[_writeObjects removeObjectIdenticalTo: object];

				break;
			default:
				OF_ENSURE(0);
			}
		}

		[_queueActions removeAllItems];
		[_queueFDs removeAllItems];
		[_queueObjects removeAllObjects];
#ifdef OF_HAVE_THREADS
	} @finally {
		[_mutex unlock];
	}
#endif
}
@end
