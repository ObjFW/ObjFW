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

#include "config.h"

#include <string.h>

#import "OFXMLParser.h"
#import "OFAutoreleasePool.h"
#import "OFExceptions.h"

int _OFXMLParser_reference;

@implementation OFXMLParser
+ xmlParser
{
	return [[[self alloc] init] autorelease];
}

- (id)delegate
{
	return [[delegate retain] autorelease];
}

- setDelegate: (OFObject <OFXMLParserDelegate>*)delegate_
{
	[delegate release];
	delegate = [delegate_ retain];

	return self;
}
@end

@implementation OFString (OFXMLUnescaping)
- stringByXMLUnescaping
{
	return [self stringByXMLUnescapingWithHandler: nil];
}

- stringByXMLUnescapingWithHandler: (OFObject <OFXMLUnescapingDelegate>*)h
{
	size_t i, last;
	BOOL in_entity;
	OFString *ret;

	last = 0;
	in_entity = NO;
	ret = [OFMutableString string];

	for (i = 0; i < length; i++) {
		if (!in_entity && string[i] == '&') {
			[ret appendCStringWithoutUTF8Checking: string + last
						    andLength: i - last];

			last = i + 1;
			in_entity = YES;
		} else if (in_entity && string[i] == ';') {
			size_t len = i - last;

			if (len == 2 && !memcmp(string + last, "lt", 2))
				[ret appendString: @"<"];
			else if (len == 2 && !memcmp(string + last, "gt", 2))
				[ret appendString: @">"];
			else if (len == 4 && !memcmp(string + last, "quot", 4))
				[ret appendString: @"\""];
			else if (len == 4 && !memcmp(string + last, "apos", 4))
				[ret appendString: @"'"];
			else if (len == 3 && !memcmp(string + last, "amp", 3))
				[ret appendString: @"&"];
			else if (h != nil) {
				OFAutoreleasePool *pool;
				OFString *n, *tmp;

				pool = [[OFAutoreleasePool alloc] init];

				n = [OFString stringWithCString: string + last
						      andLength: len];
				tmp = [h foundUnknownEntityNamed: n];

				if (tmp == nil)
					@throw [OFInvalidEncodingException
					    newWithClass: isa];

				[ret appendString: tmp];
				[pool release];
			} else
				@throw [OFInvalidEncodingException
				    newWithClass: isa];

			last = i + 1;
			in_entity = NO;
		}
	}

	if (in_entity)
		@throw [OFInvalidEncodingException newWithClass: isa];

	[ret appendCStringWithoutUTF8Checking: string + last
				    andLength: i - last];

	return ret;
}
@end
