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

/**
 * \brief An exception indicating that a thread is still waiting for a
 *	  condition.
 */
@interface OFConditionStillWaitingException: OFException
{
	OFCondition *condition;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, retain, nonatomic) OFCondition *condition;
#endif

/**
 * \param class_ The class of the object which caused the exception
 * \param condition The condition for which is still being waited
 * \return A new condition still waiting exception
 */
+ exceptionWithClass: (Class)class_
	   condition: (OFCondition*)condition;

/**
 * Initializes an already allocated condition still waiting exception.
 *
 * \param class_ The class of the object which caused the exception
 * \param condition The condition for which is still being waited
 * \return An initialized condition still waiting exception
 */
- initWithClass: (Class)class_
      condition: (OFCondition*)condition;

/**
 * \return The condition for which is still being waited
 */
- (OFCondition*)condition;
@end
