/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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
		selector = (SEL)&method->sel;
		name = [[OFString alloc]
		    initWithCString: sel_getName(selector)
			   encoding: OF_STRING_ENCODING_ASCII];
		typeEncoding = method->sel.types;
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
		selector = method_getName(method);
		name = [[OFString alloc]
		    initWithCString: sel_getName(selector)
			   encoding: OF_STRING_ENCODING_ASCII];
		typeEncoding = method_getTypeEncoding(method);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

- (void)dealloc
{
	[name release];

	[super dealloc];
}

- (SEL)selector
{
	return selector;
}

- (OFString*)name
{
	OF_GETTER(name, YES)
}

- (const char*)typeEncoding
{
	return typeEncoding;
}

- (OFString*)description
{
	return [OFString stringWithFormat: @"<OFMethod: %@ [%s]>",
					   name, typeEncoding];
}

- (BOOL)isEqual: (id)object
{
	OFMethod *otherMethod;

	if (![object isKindOfClass: [OFMethod class]])
		return NO;

	otherMethod = object;

	if (!sel_isEqual(otherMethod->selector, selector))
		return NO;

	if (![otherMethod->name isEqual: name])
		return NO;

	if ((otherMethod->typeEncoding == NULL && typeEncoding != NULL) ||
	    (otherMethod->typeEncoding != NULL && typeEncoding == NULL))
		return NO;
	if (strcmp(otherMethod->typeEncoding, typeEncoding))
		return NO;

	return YES;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, [name hash]);

	if (typeEncoding != NULL) {
		size_t i, length;

		length = strlen(typeEncoding);
		for (i = 0; i < length; i++)
			OF_HASH_ADD(hash, typeEncoding[i]);
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
		name = [[OFString alloc]
		    initWithCString: ivar->name
			   encoding: OF_STRING_ENCODING_ASCII];
		typeEncoding = ivar->type;
		offset = ivar->offset;
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
		name = [[OFString alloc]
		    initWithCString: ivar_getName(ivar)
			   encoding: OF_STRING_ENCODING_ASCII];
		typeEncoding = ivar_getTypeEncoding(ivar);
		offset = ivar_getOffset(ivar);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

- (void)dealloc
{
	[name release];

	[super dealloc];
}

- (OFString*)name
{
	OF_GETTER(name, YES);
}

- (ptrdiff_t)offset
{
	return offset;
}

- (const char*)typeEncoding
{
	return typeEncoding;
}

- (OFString*)description
{
	return [OFString stringWithFormat:
	    @"<OFInstanceVariable: %@ [%s] @ 0x%tx>",
	    name, typeEncoding, offset];
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

		classMethods = [[OFMutableArray alloc] init];
		instanceMethods = [[OFMutableArray alloc] init];
		instanceVariables = [[OFMutableArray alloc] init];

#if defined(OF_OBJFW_RUNTIME)
		for (methodList = object_getClass(class)->methodlist;
		    methodList != NULL; methodList = methodList->next) {
			int i;

			for (i = 0; i < methodList->count; i++) {
				void *pool = objc_autoreleasePoolPush();
				OFMethod *method = [[OFMethod alloc]
				    OF_initWithMethod: &methodList->methods[i]];
				[classMethods addObject: [method autorelease]];
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
				[instanceMethods addObject:
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
				[instanceVariables addObject:
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
				[classMethods addObject: [[[OFMethod alloc]
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
				[instanceMethods addObject: [[[OFMethod alloc]
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
				[instanceVariables addObject:
				    [[[OFInstanceVariable alloc]
				    OF_initWithIvar: ivarList[i]] autorelease]];
				objc_autoreleasePoolPop(pool);
			}
		} @finally {
			free(ivarList);
		}
#endif

		[classMethods makeImmutable];
		[instanceMethods makeImmutable];
		[instanceVariables makeImmutable];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[classMethods release];
	[instanceMethods release];
	[instanceVariables release];

	[super dealloc];
}

- (OFArray*)classMethods
{
	OF_GETTER(classMethods, YES)
}

- (OFArray*)instanceMethods
{
	OF_GETTER(instanceMethods, YES)
}

- (OFArray*)instanceVariables
{
	OF_GETTER(instanceVariables, YES)
}
@end
