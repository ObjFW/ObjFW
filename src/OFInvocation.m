/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#include <string.h>

#import "OFInvocation.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFMethodSignature.h"

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
@end
