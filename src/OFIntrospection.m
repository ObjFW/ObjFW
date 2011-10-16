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

#include "config.h"

#include <stdlib.h>

#if defined(OF_APPLE_RUNTIME) || defined(OF_GNU_RUNTIME)
# import <objc/runtime.h>
#elif defined(OF_OLD_GNU_RUNTIME)
# import <objc/objc-api.h>
#endif

#import "OFIntrospection.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFAutoreleasePool.h"

#import "macros.h"

@implementation OFMethod
#if defined(OF_APPLE_RUNTIME) || defined(OF_GNU_RUNTIME)
- _initWithMethod: (Method)method
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
#elif defined(OF_OLD_GNU_RUNTIME)
- _initWithMethod: (Method_t)method
{
	self = [super init];

	@try {
		selector = method->method_name;
		name = [[OFString alloc]
		    initWithCString: sel_get_name(selector)
			   encoding: OF_STRING_ENCODING_ASCII];
		typeEncoding = method->method_types;
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
@end

@implementation OFInstanceVariable
#if defined(OF_APPLE_RUNTIME) || defined(OF_GNU_RUNTIME)
- _initWithIvar: (Ivar)ivar
{
	self = [super init];

	@try {
		name = [[OFString alloc]
		    initWithCString: ivar_getName(ivar)
			   encoding: OF_STRING_ENCODING_ASCII];
		offset = ivar_getOffset(ivar);
		typeEncoding = ivar_getTypeEncoding(ivar);
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
+ introspectionWithClass: (Class)class
{
	return [[[self alloc] initWithClass: class] autorelease];
}

- initWithClass: (Class)class
{
	self = [super init];

	@try {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
#if defined(OF_APPLE_RUNTIME) || defined(OF_GNU_RUNTIME)
		Method *methodList;
		Ivar *ivarList;
		unsigned i, count;
#elif defined(OF_OLD_GNU_RUNTIME)
		MethodList_t methodList;
#endif

		classMethods = [[OFMutableArray alloc] init];
		instanceMethods = [[OFMutableArray alloc] init];
		instanceVariables = [[OFMutableArray alloc] init];

#if defined(OF_APPLE_RUNTIME) || defined(OF_GNU_RUNTIME)
		methodList = class_copyMethodList(((OFObject*)class)->isa,
		    &count);
		@try {
			for (i = 0; i < count; i++) {
				[classMethods addObject: [[[OFMethod alloc]
				    _initWithMethod: methodList[i]]
				    autorelease]];
				[pool releaseObjects];
			}
		} @finally {
			free(methodList);
		}

		methodList = class_copyMethodList(class, &count);
		@try {
			for (i = 0; i < count; i++) {
				[instanceMethods addObject: [[[OFMethod alloc]
				    _initWithMethod: methodList[i]]
				    autorelease]];
				[pool releaseObjects];
			}
		} @finally {
			free(methodList);
		}

		ivarList = class_copyIvarList(class, &count);
		@try {
			for (i = 0; i < count; i++) {
				[instanceVariables addObject:
				    [[[OFInstanceVariable alloc]
				    _initWithIvar: ivarList[i]] autorelease]];
				[pool releaseObjects];
			}
		} @finally {
			free(ivarList);
		}
#elif defined(OF_OLD_GNU_RUNTIME)
		for (methodList = class->class_pointer->methods;
		    methodList != NULL; methodList = methodList->method_next) {
			int i;

			for (i = 0; i < methodList->method_count; i++)
				[classMethods addObject: [[[OFMethod alloc]
				    _initWithMethod:
				    &methodList->method_list[i]] autorelease]];
		}

		for (methodList = class->methods; methodList != NULL;
		    methodList = methodList->method_next) {
			int i;

			for (i = 0; i < methodList->method_count; i++)
				[instanceMethods addObject: [[[OFMethod alloc]
				    _initWithMethod:
				    &methodList->method_list[i]] autorelease]];
		}
#endif

		[classMethods makeImmutable];
		[instanceMethods makeImmutable];
		[instanceVariables makeImmutable];

		[pool release];
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
