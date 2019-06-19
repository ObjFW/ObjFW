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

@class OFArray OF_GENERIC(ObjectType);
@class OFEnumerator OF_GENERIC(ObjectType);

/*!
 * @protocol OFEnumerating OFEnumerator.h ObjFW/OFEnumerator.h
 *
 * @brief A protocol for getting an enumerator for the object.
 */
@protocol OFEnumerating
/*!
 * @brief Returns an OFEnumerator to enumerate through all objects of the
 *	  collection.
 *
 * @return An OFEnumerator to enumerate through all objects of the collection
 */
- (OFEnumerator *)objectEnumerator;
@end

/*
 * This needs to be exactly like this because it's hard-coded in the compiler.
 *
 * We need this bad check to see if we already imported Cocoa, which defines
 * this as well.
 */
/*!
 * @struct of_fast_enumeration_state_t OFEnumerator.h ObjFW/OFEnumerator.h
 *
 * @brief State information for fast enumerations.
 */
#define of_fast_enumeration_state_t NSFastEnumerationState
#ifndef NSINTEGER_DEFINED
typedef struct {
	/*! Arbitrary state information for the enumeration */
	unsigned long state;
	/*! Pointer to a C array of objects to return */
	id const __unsafe_unretained _Nullable *_Nullable itemsPtr;
	/*! Arbitrary state information to detect mutations */
	unsigned long *_Nullable mutationsPtr;
	/*! Additional arbitrary state information */
	unsigned long extra[5];
} of_fast_enumeration_state_t;
#endif

/*!
 * @protocol OFFastEnumeration OFEnumerator.h ObjFW/OFEnumerator.h
 *
 * @brief A protocol for fast enumeration.
 *
 * The OFFastEnumeration protocol needs to be implemented by all classes
 * supporting fast enumeration.
 */
@protocol OFFastEnumeration
/*!
 * @brief A method which is called by the code produced by the compiler when
 *	  doing a fast enumeration.
 *
 * @param state Context information for the enumeration
 * @param objects A pointer to an array where to put the objects
 * @param count The number of objects that can be stored at objects
 * @return The number of objects returned in objects or 0 when the enumeration
 *	   finished.
 */
- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t *)state
			   objects: (id __unsafe_unretained _Nonnull *_Nonnull)
					objects
			     count: (int)count;
@end

/*!
 * @class OFEnumerator OFEnumerator.h ObjFW/OFEnumerator.h
 *
 * @brief A class which provides methods to enumerate through collections.
 */
@interface OFEnumerator OF_GENERIC(ObjectType): OFObject <OFFastEnumeration>
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# define ObjectType id
#endif
/*!
 * @brief Returns the next object or `nil` if there is none left.
 *
 * @return The next object or `nil` if there is none left
 */
- (nullable ObjectType)nextObject;

/*!
 * @brief Returns an array of all remaining objects in the collection.
 *
 * @return An array of all remaining objects in the collection.
 */
- (OFArray OF_GENERIC(ObjectType) *)allObjects;
#if !defined(OF_HAVE_GENERICS) && !defined(DOXYGEN)
# undef ObjectType
#endif
@end

OF_ASSUME_NONNULL_END
