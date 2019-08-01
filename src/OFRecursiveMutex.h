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
#import "OFLocking.h"

#import "mutex.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFRecursiveMutex OFRecursiveMutex.h ObjFW/OFRecursiveMutex.h
 *
 * @brief A class for creating mutual exclusions which can be entered
 *	  recursively.
 */
@interface OFRecursiveMutex: OFObject <OFLocking>
{
	of_rmutex_t _rmutex;
	bool _initialized;
	OFString *_Nullable _name;
}

/*!
 * @brief Creates a new recursive mutex.
 *
 * @return A new autoreleased recursive mutex.
 */
+ (instancetype)mutex;
@end

OF_ASSUME_NONNULL_END
