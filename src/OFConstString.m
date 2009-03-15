/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define OFCONSTSTRING_M
#import "OFConstString.h"
#import "OFString.h"
#import "OFExceptions.h"
#import "OFMacros.h"

#ifndef __objc_INCLUDE_GNU
struct objc_class _OFConstStringClassReference;
#endif

@implementation OFConstString
#ifndef __objc_INCLUDE_GNU
+ (void)load
{
	Class cls = objc_getClass("OFConstString");
	memcpy(&_OFConstStringClassReference, cls,
	    sizeof(_OFConstStringClassReference));
	objc_addClass(&_OFConstStringClassReference);
}
#endif

- (BOOL)isKindOf: (Class)c
{
	if (c == [OFConstString class])
		return YES;
	return NO;
}

- (const char*)cString
{
	return string;
}

- (size_t)length
{
	return length;
}

- (BOOL)isEqual: (id)obj
{
	if (![obj isKindOf: [OFString class]] &&
	    ![obj isKindOf: [OFConstString class]])
		return NO;
	if (strcmp(string, [obj cString]))
		return NO;

	return YES;
}

- (int)compare: (id)obj
{
	if (![obj isKindOf: [OFString class]] &&
	    ![obj isKindOf: [OFConstString class]])
		@throw [OFInvalidArgumentException newWithClass: [self class]];

	return strcmp(string, [obj cString]);
}

- (uint32_t)hash
{
	uint32_t hash;
	size_t i;

	OF_HASH_INIT(hash);
	for (i = 0; i < length; i++)
		OF_HASH_ADD(hash, string[i]);
	OF_HASH_FINALIZE(hash);

	return hash;
}

- retain
{
	return self;
}

- (void)release
{
}

- (size_t)retainCount
{
	return 1;
}

- autorelease
{
	return self;
}
@end
