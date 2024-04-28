/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

/**
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
	OF_RESERVE_IVARS(OFPair, 4)
}

/**
 * @brief The first object of the pair.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic, retain)
    FirstType firstObject;

/**
 * @brief The second object of the pair.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic, retain)
    SecondType secondObject;

/**
 * @brief Creates a new OFPair with the specified objects.
 *
 * @param firstObject The first object for the pair
 * @param secondObject The second object for the pair
 * @return A new, autoreleased OFPair
 */
+ (instancetype)pairWithFirstObject: (nullable FirstType)firstObject
		       secondObject: (nullable SecondType)secondObject;

/**
 * @brief Initializes an already allocated OFPair with the specified objects.
 *
 * @param firstObject The first object for the pair
 * @param secondObject The second object for the pair
 * @return An initialized OFPair
 */
- (instancetype)initWithFirstObject: (nullable FirstType)firstObject
		       secondObject: (nullable SecondType)secondObject
    OF_DESIGNATED_INITIALIZER;
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef FirstType
# undef SecondType
#endif
@end

OF_ASSUME_NONNULL_END

#import "OFMutablePair.h"
