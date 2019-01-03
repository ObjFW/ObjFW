/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

@class OFString;

/*!
 * @class OFAllocFailedException \
 *	  OFAllocFailedException.h ObjFW/OFAllocFailedException.h
 *
 * @brief An exception indicating an object could not be allocated.
 *
 * This exception is preallocated, as when there's no memory, no exception can
 * be allocated of course. That's why you shouldn't and even can't deallocate
 * it.
 *
 * This is the only exception which is not an OFException as it's special. It
 * does not know for which class allocation failed and it should not be handled
 * like other exceptions, as the exception handling code is not allowed to
 * allocate *any* memory.
 */
@interface OFAllocFailedException: OFObject
+ (instancetype)exception OF_UNAVAILABLE;
- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Returns a description of the exception.
 *
 * @return A description of the exception
 */
- (OFString *)description;
@end

OF_ASSUME_NONNULL_END
