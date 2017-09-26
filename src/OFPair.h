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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFPair OFPair.h ObjFW/OFPair.h
 *
 * @brief A class for storing a pair of two objects.
 */
@interface OFPair OF_GENERIC(FirstType, SecondType): OFObject <OFCopying,
    OFMutableCopying>
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# define FirstType id
# define SecondType id
#endif
{
	FirstType _Nullable _firstObject;
	SecondType _Nullable _secondObject;
}

/*!
 * The first object of the pair.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic, retain)
    FirstType firstObject;

/*!
 * The second object of the pair.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic, retain)
    SecondType secondObject;

/*!
 * @brief Creates a new OFPair with the specified objects.
 *
 * @param firstObject The first object for the pair
 * @param secondObject The second object for the pair
 * @return A new, autoreleased OFPair
 */
+ (instancetype)pairWithFirstObject: (nullable FirstType)firstObject
		       secondObject: (nullable SecondType)secondObject;

/*!
 * @brief Initializes an already allocated OFPair with the specified objects.
 *
 * @param firstObject The first object for the pair
 * @param secondObject The second object for the pair
 * @return An initialized OFPair
 */
- initWithFirstObject: (nullable FirstType)firstObject
	 secondObject: (nullable SecondType)secondObject;
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef FirstType
# undef SecondType
#endif
@end

OF_ASSUME_NONNULL_END

#import "OFMutablePair.h"
