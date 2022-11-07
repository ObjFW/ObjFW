/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFInvocation.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFMethodSignature.h"

#ifdef OF_INVOCATION_CAN_INVOKE
extern void OFInvocationInvoke(OFInvocation *);
#endif

@implementation OFInvocation
@synthesize methodSignature = _methodSignature;

+ (instancetype)invocationWithMethodSignature: (OFMethodSignature *)signature
{
	return [[[self alloc] initWithMethodSignature: signature] autorelease];
}

- (instancetype)initWithMethodSignature: (OFMethodSignature *)signature
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		size_t numberOfArguments = signature.numberOfArguments;
		const char *typeEncoding;
		size_t typeSize;

		_methodSignature = [signature retain];
		_arguments = [[OFMutableArray alloc] init];

		for (size_t i = 0; i < numberOfArguments; i++) {
			OFMutableData *data;

			typeEncoding = [_methodSignature
			    argumentTypeAtIndex: i];
			typeSize = OFSizeOfTypeEncoding(typeEncoding);

			data = [OFMutableData dataWithItemSize: typeSize
						      capacity: 1];
			[data increaseCountBy: 1];
			[_arguments addObject: data];
		}

		typeEncoding = _methodSignature.methodReturnType;
		typeSize = OFSizeOfTypeEncoding(typeEncoding);

		if (typeSize > 0) {
			_returnValue = [[OFMutableData alloc]
			    initWithItemSize: typeSize
				    capacity: 1];
			[_returnValue increaseCountBy: 1];
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_methodSignature release];
	[_arguments release];
	[_returnValue release];

	[super dealloc];
}

- (void)setArgument: (const void *)buffer atIndex: (size_t)idx
{
	OFMutableData *data = [_arguments objectAtIndex: idx];
	memcpy(data.mutableItems, buffer, data.itemSize);
}

- (void)getArgument: (void *)buffer atIndex: (size_t)idx
{
	OFData *data = [_arguments objectAtIndex: idx];
	memcpy(buffer, data.items, data.itemSize);
}

- (void)setReturnValue: (const void *)buffer
{
	memcpy(_returnValue.mutableItems, buffer, _returnValue.itemSize);
}

- (void)getReturnValue: (void *)buffer
{
	memcpy(buffer, _returnValue.items, _returnValue.itemSize);
}

#ifdef OF_INVOCATION_CAN_INVOKE
- (void)invoke
{
	OFInvocationInvoke(self);
}
#endif
@end
