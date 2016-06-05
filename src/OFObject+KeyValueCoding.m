/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#include <stdlib.h>
#include <ctype.h>

#import "OFObject.h"
#import "OFObject+KeyValueCoding.h"
#import "OFString.h"
#import "OFNull.h"

#import "OFOutOfMemoryException.h"
#import "OFUndefinedKeyException.h"

int _OFObject_KeyValueCoding_reference;

static bool
checkTypeEncoding(const char *typeEncoding, char returnType, ...)
{
	va_list args;
	char type;

	if (typeEncoding == NULL)
		return false;

	if (*typeEncoding++ != returnType)
		return false;

	while (*typeEncoding >= '0' && *typeEncoding <= '9')
		typeEncoding++;

	va_start(args, returnType);

	while ((type = va_arg(args, int)) != 0) {
		if (*typeEncoding++ != type)
			return false;

		while (*typeEncoding >= '0' && *typeEncoding <= '9')
			typeEncoding++;
	}

	if (*typeEncoding != '\0')
		return false;

	return true;
}

@implementation OFObject (KeyValueCoding)
- (id)valueForKey: (OFString*)key
{
	SEL selector = sel_registerName([key UTF8String]);
	const char *typeEncoding = [self typeEncodingForSelector: selector];

	if (!checkTypeEncoding(typeEncoding, '@', '@', ':', 0))
		return [self valueForUndefinedKey: key];

	return [self performSelector: selector];
}

- (id)valueForUndefinedKey: (OFString*)key
{
	@throw [OFUndefinedKeyException exceptionWithObject: self
							key: key];
}

- (void)setValue: (id)value
	  forKey: (OFString*)key
{
	char *name;
	size_t keyLength;
	SEL selector;
	const char *typeEncoding;
	id (*setter)(id, SEL, id);

	keyLength = [key UTF8StringLength];

	if (keyLength < 1) {
		[self	 setValue: value
		  forUndefinedKey: key];
		return;
	}

	if ((name = malloc(keyLength + 5)) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: keyLength + 5];

	memcpy(name, "set", 3);
	memcpy(name + 3, [key UTF8String], keyLength);
	memcpy(name + keyLength + 3, ":", 2);

	name[3] = toupper(name[3]);

	selector = sel_registerName(name);

	free(name);

	typeEncoding = [self typeEncodingForSelector: selector];

	if (!checkTypeEncoding(typeEncoding, 'v', '@', ':', '@', 0)) {
		[self	 setValue: value
		  forUndefinedKey: key];
		return;
	}

	setter = (id(*)(id, SEL, id))[self methodForSelector: selector];
	setter(self, selector, value);
}

-  (void)setValue: (id)value
  forUndefinedKey: (OFString*)key
{
	@throw [OFUndefinedKeyException exceptionWithObject: self
							key: key
						      value: value];
}
@end
