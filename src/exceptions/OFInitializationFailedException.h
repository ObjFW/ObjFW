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

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFInitializationFailedException \
 *	  OFInitializationFailedException.h \
 *	  ObjFW/OFInitializationFailedException.h
 *
 * @brief An exception indicating that initializing something failed.
 */
@interface OFInitializationFailedException: OFException
{
	Class _inClass;
}

/*!
 * The class for which initialization failed.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) Class inClass;

/*!
 * @brief Creates a new, autoreleased initialization failed exception.
 *
 * @param class_ The class for which initialization failed
 * @return A new, autoreleased initialization failed exception
 */
+ (instancetype)exceptionWithClass: (nullable Class)class_;

/*!
 * @brief Initializes an already allocated initialization failed exception.
 *
 * @param class_ The class for which initialization failed
 * @return An initialized initialization failed exception
 */
- (instancetype)initWithClass: (nullable Class)class_ OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
