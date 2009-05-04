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

#include <stdarg.h>
#include <string.h>

#import "OFString.h"
#import "OFMutableString.h"
#import "OFExceptions.h"
#import "OFMacros.h"

@implementation OFString
+ string
{
	return [[[OFMutableString alloc] init] autorelease];
}

+ stringWithCString: (const char*)str
{
	return [[[OFMutableString alloc] initWithCString: str] autorelease];
}

+ stringWithFormat: (const char*)fmt, ...
{
	id ret;
	va_list args;

	va_start(args, fmt);
	ret = [[[OFMutableString alloc] initWithFormat: fmt
					  andArguments: args] autorelease];
	va_end(args);

	return ret;
}

+ stringWithFormat: (const char*)fmt
      andArguments: (va_list)args
{
	return [[[OFMutableString alloc] initWithFormat: fmt
					   andArguments: args] autorelease];
}

- init
{
	[super init];

	length = 0;
	string = NULL;

	return self;
}

- (const char*)cString
{
	return string;
}

- (size_t)length
{
	return length;
}

- (id)copy
{
	return [OFString stringWithCString: string];
}

- (BOOL)isEqual: (id)obj
{
	if (![obj isKindOf: [OFString class]])
		return NO;
	if (strcmp(string, [obj cString]))
		return NO;

	return YES;
}

- (int)compare: (id)obj
{
	if (![obj isKindOf: [OFString class]])
		@throw [OFInvalidArgumentException newWithClass: isa];

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

- setTo: (const char*)str
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- append: (OFString*)str
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- appendCString: (const char*)str
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- appendWithFormatCString: (const char*)fmt, ...
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- appendWithFormatCString: (const char*)fmt
	     andArguments: (va_list)args
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- reverse
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- upper
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}

- lower
{
	@throw [OFNotImplementedException newWithClass: isa
					   andSelector: _cmd];
}
@end
