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

#import "OFException.h"

#ifndef OF_HAVE_THREADS
# error No threads available!
#endif

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

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain) OFCondition *condition;
#endif

/*!
 * @brief Creates a new, autoreleased condition signal failed exception.
 *
 * @param condition The condition which could not be signaled
 * @return A new, autoreleased condition signal failed exception
 */
+ (instancetype)exceptionWithCondition: (OFCondition*)condition;

/*!
 * @brief Initializes an already allocated condition signal failed exception.
 *
 * @param condition The condition which could not be signaled
 * @return An initialized condition signal failed exception
 */
- initWithCondition: (OFCondition*)condition;

/*!
 * @brief Return the condition which could not be signaled.
 *
 * @return The condition which could not be signaled
 */
- (OFCondition*)condition;
@end
