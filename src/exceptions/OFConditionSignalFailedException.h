/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#import "OFException.h"

#ifndef OF_HAVE_THREADS
# error No threads available!
#endif

OF_ASSUME_NONNULL_BEGIN

@class OFCondition;

/*!
 * @class OFConditionSignalFailedException \
 *	  OFConditionSignalFailedException.h \
 *	  ObjFW/OFConditionSignalFailedException.h
 *
 * @brief An exception indicating signaling a condition failed.
 */
@interface OFConditionSignalFailedException: OFException
{
	OFCondition *_condition;
}

/*!
 * The condition which could not be signaled.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFCondition *condition;

/*!
 * @brief Creates a new, autoreleased condition signal failed exception.
 *
 * @param condition The condition which could not be signaled
 * @return A new, autoreleased condition signal failed exception
 */
+ (instancetype)exceptionWithCondition: (nullable OFCondition*)condition;

/*!
 * @brief Initializes an already allocated condition signal failed exception.
 *
 * @param condition The condition which could not be signaled
 * @return An initialized condition signal failed exception
 */
- initWithCondition: (nullable OFCondition*)condition;
@end

OF_ASSUME_NONNULL_END
