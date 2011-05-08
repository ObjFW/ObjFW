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

#include <string.h>
#include <assert.h>

#import "OFXMLElement.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFXMLAttribute.h"
#import "OFXMLParser.h"
#import "OFXMLElementBuilder.h"
#import "OFAutoreleasePool.h"

#import "OFInvalidArgumentException.h"
#import "OFMalformedXMLException.h"
#import "OFNotImplementedException.h"
#import "OFUnboundNamespaceException.h"

@interface OFXMLElement_OFXMLElementBuilderDelegate: OFObject
{
@public
	OFXMLElement *element;
}
@end

@implementation OFXMLElement_OFXMLElementBuilderDelegate
- (void)elementBuilder: (OFXMLElementBuilder*)builder
       didBuildElement: (OFXMLElement*)element_
{
	element = [element_ retain];
}

- (void)dealloc
{
	[element release];

	[super dealloc];
}
@end

@implementation OFXMLElement
+ elementWithName: (OFString*)name
{
	return [[[self alloc] initWithName: name] autorelease];
}

+ elementWithName: (OFString*)name
      stringValue: (OFString*)stringValue
{
	return [[[self alloc] initWithName: name
			       stringValue: stringValue] autorelease];
}

+ elementWithName: (OFString*)name
	namespace: (OFString*)ns
{
	return [[[self alloc] initWithName: name
				 namespace: ns] autorelease];
}

+ elementWithName: (OFString*)name
	namespace: (OFString*)ns
      stringValue: (OFString*)stringValue
{
	return [[[self alloc] initWithName: name
				 namespace: ns
			       stringValue: stringValue] autorelease];
}

+ elementWithCharacters: (OFString*)characters
{
	return [[[self alloc] initWithCharacters: characters] autorelease];
}

+ elementWithCDATA: (OFString*)CDATA
{
	return [[[self alloc] initWithCDATA: CDATA] autorelease];
}

+ elementWithComment: (OFString*)comment
{
	return [[[self alloc] initWithComment: comment] autorelease];
}

+ elementWithElement: (OFXMLElement*)element
{
	return [[[self alloc] initWithElement: element] autorelease];
}

+ elementWithXMLString: (OFString*)string
{
	return [[[self alloc] initWithXMLString: string] autorelease];
}

- init
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException newWithClass: c
					      selector: _cmd];
}

- initWithName: (OFString*)name_
{
	return [self initWithName: name_
			namespace: nil
		      stringValue: nil];
}

- initWithName: (OFString*)name_
   stringValue: (OFString*)stringValue
{
	return [self initWithName: name_
			namespace: nil
		      stringValue: stringValue];
}

- initWithName: (OFString*)name_
     namespace: (OFString*)ns_
{
	return [self initWithName: name_
			namespace: ns_
		      stringValue: nil];
}

- initWithName: (OFString*)name_
     namespace: (OFString*)ns_
   stringValue: (OFString*)stringValue
{
	self = [super init];

	@try {
		name = [name_ copy];
		ns = [ns_ copy];

		if (stringValue != nil) {
			OFAutoreleasePool *pool;

			pool = [[OFAutoreleasePool alloc] init];
			[self addChild:
			    [OFXMLElement elementWithCharacters: stringValue]];
			[pool release];
		}

		namespaces = [[OFMutableDictionary alloc]
		    initWithKeysAndObjects:
		    @"http://www.w3.org/XML/1998/namespace", @"xml",
		    @"http://www.w3.org/2000/xmlns/", @"xmlns", nil];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithCharacters: (OFString*)characters_
{
	self = [super init];

	@try {
		characters = [characters_ copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithCDATA: (OFString*)CDATA_
{
	self = [super init];

	@try {
		CDATA = [CDATA_ copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithComment: (OFString*)comment_
{
	self = [super init];

	@try {
		comment = [comment_ copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithElement: (OFXMLElement*)element
{
	self = [super init];

	@try {
		name = [element->name copy];
		ns = [element->ns copy];
		defaultNamespace = [element->defaultNamespace copy];
		attributes = [element->attributes mutableCopy];
		namespaces = [element->namespaces mutableCopy];
		children = [element->children mutableCopy];
		characters = [element->characters copy];
		CDATA = [element->CDATA copy];
		comment = [element->comment copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithXMLString: (OFString*)string
{
	OFAutoreleasePool *pool;
	OFXMLParser *parser;
	OFXMLElementBuilder *builder;
	OFXMLElement_OFXMLElementBuilderDelegate *delegate;
	Class c;

	c = isa;
	[self release];

	pool = [[OFAutoreleasePool alloc] init];

	parser = [OFXMLParser parser];
	builder = [OFXMLElementBuilder elementBuilder];
	delegate = [[[OFXMLElement_OFXMLElementBuilderDelegate alloc] init]
	    autorelease];

	[parser setDelegate: builder];
	[builder setDelegate: delegate];

	[parser parseString: string];

	if (![parser finishedParsing])
		@throw [OFMalformedXMLException newWithClass: c
						      parser: parser];

	self = [delegate->element retain];

	@try {
		[pool release];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (OFString*)name
{
	return [[name copy] autorelease];
}

- (OFString*)namespace
{
	return [[ns copy] autorelease];
}

- (OFArray*)attributes
{
	return [[attributes copy] autorelease];
}

- (void)setChildren: (OFArray*)children_
{
	OFMutableArray *new = [children_ mutableCopy];

	@try {
		[children release];
	} @catch (id e) {
		[new release];
		@throw e;
	}

	children = new;
}

- (OFArray*)children
{
	return [[children copy] autorelease];
}

- (void)setStringValue: (OFString*)stringValue
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

	[self setChildren: [OFArray arrayWithObject:
	    [OFXMLElement elementWithCharacters: stringValue]]];

	[pool release];
}

- (OFString*)stringValue
{
	OFAutoreleasePool *pool;
	OFMutableString *ret;
	OFXMLElement **cArray;
	size_t i, count = [children count];

	if (count == 0)
		return @"";

	ret = [OFMutableString string];
	cArray = [children cArray];
	pool = [[OFAutoreleasePool alloc] init];

	for (i = 0; i < count; i++) {
		if (cArray[i]->characters != nil)
			[ret appendString: cArray[i]->characters];
		else if (cArray[i]->CDATA != nil)
			[ret appendString: cArray[i]->CDATA];
		else if (cArray[i]->comment == nil) {
			[ret appendString: [cArray[i] stringValue]];
			[pool releaseObjects];
		}
	}

	[pool release];

	/*
	 * Class swizzle the string to be immutable. We declared the return type
	 * to be OFString*, so it can't be modified anyway. But not swizzling it
	 * would create a real copy each time -[copy] is called.
	 */
	ret->isa = [OFString class];
	return ret;
}

- (OFString*)_XMLStringWithParent: (OFXMLElement*)parent
{
	OFAutoreleasePool *pool, *pool2;
	char *cString;
	size_t length, i, j, attributesCount;
	OFString *prefix, *parentPrefix;
	OFXMLAttribute **attributesCArray;
	OFString *ret, *tmp;
	OFMutableDictionary *allNamespaces;
	OFString *defaultNS;

	if (characters != nil)
		return [characters stringByXMLEscaping];

	if (CDATA != nil)
		return [OFString stringWithFormat: @"<![CDATA[%@]]>", CDATA];

	if (comment != nil)
		return [OFString stringWithFormat: @"<!--%@-->", comment];

	pool = [[OFAutoreleasePool alloc] init];
	defaultNS = (defaultNamespace != nil
	    ? defaultNamespace
	    : (parent != nil ? parent->defaultNamespace : (OFString*)nil));

	if (parent != nil && parent->namespaces != nil) {
		OFEnumerator *keyEnumerator = [namespaces keyEnumerator];
		OFEnumerator *objectEnumerator = [namespaces objectEnumerator];
		id key, object;

		allNamespaces = [[parent->namespaces mutableCopy] autorelease];

		while ((key = [keyEnumerator nextObject]) != nil &&
		    (object = [objectEnumerator nextObject]) != nil)
			[allNamespaces setObject: object
					  forKey: key];
	} else
		allNamespaces = namespaces;

	prefix = [allNamespaces objectForKey:
	    (ns != nil ? ns : (OFString*)@"")];
	parentPrefix = [allNamespaces objectForKey:
	    (parent != nil && parent->ns != nil ? parent->ns : (OFString*)@"")];

	i = 0;
	length = [name cStringLength] + 3;
	cString = [self allocMemoryWithSize: length];

	/* Start of tag */
	cString[i++] = '<';

	if (prefix != nil && ![ns isEqual: defaultNS] &&
	    (![ns isEqual: (parent != nil ? parent->ns : (OFString*)nil)] ||
	    parentPrefix != nil)) {
		length += [prefix cStringLength] + 1;
		@try {
			cString = [self resizeMemory: cString
					      toSize: length];
		} @catch (id e) {
			[self freeMemory: cString];
			@throw e;
		}

		memcpy(cString + i, [prefix cString], [prefix cStringLength]);
		i += [prefix cStringLength];
		cString[i++] = ':';
	}

	memcpy(cString + i, [name cString], [name cStringLength]);
	i += [name cStringLength];

	/* xmlns if necessary */
	if (ns != nil && prefix == nil && ![ns isEqual: defaultNS] &&
	     (![ns isEqual: (parent != nil ? parent->ns : (OFString*)nil)] ||
	     parentPrefix != nil)) {
		length += [ns cStringLength] + 9;
		@try {
			cString = [self resizeMemory: cString
					      toSize: length];
		} @catch (id e) {
			[self freeMemory: cString];
			@throw e;
		}

		memcpy(cString + i, " xmlns='", 8);
		i += 8;
		memcpy(cString + i, [ns cString], [ns cStringLength]);
		i += [ns cStringLength];
		cString[i++] = '\'';

		defaultNS = ns;
	}

	/* Attributes */
	attributesCArray = [attributes cArray];
	attributesCount = [attributes count];

	pool2 = [[OFAutoreleasePool alloc] init];
	for (j = 0; j < attributesCount; j++) {
		OFString *attributeName = [attributesCArray[j] name];
		OFString *attributePrefix = nil;
		tmp = [[attributesCArray[j] stringValue] stringByXMLEscaping];

		if ([attributesCArray[j] namespace] != nil &&
		    (attributePrefix = [allNamespaces objectForKey:
		    [attributesCArray[j] namespace]]) == nil)
			@throw [OFUnboundNamespaceException
			    newWithClass: isa
			       namespace: [attributesCArray[j] namespace]];

		length += [attributeName cStringLength] +
		    (attributePrefix != nil ?
		    [attributePrefix cStringLength] + 1 : 0) +
		    [tmp cStringLength] + 4;

		@try {
			cString = [self resizeMemory: cString
					      toSize: length];
		} @catch (id e) {
			[self freeMemory: cString];
			@throw e;
		}

		cString[i++] = ' ';
		if (attributePrefix != nil) {
			memcpy(cString + i, [attributePrefix cString],
			    [attributePrefix cStringLength]);
			i += [attributePrefix cStringLength];
			cString[i++] = ':';
		}
		memcpy(cString + i, [attributeName cString],
		    [attributeName cStringLength]);
		i += [attributeName cStringLength];
		cString[i++] = '=';
		cString[i++] = '\'';
		memcpy(cString + i, [tmp cString], [tmp cStringLength]);
		i += [tmp cStringLength];
		cString[i++] = '\'';

		[pool2 releaseObjects];
	}

	/* Childen */
	if (children != nil) {
		OFXMLElement **childrenCArray = [children cArray];
		size_t childrenCount = [children count];
		IMP append;
		SEL appendSel = @selector(appendCStringWithoutUTF8Checking:);

		tmp = [OFMutableString string];
		append = [tmp methodForSelector: appendSel];

		for (j = 0; j < childrenCount; j++)
			append(tmp, appendSel,
			    [[childrenCArray[j] _XMLStringWithParent: self]
			    cString]);

		length += [tmp cStringLength] + [name cStringLength] + 2;
		@try {
			cString = [self resizeMemory: cString
					      toSize: length];
		} @catch (id e) {
			[self freeMemory: cString];
			@throw e;
		}

		cString[i++] = '>';
		memcpy(cString + i, [tmp cString], [tmp cStringLength]);
		i += [tmp cStringLength];
		cString[i++] = '<';
		cString[i++] = '/';
		if (prefix != nil) {
			length += [prefix cStringLength] + 1;
			@try {
				cString = [self resizeMemory: cString
						      toSize: length];
			} @catch (id e) {
				[self freeMemory: cString];
				@throw e;
			}

			memcpy(cString + i, [prefix cString],
			    [prefix cStringLength]);
			i += [prefix cStringLength];
			cString[i++] = ':';
		}
		memcpy(cString + i, [name cString], [name cStringLength]);
		i += [name cStringLength];
	} else
		cString[i++] = '/';

	cString[i++] = '>';
	assert(i == length);

	[pool release];

	@try {
		ret = [OFString stringWithCString: cString
					   length: length];
	} @finally {
		[self freeMemory: cString];
	}
	return ret;
}

- (OFString*)XMLString
{
	return [self _XMLStringWithParent: nil];
}

- (OFString*)description
{
	return [self XMLString];
}

- (OFString*)stringBySerializing
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFString *ret = [[OFString alloc]
	    initWithFormat: @"(class=OFXMLElement)<%@>",
			    [[self XMLString] stringBySerializing]];

	@try {
		[pool release];
	} @finally {
		[ret autorelease];
	}

	return ret;
}

- (void)addAttribute: (OFXMLAttribute*)attribute
{
	if (name == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if (attributes == nil)
		attributes = [[OFMutableArray alloc] init];

	if ([self attributeForName: attribute->name
			 namespace: attribute->ns] == nil)
		[attributes addObject: attribute];
}

- (void)addAttributeWithName: (OFString*)name_
		 stringValue: (OFString*)stringValue
{
	[self addAttributeWithName: name_
			 namespace: nil
		       stringValue: stringValue];
}

- (void)addAttributeWithName: (OFString*)name_
		   namespace: (OFString*)ns_
		 stringValue: (OFString*)stringValue
{
	OFAutoreleasePool *pool;

	if (name == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	pool = [[OFAutoreleasePool alloc] init];
	[self addAttribute: [OFXMLAttribute attributeWithName: name_
						    namespace: ns_
						  stringValue: stringValue]];
	[pool release];
}

- (OFXMLAttribute*)attributeForName: (OFString*)attributeName
{
	OFXMLAttribute **cArray = [attributes cArray];
	size_t i, count = [attributes count];

	for (i = 0; i < count; i++)
		if (cArray[i]->ns == nil &&
		    [cArray[i]->name isEqual: attributeName])
			return cArray[i];

	return nil;
}

- (OFXMLAttribute*)attributeForName: (OFString*)attributeName
			  namespace: (OFString*)attributeNS
{
	OFXMLAttribute **cArray;
	size_t i, count;

	if (attributeNS == nil)
		return [self attributeForName: attributeName];

	cArray = [attributes cArray];
	count = [attributes count];

	for (i = 0; i < count; i++)
		if ([cArray[i]->ns isEqual: attributeNS] &&
		    [cArray[i]->name isEqual: attributeName])
			return cArray[i];

	return nil;
}

- (void)removeAttributeForName: (OFString*)attributeName
{
	OFXMLAttribute **cArray = [attributes cArray];
	size_t i, count = [attributes count];

	for (i = 0; i < count; i++) {
		if (cArray[i]->ns == nil &&
		    [cArray[i]->name isEqual: attributeName]) {
			[attributes removeObjectAtIndex: i];

			return;
		}
	}
}

- (void)removeAttributeForName: (OFString*)attributeName
		     namespace: (OFString*)attributeNS
{
	OFXMLAttribute **cArray;
	size_t i, count;

	if (attributeNS == nil)
		return [self removeAttributeForName: attributeName];

	cArray = [attributes cArray];
	count = [attributes count];

	for (i = 0; i < count; i++) {
		if ([cArray[i]->ns isEqual: attributeNS] &&
		    [cArray[i]->name isEqual: attributeName]) {
			[attributes removeObjectAtIndex: i];
				return;
		}
	}
}

- (void)setPrefix: (OFString*)prefix
     forNamespace: (OFString*)ns_
{
	if (name == nil || prefix == nil || [prefix isEqual: @""])
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];
	if (ns_ == nil)
		ns_ = @"";

	[namespaces setObject: prefix
		       forKey: ns_];
}

- (void)bindPrefix: (OFString*)prefix
      forNamespace: (OFString*)ns_
{
	[self setPrefix: prefix
	   forNamespace: ns_];
	[self addAttributeWithName: prefix
			 namespace: @"http://www.w3.org/2000/xmlns/"
		       stringValue: ns_];
}

- (OFString*)defaultNamespace
{
	if (name == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	return [[defaultNamespace retain] autorelease];
}

- (void)setDefaultNamespace: (OFString*)ns_
{
	if (name == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	OFString *old = defaultNamespace;
	defaultNamespace = [ns_ copy];
	[old release];
}

- (void)addChild: (OFXMLElement*)child
{
	if (name == nil)
		@throw [OFInvalidArgumentException newWithClass: isa
						       selector: _cmd];

	if (children == nil)
		children = [[OFMutableArray alloc] init];

	[children addObject: child];
}

- (OFXMLElement*)elementForName: (OFString*)elementName
{
	return [[self elementsForName: elementName] firstObject];
}

- (OFXMLElement*)elementForName: (OFString*)elementName
		      namespace: (OFString*)elementNS
{
	return [[self elementsForName: elementName
			    namespace: elementNS] firstObject];
}

- (OFArray*)elementsForName: (OFString*)elementName
{
	OFMutableArray *ret = [OFMutableArray array];
	OFXMLElement **cArray = [children cArray];
	size_t i, count = [children count];

	for (i = 0; i < count; i++)
		if (cArray[i]->ns == nil &&
		    [cArray[i]->name isEqual: elementName])
			[ret addObject: cArray[i]];

	return ret;
}

- (OFArray*)elementsForName: (OFString*)elementName
		  namespace: (OFString*)elementNS
{
	OFMutableArray *ret;
	OFXMLElement **cArray;
	size_t i, count;

	if (elementNS == nil)
		return [self elementsForName: elementName];

	ret = [OFMutableArray array];
	cArray = [children cArray];
	count = [children count];

	for (i = 0; i < count; i++)
		if ([cArray[i]->ns isEqual: elementNS] &&
		    [cArray[i]->name isEqual: elementName])
			[ret addObject: cArray[i]];

	return ret;
}

- (void)dealloc
{
	[name release];
	[ns release];
	[defaultNamespace release];
	[attributes release];
	[namespaces release];
	[children release];
	[characters release];
	[CDATA release];
	[comment release];

	[super dealloc];
}
@end
