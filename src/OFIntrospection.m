/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#include "config.h"

#include <stdlib.h>
#include <string.h>

#if defined(OF_APPLE_RUNTIME)
# import <objc/runtime.h>
#endif

#import "OFIntrospection.h"
#import "OFString.h"
#import "OFArray.h"

#import "autorelease.h"
#import "macros.h"

@implementation OFMethod
#if defined(OF_OBJFW_RUNTIME)
- OF_initWithMethod: (struct objc_method*)method
{
	self = [super init];

	@try {
		_selector = (SEL)&method->sel;
		_name = [[OFString alloc]
		    initWithUTF8String: sel_getName(_selector)];
		_typeEncoding = method->sel.types;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#elif defined(OF_APPLE_RUNTIME)
- OF_initWithMethod: (Method)method
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
#endif

- (void)dealloc
{
	[_name release];

	[super dealloc];
}

- (SEL)selector
{
	return _selector;
}

- (OFString*)name
{
	OF_GETTER(_name, true)
}

- (const char*)typeEncoding
{
	return _typeEncoding;
}

- (OFString*)description
{
	return [OFString stringWithFormat: @"<OFMethod: %@ [%s]>",
					   _name, _typeEncoding];
}

- (bool)isEqual: (id)object
{
	OFMethod *method;

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
	    strcmp(method->_typeEncoding, _typeEncoding))
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, [_name hash]);

	if (_typeEncoding != NULL) {
		size_t i, length;

		length = strlen(_typeEncoding);
		for (i = 0; i < length; i++)
			OF_HASH_ADD(hash, _typeEncoding[i]);
	}

	OF_HASH_FINALIZE(hash);

	return hash;
}
@end

@implementation OFInstanceVariable
#if defined(OF_OBJFW_RUNTIME)
- OF_initWithIvar: (struct objc_ivar*)ivar
{
	self = [super init];

	@try {
		_name = [[OFString alloc] initWithUTF8String: ivar->name];
		_typeEncoding = ivar->type;
		_offset = ivar->offset;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#elif defined(OF_APPLE_RUNTIME)
- OF_initWithIvar: (Ivar)ivar
{
	self = [super init];

	@try {
		_name = [[OFString alloc]
		    initWithUTF8String: ivar_getName(ivar)];
		_typeEncoding = ivar_getTypeEncoding(ivar);
		_offset = ivar_getOffset(ivar);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

- (void)dealloc
{
	[_name release];

	[super dealloc];
}

- (OFString*)name
{
	OF_GETTER(_name, true);
}

- (ptrdiff_t)offset
{
	return _offset;
}

- (const char*)typeEncoding
{
	return _typeEncoding;
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"<OFInstanceVariable: %@ [%s] @ 0x%tx>",
	    _name, _typeEncoding, _offset];
}
@end

@implementation OFIntrospection
+ (instancetype)introspectionWithClass: (Class)class
{
	return [[[self alloc] initWithClass: class] autorelease];
}

- initWithClass: (Class)class
{
	self = [super init];

	@try {
#if defined(OF_OBJFW_RUNTIME)
		struct objc_method_list *methodList;
#elif defined(OF_APPLE_RUNTIME)
		Method *methodList;
		Ivar *ivarList;
		unsigned i, count;
#endif

		_classMethods = [[OFMutableArray alloc] init];
		_instanceMethods = [[OFMutableArray alloc] init];
		_instanceVariables = [[OFMutableArray alloc] init];

#if defined(OF_OBJFW_RUNTIME)
		for (methodList = object_getClass(class)->methodlist;
		    methodList != NULL; methodList = methodList->next) {
			int i;

			for (i = 0; i < methodList->count; i++) {
				void *pool = objc_autoreleasePoolPush();
				OFMethod *method = [[OFMethod alloc]
				    OF_initWithMethod: &methodList->methods[i]];
				[_classMethods addObject: [method autorelease]];
				objc_autoreleasePoolPop(pool);
			}
		}

		for (methodList = class->methodlist; methodList != NULL;
		    methodList = methodList->next) {
			int i;

			for (i = 0; i < methodList->count; i++) {
				void *pool = objc_autoreleasePoolPush();
				OFMethod *method = [[OFMethod alloc]
				    OF_initWithMethod: &methodList->methods[i]];
				[_instanceMethods addObject:
				    [method autorelease]];
				objc_autoreleasePoolPop(pool);
			}
		}

		if (class->ivars != NULL) {
			unsigned i;

			for (i = 0; i < class->ivars->count; i++) {
				void *pool = objc_autoreleasePoolPush();
				OFInstanceVariable *ivar;

				ivar = [[OFInstanceVariable alloc]
				    OF_initWithIvar: &class->ivars->ivars[i]];
				[_instanceVariables addObject:
				    [ivar autorelease]];

				objc_autoreleasePoolPop(pool);
			}
		}
#elif defined(OF_APPLE_RUNTIME)
		methodList = class_copyMethodList(object_getClass(class),
		    &count);
		@try {
			for (i = 0; i < count; i++) {
				void *pool = objc_autoreleasePoolPush();
				[_classMethods addObject: [[[OFMethod alloc]
				    OF_initWithMethod: methodList[i]]
				    autorelease]];
				objc_autoreleasePoolPop(pool);
			}
		} @finally {
			free(methodList);
		}

		methodList = class_copyMethodList(class, &count);
		@try {
			for (i = 0; i < count; i++) {
				void *pool = objc_autoreleasePoolPush();
				[_instanceMethods addObject: [[[OFMethod alloc]
				    OF_initWithMethod: methodList[i]]
				    autorelease]];
				objc_autoreleasePoolPop(pool);
			}
		} @finally {
			free(methodList);
		}

		ivarList = class_copyIvarList(class, &count);
		@try {
			for (i = 0; i < count; i++) {
				void *pool = objc_autoreleasePoolPush();
				[_instanceVariables addObject:
				    [[[OFInstanceVariable alloc]
				    OF_initWithIvar: ivarList[i]] autorelease]];
				objc_autoreleasePoolPop(pool);
			}
		} @finally {
			free(ivarList);
		}
#endif

		[_classMethods makeImmutable];
		[_instanceMethods makeImmutable];
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

- (OFArray*)classMethods
{
	OF_GETTER(_classMethods, true)
}

- (OFArray*)instanceMethods
{
	OF_GETTER(_instanceMethods, true)
}

- (OFArray*)instanceVariables
{
	OF_GETTER(_instanceVariables, true)
}
@end
