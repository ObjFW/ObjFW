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

#import "OFMutableDictionary_hashtable.h"
#import "OFAutoreleasePool.h"

#import "OFNotImplementedException.h"

#import "macros.h"

static struct {
	Class isa;
} placeholder;

@implementation OFMutableDictionary_placeholder
- init
{
	return (id)[[OFMutableDictionary_hashtable alloc] init];
}

- initWithDictionary: (OFDictionary*)dictionary
{
	return (id)[[OFMutableDictionary_hashtable alloc]
	    initWithDictionary: dictionary];
}

- initWithObject: (id)object
	  forKey: (id <OFCopying>)key
{
	return (id)[[OFMutableDictionary_hashtable alloc] initWithObject: object
								  forKey: key];
}

- initWithObjects: (OFArray*)objects
	  forKeys: (OFArray*)keys
{
	return (id)[[OFMutableDictionary_hashtable alloc]
	    initWithObjects: objects
		    forKeys: keys];
}

- initWithKeysAndObjects: (id <OFCopying>)firstKey, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstKey);
	ret = (id)[[OFMutableDictionary_hashtable alloc]
	    initWithKey: firstKey
	      arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithKey: (id <OFCopying>)firstKey
    arguments: (va_list)arguments
{
	return (id)[[OFMutableDictionary_hashtable alloc]
	    initWithKey: firstKey
	      arguments: arguments];
}

- initWithSerialization: (OFXMLElement*)element
{
	return (id)[[OFMutableDictionary_hashtable alloc]
	    initWithSerialization: element];
}

- retain
{
	return self;
}

- autorelease
{
	return self;
}

- (void)release
{
}

- (void)dealloc
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
	[super dealloc];	/* Get rid of a stupid warning */
}
@end

@implementation OFMutableDictionary
+ (void)initialize
{
	if (self == [OFMutableDictionary class])
		placeholder.isa = [OFMutableDictionary_placeholder class];
}

+ alloc
{
	if (self == [OFMutableDictionary class])
		return (id)&placeholder;

	return [super alloc];
}

- (void)setObject: (id)object
	   forKey: (id <OFCopying>)key
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- (void)removeObjectForKey: (id <OFCopying>)key
{
	@throw [OFNotImplementedException newWithClass: isa
					      selector: _cmd];
}

- copy
{
	return [[OFDictionary alloc] initWithDictionary: self];
}

#ifdef OF_HAVE_BLOCKS
- (void)replaceObjectsUsingBlock: (of_dictionary_replace_block_t)block
{
	[self enumerateKeysAndObjectsUsingBlock: ^ (id key, id object,
	    BOOL *stop) {
		[self setObject: block(key, object, stop)
			 forKey: key];
	}];
}
#endif

- (void)makeImmutable
{
}
@end
