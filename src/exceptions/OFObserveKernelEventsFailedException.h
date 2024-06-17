/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

@class OFKernelEventObserver;

/**
 * @class OFObserveKernelEventsFailedException
 *	  OFObserveKernelEventsFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that observing failed.
 */
@interface OFObserveKernelEventsFailedException: OFException
{
	OFKernelEventObserver *_observer;
	int _errNo;
	OF_RESERVE_IVARS(OFObserveKernelEventsFailedException, 4)
}

/**
 * @brief The observer which failed to observe.
 */
@property (readonly, nonatomic) OFKernelEventObserver *observer;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased observe failed exception.
 *
 * @param observer The observer which failed to observe
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased observe failed exception
 */
+ (instancetype)exceptionWithObserver: (OFKernelEventObserver *)observer
				errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated observe failed exception.
 *
 * @param observer The observer which failed to observe
 * @param errNo The errno of the error that occurred
 * @return An initialized observe failed exception
 */
- (instancetype)initWithObserver: (OFKernelEventObserver *)observer
			   errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
