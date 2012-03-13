/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#include <assert.h>

#import "OFDictionary.h"
#import "OFDictionary_hashtable.h"
#import "OFArray.h"
#import "OFString.h"
#import "OFXMLElement.h"
#import "OFAutoreleasePool.h"

#import "OFNotImplementedException.h"

static struct {
	Class isa;
} placeholder;

@interface OFDictionary_placeholder: OFDictionary
@end

@implementation OFDictionary_placeholder
- init
{
	return (id)[[OFDictionary_hashtable alloc] init];
}

- initWithDictionary: (OFDictionary*)dictionary
{
	return (id)[[OFDictionary_hashtable alloc]
	    initWithDictionary: dictionary];
}

- initWithObject: (id)object
	  forKey: (id)key
{
	return (id)[[OFDictionary_hashtable alloc] initWithObject: object
							   forKey: key];
}

- initWithObjects: (OFArray*)objects
	  forKeys: (OFArray*)keys
{
	return (id)[[OFDictionary_hashtable alloc] initWithObjects: objects
							   forKeys: keys];
}

- initWithKeysAndObjects: (id <OFCopying>)firstKey, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstKey);
	ret = [[OFDictionary_hashtable alloc] initWithKey: firstKey
						arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithKey: (id <OFCopying>)firstKey
    arguments: (va_list)arguments
{
	return (id)[[OFDictionary_hashtable alloc] initWithKey: firstKey
						     arguments: arguments];
}

- initWithSerialization: (OFXMLElement*)element
{
	return (id)[[OFDictionary_hashtable alloc]
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
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
	[super dealloc];	/* Get rid of a stupid warning */
}
@end

@implementation OFDictionary
+ (void)initialize
{
	if (self == [OFDictionary class])
		placeholder.isa = [OFDictionary_placeholder class];
}

+ alloc
{
	if (self == [OFDictionary class])
		return (id)&placeholder;

	return [super alloc];
}

+ dictionary
{
	return [[[self alloc] init] autorelease];
}

+ dictionaryWithDictionary: (OFDictionary*)dictionary
{
	return [[[self alloc] initWithDictionary: dictionary] autorelease];
}

+ dictionaryWithObject: (id)object
		forKey: (id)key
{
	return [[[self alloc] initWithObject: object
				      forKey: key] autorelease];
}

+ dictionaryWithObjects: (OFArray*)objects
		forKeys: (OFArray*)keys
{
	return [[[self alloc] initWithObjects: objects
				      forKeys: keys] autorelease];
}

+ dictionaryWithKeysAndObjects: (id)firstKey, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstKey);
	ret = [[[self alloc] initWithKey: firstKey
			       arguments: arguments] autorelease];
	va_end(arguments);

	return ret;
}

- init
{
	if (isa == [OFDictionary class]) {
		Class c = isa;
		[self release];
		@throw [OFNotImplementedException exceptionWithClass: c
							    selector: _cmd];
	}

	return [super init];
}

- initWithDictionary: (OFDictionary*)dictionary
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithObject: (id)object
	  forKey: (id)key
{
	return [self initWithKeysAndObjects: key, object, nil];
}

- initWithObjects: (OFArray*)objects
	  forKeys: (OFArray*)keys
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithKeysAndObjects: (id)firstKey, ...
{
	id ret;
	va_list arguments;

	va_start(arguments, firstKey);
	ret = [self initWithKey: firstKey
		      arguments: arguments];
	va_end(arguments);

	return ret;
}

- initWithKey: (id)firstKey
    arguments: (va_list)arguments
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithSerialization: (OFXMLElement*)element
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- (id)objectForKey: (id)key
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (size_t)count
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- copy
{
	return [self retain];
}

- mutableCopy
{
	return [[OFMutableDictionary alloc] initWithDictionary: self];
}

- (BOOL)isEqual: (id)object
{
	OFDictionary *otherDictionary;
	OFAutoreleasePool *pool;
	OFEnumerator *enumerator;
	id key;

	if (![object isKindOfClass: [OFDictionary class]])
		return NO;

	otherDictionary = object;

	if ([otherDictionary count] != [self count])
		return NO;

	pool = [[OFAutoreleasePool alloc] init];

	enumerator = [self keyEnumerator];
	while ((key = [enumerator nextObject]) != nil) {
		id object = [otherDictionary objectForKey: key];

		if (object == nil ||
		    ![object isEqual: [self objectForKey: key]]) {
			[pool release];
			return NO;
		}
	}

	[pool release];

	return YES;
}

- (BOOL)containsObject: (id)object
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFEnumerator *enumerator = [self objectEnumerator];
	id currentObject;

	while ((currentObject = [enumerator nextObject]) != nil) {
		if ([currentObject isEqual: object]) {
			[pool release];
			return YES;
		}
	}

	[pool release];

	return NO;
}

- (BOOL)containsObjectIdenticalTo: (id)object
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFEnumerator *enumerator = [self objectEnumerator];
	id currentObject;

	while ((currentObject = [enumerator nextObject]) != nil) {
		if (currentObject == object) {
			[pool release];
			return YES;
		}
	}

	[pool release];

	return NO;
}

- (OFArray*)allKeys
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	id *cArray = [self allocMemoryForNItems: [self count]
					 ofSize: sizeof(id)];
	OFArray *ret;
	OFEnumerator *enumerator;
	id key;
	size_t i = 0;

	pool = [[OFAutoreleasePool alloc] init];
	enumerator = [self keyEnumerator];

	while ((key = [enumerator nextObject]) != nil)
		cArray[i++] = key;

	assert(i == [self count]);

	[pool release];

	@try {
		ret = [OFArray arrayWithCArray: cArray
					length: [self count]];
	} @finally {
		[self freeMemory: cArray];
	}

	return ret;
}

- (OFArray*)allObjects
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	id *cArray = [self allocMemoryForNItems: [self count]
					 ofSize: sizeof(id)];
	OFArray *ret;
	OFEnumerator *enumerator;
	id object;
	size_t i = 0;

	pool = [[OFAutoreleasePool alloc] init];
	enumerator = [self objectEnumerator];

	while ((object = [enumerator nextObject]) != nil)
		cArray[i++] = object;

	assert(i == [self count]);

	[pool release];

	@try {
		ret = [OFArray arrayWithCArray: cArray
					length: [self count]];
	} @finally {
		[self freeMemory: cArray];
	}

	return ret;
}

- (OFEnumerator*)objectEnumerator
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (OFEnumerator*)keyEnumerator
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count_
{
	@throw [OFNotImplementedException exceptionWithClass: isa
						    selector: _cmd];
}

#if defined(OF_HAVE_BLOCKS) && defined(OF_HAVE_FAST_ENUMERATION)
- (void)enumerateKeysAndObjectsUsingBlock:
    (of_dictionary_enumeration_block_t)block
{
	BOOL stop = NO;

	for (id key in self) {
		block(key, [self objectForKey: key], &stop);

		if (stop)
			break;
	}
}
#endif

#ifdef OF_HAVE_BLOCKS
- (OFDictionary*)mappedDictionaryUsingBlock: (of_dictionary_map_block_t)block
{
	OFMutableDictionary *new = [OFMutableDictionary dictionary];

	[self enumerateKeysAndObjectsUsingBlock: ^ (id key, id object,
	    BOOL *stop) {
		[new setObject: block(key, object)
			forKey: key];
	}];

	[new makeImmutable];

	return new;
}

- (OFDictionary*)filteredDictionaryUsingBlock:
    (of_dictionary_filter_block_t)block
{
	OFMutableDictionary *new = [OFMutableDictionary dictionary];

	[self enumerateKeysAndObjectsUsingBlock: ^ (id key, id object,
	    BOOL *stop) {
		if (block(key, object))
			[new setObject: object
				forKey: key];
	}];

	[new makeImmutable];

	return new;
}
#endif

- (uint32_t)hash
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFEnumerator *enumerator = [self keyEnumerator];
	id key;
	uint32_t hash = 0;

	while ((key = [enumerator nextObject]) != nil) {
		hash += [key hash];
		hash += [[self objectForKey: key] hash];
	}

	[pool release];

	return hash;
}

- (OFString*)description
{
	OFMutableString *ret;
	OFAutoreleasePool *pool, *pool2;
	OFEnumerator *keyEnumerator, *objectEnumerator;
	id key, object;
	size_t i, count = [self count];

	if (count == 0)
		return @"{}";

	ret = [OFMutableString stringWithString: @"{\n"];
	pool = [[OFAutoreleasePool alloc] init];
	keyEnumerator = [self keyEnumerator];
	objectEnumerator = [self objectEnumerator];

	i = 0;
	pool2 = [[OFAutoreleasePool alloc] init];

	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil) {
		[ret appendString: [key description]];
		[ret appendString: @" = "];
		[ret appendString: [object description]];

		if (++i < count)
			[ret appendString: @";\n"];

		[pool2 releaseObjects];
	}
	[ret replaceOccurrencesOfString: @"\n"
			     withString: @"\n\t"];
	[ret appendString: @";\n}"];

	[ret makeImmutable];

	[pool release];

	return ret;
}

- (OFXMLElement*)XMLElementBySerializing
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFAutoreleasePool *pool2;
	OFXMLElement *element;
	OFEnumerator *keyEnumerator, *objectEnumerator;
	id key, object;

	if ([self isKindOfClass: [OFMutableDictionary class]])
		element = [OFXMLElement elementWithName: @"OFMutableDictionary"
					      namespace: OF_SERIALIZATION_NS];
	else
		element = [OFXMLElement elementWithName: @"OFDictionary"
					      namespace: OF_SERIALIZATION_NS];

	keyEnumerator = [self keyEnumerator];
	objectEnumerator = [self objectEnumerator];
	pool2 = [[OFAutoreleasePool alloc] init];

	while ((key = [keyEnumerator nextObject]) != nil &&
	       (object = [objectEnumerator nextObject]) != nil) {
		OFXMLElement *keyElement, *objectElement;

		keyElement = [OFXMLElement
		    elementWithName: @"key"
			  namespace: OF_SERIALIZATION_NS];
		[keyElement addChild: [key XMLElementBySerializing]];

		objectElement = [OFXMLElement
		    elementWithName: @"object"
			  namespace: OF_SERIALIZATION_NS];
		[objectElement addChild: [object XMLElementBySerializing]];

		[element addChild: keyElement];
		[element addChild: objectElement];

		[pool2 releaseObjects];
	}

	[element retain];
	[pool release];
	[element autorelease];

	return element;
}

- (OFString*)JSONRepresentation
{
	OFMutableString *JSON = [OFMutableString stringWithString: @"{"];
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init], *pool2;
	OFEnumerator *keyEnumerator = [self keyEnumerator];
	OFEnumerator *objectEnumerator = [self objectEnumerator];
	size_t i = 0, count = [self count];
	OFString *key;
	OFString *object;

	pool2 = [[OFAutoreleasePool alloc] init];

	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil) {
		[JSON appendString: [key JSONRepresentation]];
		[JSON appendString: @":"];
		[JSON appendString: [object JSONRepresentation]];

		if (++i < count)
			[JSON appendString: @","];

		[pool2 releaseObjects];
	}

	[pool release];

	[JSON appendString: @"}"];
	[JSON makeImmutable];

	return JSON;
}
@end
