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
@class OFArray;
@class OFMutableArray;

/**
 * \brief A class for describing a method.
 */
@interface OFMethod: OFObject
{
	SEL selector;
	OFString *name;
	const char *typeEncoding;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) SEL selector;
@property (readonly, copy) OFString *name;
@property (readonly) const char *typeEncoding;
#endif

/**
 * \brief Returns the selector of the method.
 *
 * \return The selector of the method
 */
- (SEL)selector;

/**
 * \brief Returns the name of the method.
 *
 * \return The name of the method
 */
- (OFString*)name;

/**
 * \brief Returns the type encoding for the method.
 *
 * \return The type encoding for the method
 */
- (const char*)typeEncoding;
@end

/**
 * \brief A class for introspecting classes.
 */
@interface OFIntrospection: OFObject
{
	OFMutableArray *classMethods;
	OFMutableArray *instanceMethods;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFArray *classMethods;
@property (readonly, copy) OFArray *instanceMethods;
#endif

/**
 * \brief Creates a new, autoreleased introspection for the specified class.
 *
 * \return A new, autoreleased introspection for the specified class
 */
+ introspectionWithClass: (Class)class_;

/**
 * \brief Initializes an already allocated OFIntrospection with the specified
 *	  class.
 *
 * \return An initialized OFIntrospection
 */
- initWithClass: (Class)class_;

/**
 * \brief Returns the class methods of the class.
 *
 * \return The class methods of the class
 */
- (OFArray*)classMethods;

/**
 * \brief Returns the instance methods of the class.
 *
 * \return The instance methods of the class
 */
- (OFArray*)instanceMethods;

/* TODO: Ivars, properties */
@end
