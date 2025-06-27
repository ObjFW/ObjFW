/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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
 * @class OFTriple OFTriple.h ObjFW/ObjFW.h
 *
 * @brief A class for storing a triple of three objects.
 */
@interface OFTriple OF_GENERIC(FirstType, SecondType, ThirdType):
    OFObject <OFCopying, OFMutableCopying>
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# define FirstType id
# define SecondType id
# define ThirdType id
#endif
{
	FirstType _Nullable _firstObject;
	SecondType _Nullable _secondObject;
	ThirdType _Nullable _thirdObject;
	OF_RESERVE_IVARS(OFTriple, 4)
}

/**
 * @brief The first object of the triple.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic, retain)
    FirstType firstObject;

/**
 * @brief The second object of the triple.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic, retain)
    SecondType secondObject;

/**
 * @brief The third object of the triple.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic, retain)
    ThirdType thirdObject;

/**
 * @brief Creates a new OFTriple with the specified objects.
 *
 * @param firstObject The first object for the triple
 * @param secondObject The second object for the triple
 * @param thirdObject The second object for the triple
 * @return A new, autoreleased OFTriple
 */
+ (instancetype)tripleWithFirstObject: (nullable FirstType)firstObject
			 secondObject: (nullable SecondType)secondObject
			  thirdObject: (nullable ThirdType)thirdObject;

/**
 * @brief Initializes an already allocated OFTriple with the specified objects.
 *
 * @param firstObject The first object for the triple
 * @param secondObject The second object for the triple
 * @param thirdObject The second object for the triple
 * @return An initialized OFTriple
 */
- (instancetype)initWithFirstObject: (nullable FirstType)firstObject
		       secondObject: (nullable SecondType)secondObject
			thirdObject: (nullable ThirdType)thirdObject
    OF_DESIGNATED_INITIALIZER;
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef FirstType
# undef SecondType
# undef ThirdType
#endif
@end

OF_ASSUME_NONNULL_END

#import "OFMutableTriple.h"
