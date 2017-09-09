/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#include <ctype.h>

#import "OFMethodSignature.h"
#import "OFData.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"

@implementation OFMethodSignature
+ (instancetype)signatureWithObjCTypes: (const char*)types
{
	return [[[self alloc] initWithObjCTypes: types] autorelease];
}

- initWithObjCTypes: (const char *)types
{
	self = [super init];

	@try {
		size_t length;
		const char *last;

		if (types == NULL)
			@throw [OFInvalidArgumentException exception];

		length = strlen(types);

		if (length == 0)
			@throw [OFInvalidFormatException exception];

		_types = [self allocMemoryWithSize: length + 1];
		memcpy(_types, types, length);

		_typesPointers = [[OFMutableData alloc]
		    initWithItemSize: sizeof(char *)];

		last = _types;
		for (size_t i = 0; i < length; i++) {
			if (isdigit(_types[i])) {
				if (last == _types + i)
					@throw [OFInvalidFormatException
					    exception];

				_types[i] = '\0';
				[_typesPointers addItem: &last];

				i++;
				for (; i < length && isdigit(_types[i]); i++);

				last = _types + i;
				i--;
			} else if (_types[i] == '{') {
				size_t depth = 0;

				for (; i < length; i++) {
					if (_types[i] == '{')
						depth++;
					else if (_types[i] == '}') {
						if (--depth == 0)
							break;
					}
				}

				if (depth != 0)
					@throw [OFInvalidFormatException
					    exception];
			} else if (_types[i] == '(') {
				size_t depth = 0;

				for (; i < length; i++) {
					if (_types[i] == '(')
						depth++;
					else if (_types[i] == ')') {
						if (--depth == 0)
							break;
					}
				}

				if (depth != 0)
					@throw [OFInvalidFormatException
					    exception];
			}
		}

		if (last < _types + length)
			@throw [OFInvalidFormatException exception];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_typesPointers release];

	[super dealloc];
}

- (size_t)numberOfArguments
{
	return [_typesPointers count] - 1;
}

- (const char *)methodReturnType
{
	return *(const char **)[_typesPointers firstItem];
}

- (const char *)argumentTypeAtIndex: (size_t)index
{
	return *(const char **)[_typesPointers itemAtIndex: index + 1];
}
@end
