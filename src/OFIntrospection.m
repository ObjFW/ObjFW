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

#include "config.h"

#include <string.h>

#import "OFIntrospection.h"
#import "OFString.h"
#import "OFArray.h"

#import "OFInitializationFailedException.h"

@implementation OFMethod
@synthesize selector = _selector, name = _name, typeEncoding = _typeEncoding;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_initWithMethod: (Method)method
{
	self = [super init];

	@try {
		_selector = method_getName(method);
		_name = [[OFString alloc]
		    initWithUTF8String: sel_getName(_selector)];
		_typeEncoding = method_getTypeEncoding(method);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_name release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@ [%s]>",
					   self.class, _name, _typeEncoding];
}

- (bool)isEqual: (id)object
{
	OFMethod *method;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFMethod class]])
		return false;

	method = object;

	if (!sel_isEqual(method->_selector, _selector))
		return false;

	if (![method->_name isEqual: _name])
		return false;

	if ((method->_typeEncoding == NULL && _typeEncoding != NULL) ||
	    (method->_typeEncoding != NULL && _typeEncoding == NULL))
		return false;

	if (method->_typeEncoding != NULL && _typeEncoding != NULL &&
	    strcmp(method->_typeEncoding, _typeEncoding) != 0)
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, _name.hash);

	if (_typeEncoding != NULL) {
		size_t length = strlen(_typeEncoding);

		for (size_t i = 0; i < length; i++)
			OF_HASH_ADD(hash, _typeEncoding[i]);
	}

	OF_HASH_FINALIZE(hash);

	return hash;
}
@end

@implementation OFProperty
@synthesize name = _name, attributes = _attributes;
@synthesize getter = _getter, setter = _setter, iVar = _iVar;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_initWithProperty: (objc_property_t)property
{
	self = [super init];

	@try {
		char *value;

		_name = [[OFString alloc]
		    initWithUTF8String: property_getName(property)];

		value = property_copyAttributeValue(property, "G");
		if (value != NULL) {
			@try {
				_getter = [[OFString alloc]
				    initWithUTF8String: value];
			} @finally {
				free(value);
			}
		}

		value = property_copyAttributeValue(property, "S");
		if (value != NULL) {
			@try {
				_setter = [[OFString alloc]
				    initWithUTF8String: value];
			} @finally {
				free(value);
			}
		}

#define BOOL_ATTRIBUTE(name, flag)					\
		value = property_copyAttributeValue(property, name);	\
		if (value != NULL) {					\
			_attributes |= flag;				\
			free(value);					\
		}

		BOOL_ATTRIBUTE("R", OF_PROPERTY_READONLY)
		BOOL_ATTRIBUTE("C", OF_PROPERTY_COPY)
		BOOL_ATTRIBUTE("&", OF_PROPERTY_RETAIN)
		BOOL_ATTRIBUTE("N", OF_PROPERTY_NONATOMIC)
		BOOL_ATTRIBUTE("D", OF_PROPERTY_DYNAMIC)
		BOOL_ATTRIBUTE("W", OF_PROPERTY_WEAK)
#undef BOOL_ATTRIBUTE

		value = property_copyAttributeValue(property, "V");
		if (value != NULL) {
			@try {
				_iVar = [[OFString alloc]
				    initWithUTF8String: value];
			} @finally {
				free(value);
			}
		}

		if (!(_attributes & OF_PROPERTY_READONLY))
			_attributes |= OF_PROPERTY_READWRITE;

		if (!(_attributes & OF_PROPERTY_COPY) &&
		    !(_attributes & OF_PROPERTY_RETAIN))
			_attributes |= OF_PROPERTY_ASSIGN;

		if (!(_attributes & OF_PROPERTY_NONATOMIC))
			_attributes |= OF_PROPERTY_ATOMIC;

		if (!(_attributes & OF_PROPERTY_DYNAMIC))
			_attributes |= OF_PROPERTY_SYNTHESIZED;

		if (_getter == nil)
			_getter = [_name copy];

		if ((_attributes & OF_PROPERTY_READWRITE) && _setter == nil) {
			of_unichar_t first = [_name characterAtIndex: 0];
			OFMutableString *tmp = [_name mutableCopy];
			_setter = tmp;

			[tmp setCharacter: of_ascii_toupper(first)
				  atIndex: 0];
			[tmp prependString: @"set"];

			[tmp makeImmutable];
		}
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_name release];
	[_getter release];
	[_setter release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString
	    stringWithFormat: @"<%@: %@\n"
			      @"\tAttributes = 0x%03X\n"
			      @"\tGetter = %@\n"
			      @"\tSetter = %@\n"
			      @"\tiVar = %@\n"
			      @">",
			      self.class, _name, _attributes, _getter, _setter,
			      _iVar];
}

- (bool)isEqual: (id)object
{
	OFProperty *otherProperty;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFProperty class]])
		return false;

	otherProperty = object;

	if (![otherProperty->_name isEqual: _name])
		return false;
	if (otherProperty->_attributes != _attributes)
		return false;
	if (![otherProperty->_getter isEqual: _getter])
		return false;
	if (![otherProperty->_setter isEqual: _setter])
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, _name.hash);
	OF_HASH_ADD(hash, (_attributes & 0xFF00) >> 8);
	OF_HASH_ADD(hash, _attributes & 0xFF);
	OF_HASH_ADD_HASH(hash, _getter.hash);
	OF_HASH_ADD_HASH(hash, _setter.hash);

	OF_HASH_FINALIZE(hash);

	return hash;
}
@end

@implementation OFInstanceVariable
@synthesize name = _name, offset = _offset, typeEncoding = _typeEncoding;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_initWithIVar: (Ivar)iVar
{
	self = [super init];

	@try {
		const char *name = ivar_getName(iVar);

		if (name != NULL)
			_name = [[OFString alloc] initWithUTF8String: name];

		_typeEncoding = ivar_getTypeEncoding(iVar);
		_offset = ivar_getOffset(iVar);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_name release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<OFInstanceVariable: %@ [%s] @ 0x%tx>",
	    _name, _typeEncoding, _offset];
}
@end

@implementation OFIntrospection
@synthesize classMethods = _classMethods, instanceMethods = _instanceMethods;
@synthesize properties = _properties, instanceVariables = _instanceVariables;

+ (instancetype)introspectionWithClass: (Class)class
{
	return [[[self alloc] initWithClass: class] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithClass: (Class)class
{
	self = [super init];

	@try {
		Method *methodList;
		Ivar *iVarList;
		objc_property_t *propertyList;
		unsigned count;
		void *pool;

		_classMethods = [[OFMutableArray alloc] init];
		_instanceMethods = [[OFMutableArray alloc] init];
		_properties = [[OFMutableArray alloc] init];
		_instanceVariables = [[OFMutableArray alloc] init];

		methodList = class_copyMethodList(object_getClass(class),
		    &count);
		@try {
			pool = objc_autoreleasePoolPush();

			for (unsigned int i = 0; i < count; i++)
				[_classMethods addObject: [[[OFMethod alloc]
				    of_initWithMethod: methodList[i]]
				    autorelease]];

			objc_autoreleasePoolPop(pool);
		} @finally {
			free(methodList);
		}

		methodList = class_copyMethodList(class, &count);
		@try {
			pool = objc_autoreleasePoolPush();

			for (unsigned int i = 0; i < count; i++)
				[_instanceMethods addObject: [[[OFMethod alloc]
				    of_initWithMethod: methodList[i]]
				    autorelease]];

			objc_autoreleasePoolPop(pool);
		} @finally {
			free(methodList);
		}

		iVarList = class_copyIvarList(class, &count);
		@try {
			pool = objc_autoreleasePoolPush();

			for (unsigned int i = 0; i < count; i++)
				[_instanceVariables addObject:
				    [[[OFInstanceVariable alloc]
				    of_initWithIVar: iVarList[i]] autorelease]];

			objc_autoreleasePoolPop(pool);
		} @finally {
			free(iVarList);
		}

		propertyList = class_copyPropertyList(class, &count);
		@try {
			pool = objc_autoreleasePoolPush();

			for (unsigned int i = 0; i < count; i++)
				[_properties addObject: [[[OFProperty alloc]
				    of_initWithProperty: propertyList[i]]
				    autorelease]];

			objc_autoreleasePoolPop(pool);
		} @finally {
			free(propertyList);
		}

		[_classMethods makeImmutable];
		[_instanceMethods makeImmutable];
		[_properties makeImmutable];
		[_instanceVariables makeImmutable];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_classMethods release];
	[_instanceMethods release];
	[_instanceVariables release];

	[super dealloc];
}
@end
