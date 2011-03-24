/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#import "OFObject.h"

@class OFString;

/**
 * \brief An exception indicating an object could not be allocated.
 *
 * This exception is preallocated, as if there's no memory, no exception can
 * be allocated of course. That's why you shouldn't and even can't deallocate
 * it.
 *
 * This is the only exception that is not an OFException as it's special.
 * It does not know for which class allocation failed and it should not be
 * handled like other exceptions, as the exception handling code is not
 * allowed to allocate ANY memory.
 */
@interface OFAllocFailedException: OFObject
/**
 * \return A description of the exception
 */
- (OFString*)description;
@end
