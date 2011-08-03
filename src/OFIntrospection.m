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
		    initWithCString: sel_getName(selector)];
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
		    initWithCString: sel_get_name(selector)];
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
		unsigned i, count;

		classMethods = [[OFMutableArray alloc] init];
		instanceMethods = [[OFMutableArray alloc] init];

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
#elif defined(OF_OLD_GNU_RUNTIME)
		MethodList_t methodList;

		classMethods = [[OFMutableArray alloc] init];
		instanceMethods = [[OFMutableArray alloc] init];

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
@end
