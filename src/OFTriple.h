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
 * @class OFTriple OFTriple.h ObjFW/OFTriple.h
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
	FirstType _firstObject;
	SecondType _secondObject;
	ThirdType _thirdObject;
}

/*!
 * The first object of the triple.
 */
@property (readonly, nonatomic, retain) FirstType firstObject;

/*!
 * The second object of the triple.
 */
@property (readonly, nonatomic, retain) SecondType secondObject;

/*!
 * The third object of the triple.
 */
@property (readonly, nonatomic, retain) ThirdType thirdObject;

/*!
 * @brief Creates a new OFTriple with the specified objects.
 *
 * @param firstObject The first object for the triple
 * @param secondObject The second object for the triple
 * @param thirdObject The second object for the triple
 * @return A new, autoreleased OFTriple
 */
+ (instancetype)tripleWithFirstObject: (FirstType)firstObject
			 secondObject: (SecondType)secondObject
			  thirdObject: (ThirdType)thirdObject;

/*!
 * @brief Initializes an already allocated OFTriple with the specified objects.
 *
 * @param firstObject The first object for the triple
 * @param secondObject The second object for the triple
 * @param thirdObject The second object for the triple
 * @return An initialized OFTriple
 */
- initWithFirstObject: (FirstType)firstObject
	 secondObject: (SecondType)secondObject
	  thirdObject: (ThirdType)thirdObject;
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef FirstType
# undef SecondType
# undef ThirdType
#endif
@end

OF_ASSUME_NONNULL_END

#import "OFMutableTriple.h"
