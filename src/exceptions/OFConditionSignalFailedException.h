/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

@class OFCondition;

/*!
 * @brief An exception indicating signaling a condition failed.
 */
@interface OFConditionSignalFailedException: OFException
{
	OFCondition *condition;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain, nonatomic) OFCondition *condition;
#endif

/*!
 * @param class_ The class of the object which caused the exception
 * @param condition The condition which could not be signaled
 * @return A new condition signal failed exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			 condition: (OFCondition*)condition;

/*!
 * Initializes an already allocated condition signal failed exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param condition The condition which could not be signaled
 * @return An initialized condition signal failed exception
 */
- initWithClass: (Class)class_
      condition: (OFCondition*)condition;

/*!
 * @return The condition which could not be signaled
 */
- (OFCondition*)condition;
@end
