/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
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
#ifndef DOXYGEN
@class OFArray OF_GENERIC(ObjectType);
@class OFMutableArray OF_GENERIC(ObjectType);
#endif

enum {
	OF_PROPERTY_READONLY	=   0x01,
	OF_PROPERTY_ASSIGN	=   0x04,
	OF_PROPERTY_READWRITE	=   0x08,
	OF_PROPERTY_RETAIN	=   0x10,
	OF_PROPERTY_COPY	=   0x20,
	OF_PROPERTY_NONATOMIC	=   0x40,
	OF_PROPERTY_SYNTHESIZED	=  0x100,
	OF_PROPERTY_DYNAMIC	=  0x200,
	OF_PROPERTY_ATOMIC	=  0x400,
	OF_PROPERTY_WEAK	=  0x800
};

/*!
 * @class OFMethod OFIntrospection.h ObjFW/OFIntrospection.h
 *
 * @brief A class for describing a method.
 */
@interface OFMethod: OFObject
{
	SEL _selector;
	OFString *_name;
	const char *_typeEncoding;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly) SEL selector;
@property (readonly, copy) OFString *name;
@property (readonly) const char *typeEncoding;
#endif

/*!
 * @brief Returns the selector of the method.
 *
 * @return The selector of the method
 */
- (SEL)selector;

/*!
 * @brief Returns the name of the method.
 *
 * @return The name of the method
 */
- (OFString*)name;

/*!
 * @brief Returns the type encoding for the method.
 *
 * @return The type encoding for the method
 */
- (const char*)typeEncoding;
@end

/*!
 * @class OFProperty OFIntrospection.h ObjFW/OFIntrospection.h
 *
 * @brief A class for describing a property.
 */
@interface OFProperty: OFObject
{
	OFString *_name;
	unsigned _attributes;
	OFString *_getter, *_setter;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *name;
@property (readonly) unsigned attributes;
@property (readonly, copy) OFString *getter, *setter;
#endif

/*!
 * @brief Returns the name of the property.
 *
 * @return The name of the property
 */
- (OFString*)name;

/*!
 * @brief Returns the attributes of the property.
 *
 * The attributes are a bitmask with the following possible flags:@n
 * Flag                          | Description
 * ------------------------------|-------------------------------------
 * OF_PROPERTY_READONLY          | The property is declared `readonly`
 * OF_PROPERTY_READWRITE         | The property is declared `readwrite`
 * OF_PROPERTY_ASSIGN            | The property is declared `assign`
 * OF_PROPERTY_RETAIN            | The property is declared `retain`
 * OF_PROPERTY_COPY              | The property is declared `copy`
 * OF_PROPERTY_NONATOMIC         | The property is declared `nonatomic`
 * OF_PROPERTY_ATOMIC            | The property is declared `atomic`
 * OF_PROPERTY_WEAK              | The property is declared `weak`
 * OF_PROPERTY_SYNTHESIZED       | The property is synthesized
 * OF_PROPERTY_DYNAMIC           | The property is dynamic
 *
 * @return The attributes of the property
 */
- (unsigned)attributes;

/*!
 * @brief Returns the name of the getter.
 *
 * @return The name of the getter
 */
- (OFString*)getter;

/*!
 * @brief Returns the name of the setter.
 *
 * @return The name of the setter
 */
- (OFString*)setter;
@end

/*!
 * @class OFInstanceVariable OFIntrospection.h ObjFW/OFIntrospection.h
 *
 * @brief A class for describing an instance variable.
 */
@interface OFInstanceVariable: OFObject
{
	OFString *_name;
	const char *_typeEncoding;
	ptrdiff_t _offset;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFString *name;
@property (readonly) ptrdiff_t offset;
@property (readonly) const char *typeEncoding;
#endif

/*!
 * @brief Returns the name of the instance variable.
 *
 * @return The name of the instance variable
 */
- (OFString*)name;

/*!
 * @brief Returns the offset of the instance variable.
 *
 * @return The offset of the instance variable
 */
- (ptrdiff_t)offset;

/*!
 * @brief Returns the type encoding for the instance variable.
 *
 * @return The type encoding for the instance variable
 */
- (const char*)typeEncoding;
@end

/*!
 * @class OFIntrospection OFIntrospection.h ObjFW/OFIntrospection.h
 *
 * @brief A class for introspecting classes.
 */
@interface OFIntrospection: OFObject
{
	OFMutableArray OF_GENERIC(OFMethod*) *_classMethods;
	OFMutableArray OF_GENERIC(OFMethod*) *_instanceMethods;
	OFMutableArray OF_GENERIC(OFProperty*) *_properties;
	OFMutableArray OF_GENERIC(OFInstanceVariable*) *_instanceVariables;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, copy) OFArray OF_GENERIC(OFMethod*) *classMethods;
@property (readonly, copy) OFArray OF_GENERIC(OFMethod*) *instanceMethods;
@property (readonly, copy) OFArray OF_GENERIC(OFProperty*) *properties;
@property (readonly, copy)
    OFArray OF_GENERIC(OFInstanceVariable*) *instanceVariables;
#endif

/*!
 * @brief Creates a new introspection for the specified class.
 *
 * @return A new, autoreleased introspection for the specified class
 */
+ (instancetype)introspectionWithClass: (Class)class_;

/*!
 * @brief Initializes an already allocated OFIntrospection with the specified
 *	  class.
 *
 * @return An initialized OFIntrospection
 */
- initWithClass: (Class)class_;

/*!
 * @brief Returns the class methods of the class.
 *
 * @return An array of objects of class @ref OFMethod
 */
- (OFArray OF_GENERIC(OFMethod*)*)classMethods;

/*!
 * @brief Returns the instance methods of the class.
 *
 * @return An array of objects of class @ref OFMethod
 */
- (OFArray OF_GENERIC(OFMethod*)*)instanceMethods;

/*!
 * @brief Returns the properties of the class.
 *
 * @warning **Do not rely on this, as this behaves differently depending on the
 *	    compiler and ABI used!**
 *
 * @warning For the ObjFW ABI, Clang only emits data for property introspection
 *	    if `@``synthesize` or `@``dynamic` has been used on the property,
 *	    not if the property has only been implemented by methods. Using
 *	    `@``synthesize` and manually implementing the methods works,
 *	    though.
 *
 * @warning For the Apple ABI, Clang and GCC both emit data for property
 *	    introspection for every property that has been declared using
 *	    `@``property`, even if no `@``synchronize` or `@``dynamic` has been
 *	    used.
 *
 * @warning GCC does not emit any data for property introspection for the GNU
 *	    ABI.
 *
 * @return An array of objects of class @ref OFProperty
 */
- (OFArray OF_GENERIC(OFProperty*)*)properties;

/*!
 * @brief Returns the instance variables of the class.
 *
 * @return An array of objects of class @ref OFInstanceVariable
 */
- (OFArray OF_GENERIC(OFInstanceVariable*)*)instanceVariables;

/* TODO: protocols */
@end
