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

/*!
 * @brief An exception indicating that the argument is invalid for this method.
 */
@interface OFInvalidArgumentException: OFException
{
	SEL selector;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) SEL selector;
#endif

/*!
 * @brief Creates a new, autoreleased invalid argument exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param selector The selector which doesn't accept the argument
 * @return A new, autoreleased invalid argument exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			  selector: (SEL)selector;

/*!
 * @brief Initializes an already allocated invalid argument exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param selector The selector which doesn't accept the argument
 * @return An initialized invalid argument exception
 */
- initWithClass: (Class)class_
       selector: (SEL)selector;

/*!
 * @brief Returns the selector to which an invalid argument was passed.
 *
 * @return The selector to which an invalid argument was passed
 */
- (SEL)selector;
@end
