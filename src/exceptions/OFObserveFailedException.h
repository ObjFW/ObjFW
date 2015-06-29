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

#import "OFException.h"

@class OFKernelEventObserver;

/*!
 * @class OFObserveFailedException \
 *	  OFObserveFailedException.h ObjFW/OFObserveFailedException.h
 *
 * @brief An exception indicating that observing failed.
 */
@interface OFObserveFailedException: OFException
{
	OFKernelEventObserver *_observer;
	int _errNo;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain) OFKernelEventObserver *observer;
@property (readonly) int errNo;
#endif

/*!
 * @brief Creates a new, autoreleased observe failed exception.
 *
 * @param observer The observer which failed to observe
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased observe failed exception
 */
+ (instancetype)exceptionWithObserver: (OFKernelEventObserver*)observer
				errNo: (int)errNo;

/*!
 * @brief Initializes an already allocated observe failed exception.
 *
 * @param observer The observer which failed to observe
 * @param errNo The errno of the error that occurred
 * @return An initialized observe failed exception
 */
- initWithObserver: (OFKernelEventObserver*)observer
	     errNo: (int)errNo;

/*!
 * @brief Returns the observer which failed to observe.
 *
 * @return The observer which failed to observe
 */
- (OFKernelEventObserver*)observer;

/*!
 * @brief Returns the errno of the error that occurred.
 *
 * @return The errno of the error that occurred
 */
- (int)errNo;
@end
