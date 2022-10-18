/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
 * @class OFConditionWaitFailedException \
 *	  OFConditionWaitFailedException.h \
 *	  ObjFW/OFConditionWaitFailedException.h
 *
 * @brief An exception indicating waiting for a condition failed.
 */
@interface OFConditionWaitFailedException: OFException
{
	OFCondition *_condition;
	int _errNo;
	OF_RESERVE_IVARS(OFConditionWaitFailedException, 4)
}

/**
 * @brief The condition for which could not be waited.
 */
@property (readonly, nonatomic) OFCondition *condition;

/**
 * @brief The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

/**
 * @brief Creates a new, autoreleased condition wait failed exception.
 *
 * @param condition The condition for which could not be waited
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased condition wait failed exception
 */
+ (instancetype)exceptionWithCondition: (OFCondition *)condition
				 errNo: (int)errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated condition wait failed exception.
 *
 * @param condition The condition for which could not be waited
 * @param errNo The errno of the error that occurred
 * @return An initialized condition wait failed exception
 */
- (instancetype)initWithCondition: (OFCondition *)condition
			    errNo: (int)errNo OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
