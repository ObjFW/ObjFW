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
 * @brief An exception indicating that a method or part of it is not
 *        implemented.
 */
@interface OFNotImplementedException: OFException
{
	SEL selector;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) SEL selector;
#endif

/*!
 * @param class_ The class of the object which caused the exception
 * @param selector The selector which is not or not fully implemented
 * @return A new not implemented exception
 */
+ (instancetype)exceptionWithClass: (Class)class_
			  selector: (SEL)selector;

/*!
 * Initializes an already allocated not implemented exception.
 *
 * @param class_ The class of the object which caused the exception
 * @param selector The selector which is not or not fully implemented
 * @return An initialized not implemented exception
 */
- initWithClass: (Class)class_
       selector: (SEL)selector;

/*!
 * @return The selector which is not or not fully implemented
 */
- (SEL)selector;
@end
