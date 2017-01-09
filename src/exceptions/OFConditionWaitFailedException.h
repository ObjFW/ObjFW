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

@class OFCondition;

/*!
 * @class OFConditionWaitFailedException \
 *	  OFConditionWaitFailedException.h \
 *	  ObjFW/OFConditionWaitFailedException.h
 *
 * @brief An exception indicating waiting for a condition failed.
 */
@interface OFConditionWaitFailedException: OFException
{
	OFCondition *_condition;
}

/*!
 * The condition for which could not be waited.
 */
@property (readonly, retain) OFCondition *condition;

/*!
 * @brief Creates a new, autoreleased condition wait failed exception.
 *
 * @param condition The condition for which could not be waited
 * @return A new, autoreleased condition wait failed exception
 */
+ (instancetype)exceptionWithCondition: (OFCondition*)condition;

/*!
 * @brief Initializes an already allocated condition wait failed exception.
 *
 * @param condition The condition for which could not be waited
 * @return An initialized condition wait failed exception
 */
- initWithCondition: (OFCondition*)condition;
@end
