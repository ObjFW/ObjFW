/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#import "OFKernelEventObserver.h"

OF_ASSUME_NONNULL_BEGIN

@class OFMutableArray OF_GENERIC(ObjectType);
@class OFDataArray;

@interface OFKernelEventObserver_LockedQueue: OFKernelEventObserver
{
	OFDataArray *_queueActions, *_queueFDs;
	OFMutableArray *_queueObjects;
}

- (void)OF_addObjectForReading: (id)object
		fileDescriptor: (int)fd;
- (void)OF_addObjectForWriting: (id)object
		fileDescriptor: (int)fd;
- (void)OF_removeObjectForReading: (id)object
		   fileDescriptor: (int)fd;
- (void)OF_removeObjectForWriting: (id)object
		   fileDescriptor: (int)fd;
- (void)OF_processQueue;
@end

OF_ASSUME_NONNULL_END
