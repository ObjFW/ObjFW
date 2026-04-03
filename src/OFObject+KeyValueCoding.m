/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#include <stdlib.h>

#import "OFObject.h"
#import "OFObject+KeyValueCoding.h"
#import "OFArray.h"
#import "OFMethodSignature.h"
#import "OFNumber.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFOutOfMemoryException.h"
#import "OFUndefinedKeyException.h"

int _OFObject_KeyValueCoding_reference;

@implementation OFObject (KeyValueCoding)
static id
valueForKeyWithSelector(id self, OFString *key, SEL selector)
{
	void *pool = objc_autoreleasePoolPush();
	OFMethodSignature *methodSignature =
	    [self methodSignatureForSelector: selector];
	const char *retType;

	if (methodSignature == nil) {
		objc_autoreleasePoolPop(pool);
		return nil;
	}

	if (methodSignature.numberOfArguments != 2 ||
	    *[methodSignature argumentTypeAtIndex: 0] != '@' ||
	    *[methodSignature argumentTypeAtIndex: 1] != ':') {
		objc_autoreleasePoolPop(pool);
		return [self valueForUndefinedKey: key];
	}

	retType = methodSignature.methodReturnType;

	while (*retType == 'r' || *retType == 'n' || *retType == 'N' ||
	    *retType == 'o' || *retType == 'O' || *retType == 'R' ||
	    *retType == 'V')
		retType++;

	switch (*retType) {
	case '@':
	case '#':
		objc_autoreleasePoolPop(pool);
		return [self performSelector: selector];
#define CASE(encoding, type, method)					  \
	case encoding:							  \
		{							  \
			objc_autoreleasePoolPop(pool);			  \
			type (*getter)(id, SEL) = (type (*)(id, SEL))	  \
			    [self methodForSelector: selector];		  \
			return [OFNumber method getter(self, selector)];  \
		}							  \
		break;
	CASE('B', bool, numberWithBool:)
	CASE('c', char, numberWithChar:)
	CASE('s', short, numberWithShort:)
	CASE('i', int, numberWithInt:)
	CASE('l', long, numberWithLong:)
	CASE('q', long long, numberWithLongLong:)
	CASE('C', unsigned char, numberWithUnsignedChar:)
	CASE('S', unsigned short, numberWithUnsignedShort:)
	CASE('I', unsigned int, numberWithUnsignedInt:)
	CASE('L', unsigned long, numberWithUnsignedLong:)
	CASE('Q', unsigned long long, numberWithUnsignedLongLong:)
	CASE('f', float, numberWithFloat:)
	CASE('d', double, numberWithDouble:)
#undef CASE
	case '^':
	case '*':
	case ':':
		{
			objc_autoreleasePoolPop(pool);
			void *(*getter)(id, SEL) = (void *(*)(id, SEL))
			    [self methodForSelector: selector];
			return [OFValue valueWithPointer:
			    getter(self, selector)];
		}
		break;
	default:
		objc_autoreleasePoolPop(pool);
		return [self valueForUndefinedKey: key];
	}
}

- (id)valueForKey: (OFString *)key
{
	size_t keyLength;
	SEL selector;
	id ret;
	char *name;

	if ((keyLength = key.UTF8StringLength) < 1)
		return [self valueForUndefinedKey: key];

	selector = sel_registerName(key.UTF8String);

	if ((ret = valueForKeyWithSelector(self, key, selector)) != nil)
		return ret;

	name = OFAllocMemory(keyLength + 3, 1);
	@try {
		memcpy(name, "is", 2);
		memcpy(name + 2, key.UTF8String, keyLength);
		name[keyLength + 2] = '\0';

		name[2] = OFASCIIToUpper(name[2]);

		selector = sel_registerName(name);
	} @finally {
		OFFreeMemory(name);
	}

	if ((ret = valueForKeyWithSelector(self, key, selector)) != nil)
		return ret;

	return [self valueForUndefinedKey: key];
}

- (id)valueForKeyPath: (OFString *)keyPath
{
	void *pool = objc_autoreleasePoolPush();
	id ret = self;

	for (OFString *key in [keyPath componentsSeparatedByString: @"."])
		ret = [ret valueForKey: key];

	objc_retain(ret);

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(ret);
}

- (id)valueForUndefinedKey: (OFString *)key
{
	@throw [OFUndefinedKeyException exceptionWithObject: self key: key];
}

- (void)setValue: (id)value forKey: (OFString *)key
{
	void *pool = objc_autoreleasePoolPush();
	size_t keyLength;
	char *name;
	SEL selector;
	OFMethodSignature *methodSignature;
	const char *valueType;

	if ((keyLength = key.UTF8StringLength) < 1) {
		objc_autoreleasePoolPop(pool);
		[self setValue: value forUndefinedKey: key];
		return;
	}

	name = OFAllocMemory(keyLength + 5, 1);
	@try {
		memcpy(name, "set", 3);
		memcpy(name + 3, key.UTF8String, keyLength);
		memcpy(name + keyLength + 3, ":", 2);

		name[3] = OFASCIIToUpper(name[3]);

		selector = sel_registerName(name);
	} @finally {
		OFFreeMemory(name);
	}

	methodSignature = [self methodSignatureForSelector: selector];

	if (methodSignature == nil ||
	    methodSignature.numberOfArguments != 3 ||
	    *methodSignature.methodReturnType != 'v' ||
	    *[methodSignature argumentTypeAtIndex: 0] != '@' ||
	    *[methodSignature argumentTypeAtIndex: 1] != ':') {
		objc_autoreleasePoolPop(pool);
		[self setValue: value forUndefinedKey: key];
		return;
	}

	valueType = [methodSignature argumentTypeAtIndex: 2];

	while (*valueType == 'r' || *valueType == 'n' || *valueType == 'N' ||
	    *valueType == 'o' || *valueType == 'O' || *valueType == 'R' ||
	    *valueType == 'V')
		valueType++;

	if (*valueType != '@' && *valueType != '#' && value == nil) {
		objc_autoreleasePoolPop(pool);
		[self setNilValueForKey: key];
		return;
	}

	switch (*valueType) {
	case '@':
	case '#':
		{
			void (*setter)(id, SEL, id) = (void (*)(id, SEL, id))
			    [self methodForSelector: selector];
			setter(self, selector, value);
		}
		break;
#define CASE(encoding, type, method) \
	case encoding:						\
		{						\
			void (*setter)(id, SEL, type) =		\
			    (void (*)(id, SEL, type))		\
			    [self methodForSelector: selector];	\
			setter(self, selector, [value method]);	\
		}						\
		break;
	CASE('B', bool, boolValue)
	CASE('c', char, charValue)
	CASE('s', short, shortValue)
	CASE('i', int, intValue)
	CASE('l', long, longValue)
	CASE('q', long long, longLongValue)
	CASE('C', unsigned char, unsignedCharValue)
	CASE('S', unsigned short, unsignedShortValue)
	CASE('I', unsigned int, unsignedIntValue)
	CASE('L', unsigned long, unsignedLongValue)
	CASE('Q', unsigned long long, unsignedLongLongValue)
	CASE('f', float, floatValue)
	CASE('d', double, doubleValue)
#undef CASE
	case '^':
	case '*':
	case ':':
		{
			void (*setter)(id, SEL, void *) =
			    (void (*)(id, SEL, void *))
			    [self methodForSelector: selector];
			setter(self, selector, [value pointerValue]);
		}
		break;
	default:
		objc_autoreleasePoolPop(pool);
		[self setValue: value forUndefinedKey: key];
		return;
	}

	objc_autoreleasePoolPop(pool);
}

- (void)setValue: (id)value forKeyPath: (OFString *)keyPath
{
	void *pool = objc_autoreleasePoolPush();
	OFArray *keys = [keyPath componentsSeparatedByString: @"."];
	size_t keysCount = keys.count;
	id object = self;
	size_t i = 0;

	for (OFString *key in keys) {
		if (++i == keysCount)
			[object setValue: value forKey: key];
		else
			object = [object valueForKey: key];
	}

	objc_autoreleasePoolPop(pool);
}

-  (void)setValue: (id)value forUndefinedKey: (OFString *)key
{
	@throw [OFUndefinedKeyException exceptionWithObject: self
							key: key
						      value: value];
}

- (void)setNilValueForKey: (OFString *)key
{
	@throw [OFInvalidArgumentException exception];
}
@end
