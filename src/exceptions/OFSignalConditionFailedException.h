/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#ifndef OF_HAVE_THREADS
# error No threads available!
#endif

OF_ASSUME_NONNULL_BEGIN

@class OFCondition;

/**
 * @class OFSignalConditionFailedException \
 *	  OFSignalConditionFailedException.h \
 *	  ObjFW/OFSignalConditionFailedException.h
 *
 * @brief An exception indicating signaling a condition failed.
 */
@interface OFSignalConditionFailedException: OFException
{
	OFCondition *_condition;
	int _errNo;
	OF_RESERVE_IVARS(OFSignalConditionFailedException, 4)
}

/**
 * @brief The condition which could not be signaled.
 */
@property (readonly, nonatomic) OFCondition *condition;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased condition signal failed exception.
 *
 * @param condition The condition which could not be signaled
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased condition signal failed exception
 */
+ (instancetype)exceptionWithCondition: (OFCondition *)condition
				 errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated condition signal failed exception.
 *
 * @param condition The condition which could not be signaled
 * @param errNo The errno of the error that occurred
 * @return An initialized condition signal failed exception
 */
- (instancetype)initWithCondition: (OFCondition *)condition
			    errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
