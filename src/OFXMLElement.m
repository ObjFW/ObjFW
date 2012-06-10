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

#include <string.h>
#include <assert.h>

#import "OFXMLElement.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFDataArray.h"
#import "OFXMLAttribute.h"
#import "OFXMLCharacters.h"
#import "OFXMLCDATA.h"
#import "OFXMLParser.h"
#import "OFXMLElementBuilder.h"
#import "OFAutoreleasePool.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFMalformedXMLException.h"
#import "OFNotImplementedException.h"
#import "OFUnboundNamespaceException.h"

#import "macros.h"

/* References for static linking */
void _references_to_categories_of_OFXMLElement(void)
{
	_OFXMLElement_Serialization_reference = 1;
}

static Class charactersClass = Nil;
static Class CDATAClass = Nil;

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
	if (element == nil)
		element = [element_ retain];
}

- (void)dealloc
{
	[element release];

	[super dealloc];
}
@end

@implementation OFXMLElement
+ (void)initialize
{
	if (self == [OFXMLElement class]) {
		charactersClass = [OFXMLCharacters class];
		CDATAClass = [OFXMLCDATA class];
	}
}

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

+ elementWithElement: (OFXMLElement*)element
{
	return [[[self alloc] initWithElement: element] autorelease];
}

+ elementWithXMLString: (OFString*)string
{
	return [[[self alloc] initWithXMLString: string] autorelease];
}

+ elementWithFile: (OFString*)path
{
	return [[[self alloc] initWithFile: path] autorelease];
}

- init
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
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
		if (name_ == nil)
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		name = [name_ copy];
		ns = [ns_ copy];

		namespaces = [[OFMutableDictionary alloc]
		    initWithKeysAndObjects:
		    @"http://www.w3.org/XML/1998/namespace", @"xml",
		    @"http://www.w3.org/2000/xmlns/", @"xmlns", nil];

		if (stringValue != nil)
			[self setStringValue: stringValue];
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
		if (element == nil)
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		name = [element->name copy];
		ns = [element->ns copy];
		defaultNamespace = [element->defaultNamespace copy];
		attributes = [element->attributes mutableCopy];
		namespaces = [element->namespaces mutableCopy];
		children = [element->children mutableCopy];
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

	if (string == nil)
		@throw [OFInvalidArgumentException exceptionWithClass: isa
							     selector: _cmd];

	pool = [[OFAutoreleasePool alloc] init];

	parser = [OFXMLParser parser];
	builder = [OFXMLElementBuilder elementBuilder];
	delegate = [[[OFXMLElement_OFXMLElementBuilderDelegate alloc] init]
	    autorelease];

	[parser setDelegate: builder];
	[builder setDelegate: delegate];

	[parser parseString: string];

	if (![parser finishedParsing])
		@throw [OFMalformedXMLException exceptionWithClass: c
							    parser: parser];

	self = [delegate->element retain];

	[pool release];

	return self;
}

- initWithFile: (OFString*)path
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

	[parser parseFile: path];

	if (![parser finishedParsing])
		@throw [OFMalformedXMLException exceptionWithClass: c
							    parser: parser];

	self = [delegate->element retain];

	[pool release];

	return self;
}

- initWithSerialization: (OFXMLElement*)element
{
	self = [super init];

	@try {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		OFXMLElement *attributesElement, *namespacesElement;
		OFXMLElement *childrenElement;
		OFEnumerator *keyEnumerator, *objectEnumerator;
		id key, object;

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		name = [[[element attributeForName: @"name"] stringValue] copy];
		ns = [[[element attributeForName: @"namespace"] stringValue]
		    copy];
		defaultNamespace = [[[element attributeForName:
		    @"defaultNamespace"] stringValue] copy];

		attributesElement = [[[element
		    elementForName: @"attributes"
			 namespace: OF_SERIALIZATION_NS] elementsForNamespace:
		    OF_SERIALIZATION_NS] firstObject];
		namespacesElement = [[[element
		    elementForName: @"namespaces"
			 namespace: OF_SERIALIZATION_NS] elementsForNamespace:
		    OF_SERIALIZATION_NS] firstObject];
		childrenElement = [[[element
		    elementForName: @"children"
			 namespace: OF_SERIALIZATION_NS] elementsForNamespace:
		    OF_SERIALIZATION_NS] firstObject];

		attributes = [[attributesElement objectByDeserializing]
		    mutableCopy];
		namespaces = [[namespacesElement objectByDeserializing]
		    mutableCopy];
		children = [[childrenElement objectByDeserializing]
		    mutableCopy];

		/* Sanity checks */
		if ((attributes != nil &&
		    ![attributes isKindOfClass: [OFMutableArray class]]) ||
		    (namespaces != nil &&
		    ![namespaces isKindOfClass: [OFMutableDictionary class]]) ||
		    (children != nil &&
		    ![children isKindOfClass: [OFMutableArray class]]))
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		objectEnumerator = [attributes objectEnumerator];
		while ((object = [objectEnumerator nextObject]) != nil)
			if (![object isKindOfClass: [OFXMLAttribute class]])
				@throw [OFInvalidArgumentException
				    exceptionWithClass: isa
					      selector: _cmd];

		keyEnumerator = [namespaces keyEnumerator];
		objectEnumerator = [namespaces objectEnumerator];
		while ((key = [keyEnumerator nextObject]) != nil &&
		    (object = [objectEnumerator nextObject]) != nil)
			if (![key isKindOfClass: [OFString class]] ||
			    ![object isKindOfClass: [OFString class]])
				@throw [OFInvalidArgumentException
				    exceptionWithClass: isa
					      selector: _cmd];

		objectEnumerator = [children objectEnumerator];
		while ((object = [objectEnumerator nextObject]) != nil)
			if (![object isKindOfClass: [OFXMLNode class]])
				@throw [OFInvalidArgumentException
				    exceptionWithClass: isa
					      selector: _cmd];

		if (namespaces == nil)
			namespaces = [[OFMutableDictionary alloc] init];

		[namespaces setObject: @"xml"
			       forKey: @"http://www.w3.org/XML/1998/namespace"];
		[namespaces setObject: @"xmlns"
			       forKey: @"http://www.w3.org/2000/xmlns/"];

		if (name == nil)
			@throw [OFInvalidArgumentException
			    exceptionWithClass: isa
				      selector: _cmd];

		[pool release];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)setName: (OFString*)name_
{
	if (name_ == nil)
		@throw [OFInvalidArgumentException exceptionWithClass: isa
							     selector: _cmd];

	OF_SETTER(name, name_, YES, 1)
}

- (OFString*)name
{
	OF_GETTER(name, YES)
}

- (void)setNamespace: (OFString*)ns_
{
	OF_SETTER(ns, ns_, YES, 1)
}

- (OFString*)namespace
{
	OF_GETTER(ns, YES)
}

- (OFArray*)attributes
{
	OF_GETTER(attributes, YES)
}

- (void)setChildren: (OFArray*)children_
{
	OF_SETTER(children, children_, YES, 2)
}

- (OFArray*)children
{
	OF_GETTER(children, YES)
}

- (void)setStringValue: (OFString*)stringValue
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

	[self setChildren: [OFArray arrayWithObject:
	    [OFXMLCharacters charactersWithString: stringValue]]];

	[pool release];
}

- (OFString*)stringValue
{
	OFAutoreleasePool *pool;
	OFMutableString *ret;
	OFXMLElement **objects;
	size_t i, count = [children count];

	if (count == 0)
		return @"";

	ret = [OFMutableString string];
	objects = [children objects];
	pool = [[OFAutoreleasePool alloc] init];

	for (i = 0; i < count; i++) {
		[ret appendString: [objects[i] stringValue]];
		[pool releaseObjects];
	}

	[ret makeImmutable];

	[pool release];

	return ret;
}

- (OFString*)_XMLStringWithParent: (OFXMLElement*)parent
		       namespaces: (OFDictionary*)allNamespaces
		      indentation: (unsigned int)indentation
			    level: (unsigned int)level
{
	OFAutoreleasePool *pool, *pool2;
	char *cString;
	size_t length, i, j, attributesCount;
	OFString *prefix, *parentPrefix;
	OFXMLAttribute **attributesObjects;
	OFString *ret;
	OFString *defaultNS;

	pool = [[OFAutoreleasePool alloc] init];

	parentPrefix = [allNamespaces objectForKey:
	    (parent != nil && parent->ns != nil ? parent->ns : (OFString*)@"")];

	/* Add the namespaces of the current element */
	if (allNamespaces != nil) {
		OFEnumerator *keyEnumerator = [namespaces keyEnumerator];
		OFEnumerator *objectEnumerator = [namespaces objectEnumerator];
		OFMutableDictionary *tmp;
		id key, object;

		tmp = [[allNamespaces mutableCopy] autorelease];

		while ((key = [keyEnumerator nextObject]) != nil &&
		    (object = [objectEnumerator nextObject]) != nil)
			[tmp setObject: object
				forKey: key];

		allNamespaces = tmp;
	} else
		allNamespaces = namespaces;

	prefix = [allNamespaces objectForKey:
	    (ns != nil ? ns : (OFString*)@"")];

	if (parent != nil && parent->ns != nil && parentPrefix == nil)
		defaultNS = parent->ns;
	else if (parent != nil && parent->defaultNamespace != nil)
		defaultNS = parent->defaultNamespace;
	else
		defaultNS = defaultNamespace;

	i = 0;
	length = [name UTF8StringLength] + 3 + (level * indentation);
	cString = [self allocMemoryWithSize: length];

	memset(cString + i, ' ', level * indentation);
	i += level * indentation;

	/* Start of tag */
	cString[i++] = '<';

	if (prefix != nil && ![ns isEqual: defaultNS]) {
		length += [prefix UTF8StringLength] + 1;
		@try {
			cString = [self resizeMemory: cString
						size: length];
		} @catch (id e) {
			[self freeMemory: cString];
			@throw e;
		}

		memcpy(cString + i, [prefix UTF8String],
		    [prefix UTF8StringLength]);
		i += [prefix UTF8StringLength];
		cString[i++] = ':';
	}

	memcpy(cString + i, [name UTF8String], [name UTF8StringLength]);
	i += [name UTF8StringLength];

	/* xmlns if necessary */
	if (prefix == nil && ((ns != nil && ![ns isEqual: defaultNS]) ||
	    (ns == nil && defaultNS != nil))) {
		length += [ns UTF8StringLength] + 9;
		@try {
			cString = [self resizeMemory: cString
						size: length];
		} @catch (id e) {
			[self freeMemory: cString];
			@throw e;
		}

		memcpy(cString + i, " xmlns='", 8);
		i += 8;
		memcpy(cString + i, [ns UTF8String], [ns UTF8StringLength]);
		i += [ns UTF8StringLength];
		cString[i++] = '\'';
	}

	/* Attributes */
	attributesObjects = [attributes objects];
	attributesCount = [attributes count];

	pool2 = [[OFAutoreleasePool alloc] init];
	for (j = 0; j < attributesCount; j++) {
		OFString *attributeName = [attributesObjects[j] name];
		OFString *attributePrefix = nil;
		OFString *tmp =
		    [[attributesObjects[j] stringValue] stringByXMLEscaping];

		if ([attributesObjects[j] namespace] != nil &&
		    (attributePrefix = [allNamespaces objectForKey:
		    [attributesObjects[j] namespace]]) == nil)
			@throw [OFUnboundNamespaceException
			    exceptionWithClass: isa
				     namespace: [attributesObjects[j]
						    namespace]];

		length += [attributeName UTF8StringLength] +
		    (attributePrefix != nil ?
		    [attributePrefix UTF8StringLength] + 1 : 0) +
		    [tmp UTF8StringLength] + 4;

		@try {
			cString = [self resizeMemory: cString
						size: length];
		} @catch (id e) {
			[self freeMemory: cString];
			@throw e;
		}

		cString[i++] = ' ';
		if (attributePrefix != nil) {
			memcpy(cString + i, [attributePrefix UTF8String],
			    [attributePrefix UTF8StringLength]);
			i += [attributePrefix UTF8StringLength];
			cString[i++] = ':';
		}
		memcpy(cString + i, [attributeName UTF8String],
		    [attributeName UTF8StringLength]);
		i += [attributeName UTF8StringLength];
		cString[i++] = '=';
		cString[i++] = '\'';
		memcpy(cString + i, [tmp UTF8String], [tmp UTF8StringLength]);
		i += [tmp UTF8StringLength];
		cString[i++] = '\'';

		[pool2 releaseObjects];
	}

	/* Childen */
	if (children != nil) {
		OFXMLElement **childrenObjects = [children objects];
		size_t childrenCount = [children count];
		OFDataArray *tmp = [OFDataArray dataArray];
		BOOL indent;

		if (indentation > 0) {
			indent = YES;

			for (j = 0; j < childrenCount; j++) {
				if ([childrenObjects[j] isKindOfClass:
				    charactersClass] || [childrenObjects[j]
				    isKindOfClass: CDATAClass]) {
					indent = NO;
					break;
				}
			}
		} else
			indent = NO;

		for (j = 0; j < childrenCount; j++) {
			OFString *child;
			unsigned int ind = (indent ? indentation : 0);

			if (ind)
				[tmp addItem: "\n"];

			if ([childrenObjects[j] isKindOfClass:
			    [OFXMLElement class]])
				child = [childrenObjects[j]
				    _XMLStringWithParent: self
					      namespaces: allNamespaces
					     indentation: ind
						   level: level + 1];
			else
				child = [childrenObjects[j]
				    XMLStringWithIndentation: ind
						       level: level + 1];

			[tmp addItemsFromCArray: [child UTF8String]
					  count: [child UTF8StringLength]];
		}

		if (indent)
			[tmp addItem: "\n"];

		length += [tmp count] + [name UTF8StringLength] + 2 +
		    (indent ? level * indentation : 0);
		@try {
			cString = [self resizeMemory: cString
						size: length];
		} @catch (id e) {
			[self freeMemory: cString];
			@throw e;
		}

		cString[i++] = '>';

		memcpy(cString + i, [tmp cArray], [tmp count]);
		i += [tmp count];

		if (indent) {
			memset(cString + i, ' ', level * indentation);
			i += level * indentation;
		}

		cString[i++] = '<';
		cString[i++] = '/';
		if (prefix != nil) {
			length += [prefix UTF8StringLength] + 1;
			@try {
				cString = [self resizeMemory: cString
							size: length];
			} @catch (id e) {
				[self freeMemory: cString];
				@throw e;
			}

			memcpy(cString + i, [prefix UTF8String],
			    [prefix UTF8StringLength]);
			i += [prefix UTF8StringLength];
			cString[i++] = ':';
		}
		memcpy(cString + i, [name UTF8String], [name UTF8StringLength]);
		i += [name UTF8StringLength];
	} else
		cString[i++] = '/';

	cString[i++] = '>';
	assert(i == length);

	[pool release];

	@try {
		ret = [OFString stringWithUTF8String: cString
					      length: length];
	} @finally {
		[self freeMemory: cString];
	}
	return ret;
}

- (OFString*)XMLString
{
	return [self _XMLStringWithParent: nil
			       namespaces: nil
			      indentation: 0
				    level: 0];
}

- (OFString*)XMLStringWithIndentation: (unsigned int)indentation
{
	return [self _XMLStringWithParent: nil
			       namespaces: nil
			      indentation: indentation
				    level: 0];
}

- (OFString*)XMLStringWithIndentation: (unsigned int)indentation
				level: (unsigned int)level
{
	return [self _XMLStringWithParent: nil
			       namespaces: nil
			      indentation: indentation
				    level: level];
}

- (OFXMLElement*)XMLElementBySerializing
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: [self className]
				      namespace: OF_SERIALIZATION_NS];

	if (name != nil)
		[element addAttributeWithName: @"name"
				  stringValue: name];

	if (ns != nil)
		[element addAttributeWithName: @"namespace"
				  stringValue: ns];

	if (defaultNamespace != nil)
		[element addAttributeWithName: @"defaultNamespace"
				  stringValue: defaultNamespace];

	if (attributes != nil) {
		OFXMLElement *attributesElement;

		attributesElement =
		    [OFXMLElement elementWithName: @"attributes"
					namespace: OF_SERIALIZATION_NS];
		[attributesElement addChild:
		    [attributes XMLElementBySerializing]];
		[element addChild: attributesElement];
	}

	if (namespaces != nil) {
		OFXMLElement *namespacesElement;
		OFMutableDictionary *namespacesCopy =
		    [[namespaces mutableCopy] autorelease];

		[namespacesCopy removeObjectForKey:
		    @"http://www.w3.org/XML/1998/namespace"];
		[namespacesCopy removeObjectForKey:
		    @"http://www.w3.org/2000/xmlns/"];

		if ([namespacesCopy count] > 0) {
			namespacesElement =
			    [OFXMLElement elementWithName: @"namespaces"
						namespace: OF_SERIALIZATION_NS];
			[namespacesElement addChild:
			    [namespacesCopy XMLElementBySerializing]];
			[element addChild: namespacesElement];
		}
	}

	if (children != nil) {
		OFXMLElement *childrenElement;

		childrenElement =
		    [OFXMLElement elementWithName: @"children"
					namespace: OF_SERIALIZATION_NS];
		[childrenElement addChild: [children XMLElementBySerializing]];
		[element addChild: childrenElement];
	}

	[element retain];
	[pool release];
	[element autorelease];

	return element;
}

- (void)addAttribute: (OFXMLAttribute*)attribute
{
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
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

	[self addAttribute: [OFXMLAttribute attributeWithName: name_
						    namespace: ns_
						  stringValue: stringValue]];

	[pool release];
}

- (OFXMLAttribute*)attributeForName: (OFString*)attributeName
{
	OFXMLAttribute **objects = [attributes objects];
	size_t i, count = [attributes count];

	for (i = 0; i < count; i++)
		if (objects[i]->ns == nil &&
		    [objects[i]->name isEqual: attributeName])
			return objects[i];

	return nil;
}

- (OFXMLAttribute*)attributeForName: (OFString*)attributeName
			  namespace: (OFString*)attributeNS
{
	OFXMLAttribute **objects;
	size_t i, count;

	if (attributeNS == nil)
		return [self attributeForName: attributeName];

	objects = [attributes objects];
	count = [attributes count];

	for (i = 0; i < count; i++)
		if ([objects[i]->ns isEqual: attributeNS] &&
		    [objects[i]->name isEqual: attributeName])
			return objects[i];

	return nil;
}

- (void)removeAttributeForName: (OFString*)attributeName
{
	OFXMLAttribute **objects = [attributes objects];
	size_t i, count = [attributes count];

	for (i = 0; i < count; i++) {
		if (objects[i]->ns == nil &&
		    [objects[i]->name isEqual: attributeName]) {
			[attributes removeObjectAtIndex: i];

			return;
		}
	}
}

- (void)removeAttributeForName: (OFString*)attributeName
		     namespace: (OFString*)attributeNS
{
	OFXMLAttribute **objects;
	size_t i, count;

	if (attributeNS == nil)
		return [self removeAttributeForName: attributeName];

	objects = [attributes objects];
	count = [attributes count];

	for (i = 0; i < count; i++) {
		if ([objects[i]->ns isEqual: attributeNS] &&
		    [objects[i]->name isEqual: attributeName]) {
			[attributes removeObjectAtIndex: i];
				return;
		}
	}
}

- (void)setPrefix: (OFString*)prefix
     forNamespace: (OFString*)ns_
{
	if (prefix == nil || [prefix isEqual: @""])
		@throw [OFInvalidArgumentException exceptionWithClass: isa
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
	OF_GETTER(defaultNamespace, YES)
}

- (void)setDefaultNamespace: (OFString*)ns_
{
	OF_SETTER(defaultNamespace, ns_, YES, 1)
}

- (void)addChild: (OFXMLNode*)child
{
	if ([child isKindOfClass: [OFXMLAttribute class]])
		@throw [OFInvalidArgumentException exceptionWithClass: isa
							     selector: _cmd];

	if (children == nil)
		children = [[OFMutableArray alloc] init];

	[children addObject: child];
}

- (void)removeChild: (OFXMLNode*)child
{
	if ([child isKindOfClass: [OFXMLAttribute class]])
		@throw [OFInvalidArgumentException exceptionWithClass: isa
							     selector: _cmd];

	[children removeObject: child];
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

- (OFArray*)elements
{
	OFMutableArray *ret = [OFMutableArray array];
	OFXMLElement **objects = [children objects];
	size_t i, count = [children count];

	for (i = 0; i < count; i++)
		if ([objects[i] isKindOfClass: [OFXMLElement class]])
			[ret addObject: objects[i]];

	[ret makeImmutable];

	return ret;
}

- (OFArray*)elementsForName: (OFString*)elementName
{
	OFMutableArray *ret = [OFMutableArray array];
	OFXMLElement **objects = [children objects];
	size_t i, count = [children count];

	for (i = 0; i < count; i++)
		if ([objects[i] isKindOfClass: [OFXMLElement class]] &&
		    objects[i]->ns == nil &&
		    [objects[i]->name isEqual: elementName])
			[ret addObject: objects[i]];

	[ret makeImmutable];

	return ret;
}

- (OFArray*)elementsForNamespace: (OFString*)elementNS
{
	OFMutableArray *ret = [OFMutableArray array];
	OFXMLElement **objects = [children objects];
	size_t i, count = [children count];

	for (i = 0; i < count; i++)
		if ([objects[i] isKindOfClass: [OFXMLElement class]] &&
		    objects[i]->name != nil &&
		    [objects[i]->ns isEqual: elementNS])
			[ret addObject: objects[i]];

	[ret makeImmutable];

	return ret;
}

- (OFArray*)elementsForName: (OFString*)elementName
		  namespace: (OFString*)elementNS
{
	OFMutableArray *ret;
	OFXMLElement **objects;
	size_t i, count;

	if (elementNS == nil)
		return [self elementsForName: elementName];

	ret = [OFMutableArray array];
	objects = [children objects];
	count = [children count];

	for (i = 0; i < count; i++)
		if ([objects[i] isKindOfClass: [OFXMLElement class]] &&
		    [objects[i]->ns isEqual: elementNS] &&
		    [objects[i]->name isEqual: elementName])
			[ret addObject: objects[i]];

	[ret makeImmutable];

	return ret;
}

- (BOOL)isEqual: (id)object
{
	OFXMLElement *otherElement;

	if (![object isKindOfClass: [OFXMLElement class]])
		return NO;

	otherElement = object;

	if (otherElement->name != name && ![otherElement->name isEqual: name])
		return NO;
	if (otherElement->ns != ns && ![otherElement->ns isEqual: ns])
		return NO;
	if (otherElement->defaultNamespace != defaultNamespace &&
	    ![otherElement->defaultNamespace isEqual: defaultNamespace])
		return NO;
	if (otherElement->attributes != attributes &&
	    ![otherElement->attributes isEqual: attributes])
		return NO;
	if (otherElement->namespaces != namespaces &&
	    ![otherElement->namespaces isEqual: namespaces])
		return NO;
	if (otherElement->children != children &&
	    ![otherElement->children isEqual: children])
		return NO;

	return YES;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, [name hash]);
	OF_HASH_ADD_HASH(hash, [ns hash]);
	OF_HASH_ADD_HASH(hash, [defaultNamespace hash]);
	OF_HASH_ADD_HASH(hash, [attributes hash]);
	OF_HASH_ADD_HASH(hash, [namespaces hash]);
	OF_HASH_ADD_HASH(hash, [children hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- copy
{
	return [[isa alloc] initWithElement: self];
}

- (void)dealloc
{
	[name release];
	[ns release];
	[defaultNamespace release];
	[attributes release];
	[namespaces release];
	[children release];

	[super dealloc];
}
@end
