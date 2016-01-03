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

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFMalformedXMLException.h"
#import "OFUnboundNamespaceException.h"

/* References for static linking */
void _references_to_categories_of_OFXMLElement(void)
{
	_OFXMLElement_Serialization_reference = 1;
}

static Class charactersClass = Nil;
static Class CDATAClass = Nil;

@interface OFXMLElement_OFXMLElementBuilderDelegate: OFObject
    <OFXMLElementBuilderDelegate>
{
@public
	OFXMLElement *_element;
}
@end

@implementation OFXMLElement_OFXMLElementBuilderDelegate
- (void)elementBuilder: (OFXMLElementBuilder*)builder
       didBuildElement: (OFXMLElement*)element
{
	if (_element == nil)
		_element = [element retain];
}

- (void)dealloc
{
	[_element release];

	[super dealloc];
}
@end

@implementation OFXMLElement
@synthesize name = _name, namespace = _namespace;
@synthesize defaultNamespace = _defaultNamespace;

+ (void)initialize
{
	if (self == [OFXMLElement class]) {
		charactersClass = [OFXMLCharacters class];
		CDATAClass = [OFXMLCDATA class];
	}
}

+ (instancetype)elementWithName: (OFString*)name
{
	return [[[self alloc] initWithName: name] autorelease];
}

+ (instancetype)elementWithName: (OFString*)name
		    stringValue: (OFString*)stringValue
{
	return [[[self alloc] initWithName: name
			       stringValue: stringValue] autorelease];
}

+ (instancetype)elementWithName: (OFString*)name
		      namespace: (OFString*)ns
{
	return [[[self alloc] initWithName: name
				 namespace: ns] autorelease];
}

+ (instancetype)elementWithName: (OFString*)name
		      namespace: (OFString*)ns
		    stringValue: (OFString*)stringValue
{
	return [[[self alloc] initWithName: name
				 namespace: ns
			       stringValue: stringValue] autorelease];
}

+ (instancetype)elementWithElement: (OFXMLElement*)element
{
	return [[[self alloc] initWithElement: element] autorelease];
}

+ (instancetype)elementWithXMLString: (OFString*)string
{
	return [[[self alloc] initWithXMLString: string] autorelease];
}

#ifdef OF_HAVE_FILES
+ (instancetype)elementWithFile: (OFString*)path
{
	return [[[self alloc] initWithFile: path] autorelease];
}
#endif

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithName: (OFString*)name
{
	return [self initWithName: name
			namespace: nil
		      stringValue: nil];
}

- initWithName: (OFString*)name
   stringValue: (OFString*)stringValue
{
	return [self initWithName: name
			namespace: nil
		      stringValue: stringValue];
}

- initWithName: (OFString*)name
     namespace: (OFString*)namespace
{
	return [self initWithName: name
			namespace: namespace
		      stringValue: nil];
}

- initWithName: (OFString*)name
     namespace: (OFString*)namespace
   stringValue: (OFString*)stringValue
{
	self = [super init];

	@try {
		if (name == nil)
			@throw [OFInvalidArgumentException exception];

		_name = [name copy];
		_namespace = [namespace copy];

		_namespaces = [[OFMutableDictionary alloc]
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
			@throw [OFInvalidArgumentException exception];

		_name = [element->_name copy];
		_namespace = [element->_namespace copy];
		_defaultNamespace = [element->_defaultNamespace copy];
		_attributes = [element->_attributes mutableCopy];
		_namespaces = [element->_namespaces mutableCopy];
		_children = [element->_children mutableCopy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithXMLString: (OFString*)string
{
	void *pool;
	OFXMLParser *parser;
	OFXMLElementBuilder *builder;
	OFXMLElement_OFXMLElementBuilderDelegate *delegate;

	[self release];

	if (string == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	parser = [OFXMLParser parser];
	builder = [OFXMLElementBuilder elementBuilder];
	delegate = [[[OFXMLElement_OFXMLElementBuilderDelegate alloc] init]
	    autorelease];

	[parser setDelegate: builder];
	[builder setDelegate: delegate];

	[parser parseString: string];

	if (![parser hasFinishedParsing])
		@throw [OFMalformedXMLException exceptionWithParser: parser];

	self = [delegate->_element retain];

	objc_autoreleasePoolPop(pool);

	return self;
}

#ifdef OF_HAVE_FILES
- initWithFile: (OFString*)path
{
	void *pool;
	OFXMLParser *parser;
	OFXMLElementBuilder *builder;
	OFXMLElement_OFXMLElementBuilderDelegate *delegate;

	[self release];

	pool = objc_autoreleasePoolPush();

	parser = [OFXMLParser parser];
	builder = [OFXMLElementBuilder elementBuilder];
	delegate = [[[OFXMLElement_OFXMLElementBuilderDelegate alloc] init]
	    autorelease];

	[parser setDelegate: builder];
	[builder setDelegate: delegate];

	[parser parseFile: path];

	if (![parser hasFinishedParsing])
		@throw [OFMalformedXMLException exceptionWithParser: parser];

	self = [delegate->_element retain];

	objc_autoreleasePoolPop(pool);

	return self;
}
#endif

- initWithSerialization: (OFXMLElement*)element
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFXMLElement *attributesElement, *namespacesElement;
		OFXMLElement *childrenElement;
		OFEnumerator *keyEnumerator, *objectEnumerator;
		id key, object;

		if (![[element name] isEqual: [self className]] ||
		    ![[element namespace] isEqual: OF_SERIALIZATION_NS])
			@throw [OFInvalidArgumentException exception];

		_name = [[[element attributeForName: @"name"]
		    stringValue] copy];
		_namespace = [[[element attributeForName: @"namespace"]
		    stringValue] copy];
		_defaultNamespace = [[[element attributeForName:
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

		_attributes = [[attributesElement objectByDeserializing]
		    mutableCopy];
		_namespaces = [[namespacesElement objectByDeserializing]
		    mutableCopy];
		_children = [[childrenElement objectByDeserializing]
		    mutableCopy];

		/* Sanity checks */
		if ((_attributes != nil && ![_attributes isKindOfClass:
		    [OFMutableArray class]]) || (_namespaces != nil &&
		    ![_namespaces isKindOfClass:
		    [OFMutableDictionary class]]) || (_children != nil &&
		    ![_children isKindOfClass: [OFMutableArray class]]))
			@throw [OFInvalidArgumentException exception];

		for (object in _attributes)
			if (![object isKindOfClass: [OFXMLAttribute class]])
				@throw [OFInvalidArgumentException exception];

		keyEnumerator = [_namespaces keyEnumerator];
		objectEnumerator = [_namespaces objectEnumerator];
		while ((key = [keyEnumerator nextObject]) != nil &&
		    (object = [objectEnumerator nextObject]) != nil)
			if (![key isKindOfClass: [OFString class]] ||
			    ![object isKindOfClass: [OFString class]])
				@throw [OFInvalidArgumentException exception];

		for (object in _children)
			if (![object isKindOfClass: [OFXMLNode class]])
				@throw [OFInvalidArgumentException exception];

		if (_namespaces == nil)
			_namespaces = [[OFMutableDictionary alloc] init];

		[_namespaces
		    setObject: @"xml"
		       forKey: @"http://www.w3.org/XML/1998/namespace"];
		[_namespaces setObject: @"xmlns"
				forKey: @"http://www.w3.org/2000/xmlns/"];

		if (_name == nil)
			@throw [OFInvalidArgumentException exception];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_name release];
	[_namespace release];
	[_defaultNamespace release];
	[_attributes release];
	[_namespaces release];
	[_children release];

	[super dealloc];
}

- (OFArray*)attributes
{
	return [[_attributes copy] autorelease];
}

- (void)setChildren: (OFArray*)children
{
	OFArray *old = _children;
	_children = [children copy];
	[old release];
}

- (OFArray*)children
{
	return [[_children copy] autorelease];
}

- (void)setStringValue: (OFString*)stringValue
{
	void *pool = objc_autoreleasePoolPush();

	[self setChildren: [OFArray arrayWithObject:
	    [OFXMLCharacters charactersWithString: stringValue]]];

	objc_autoreleasePoolPop(pool);
}

- (OFString*)stringValue
{
	OFMutableString *ret;

	if ([_children count] == 0)
		return @"";

	ret = [OFMutableString string];

	for (OFXMLNode *child in _children) {
		void *pool = objc_autoreleasePoolPush();

		[ret appendString: [child stringValue]];

		objc_autoreleasePoolPop(pool);
	}

	[ret makeImmutable];

	return ret;
}

- (OFString*)OF_XMLStringWithParent: (OFXMLElement*)parent
			 namespaces: (OFDictionary*)allNamespaces
			indentation: (unsigned int)indentation
			      level: (unsigned int)level
{
	void *pool;
	char *cString;
	size_t length, i, j, attributesCount;
	OFString *prefix, *parentPrefix;
	OFXMLAttribute *const *attributesObjects;
	OFString *ret;
	OFString *defaultNS;

	pool = objc_autoreleasePoolPush();

	parentPrefix = [allNamespaces objectForKey:
	    (parent != nil && parent->_namespace != nil
	    ? parent->_namespace : (OFString*)@"")];

	/* Add the namespaces of the current element */
	if (allNamespaces != nil) {
		OFEnumerator *keyEnumerator = [_namespaces keyEnumerator];
		OFEnumerator *objectEnumerator = [_namespaces objectEnumerator];
		OFMutableDictionary *tmp;
		id key, object;

		tmp = [[allNamespaces mutableCopy] autorelease];

		while ((key = [keyEnumerator nextObject]) != nil &&
		    (object = [objectEnumerator nextObject]) != nil)
			[tmp setObject: object
				forKey: key];

		allNamespaces = tmp;
	} else
		allNamespaces = _namespaces;

	prefix = [allNamespaces objectForKey:
	    (_namespace != nil ? _namespace : (OFString*)@"")];

	if (parent != nil && parent->_namespace != nil && parentPrefix == nil)
		defaultNS = parent->_namespace;
	else if (parent != nil && parent->_defaultNamespace != nil)
		defaultNS = parent->_defaultNamespace;
	else
		defaultNS = _defaultNamespace;

	i = 0;
	length = [_name UTF8StringLength] + 3 + (level * indentation);
	cString = [self allocMemoryWithSize: length];

	memset(cString + i, ' ', level * indentation);
	i += level * indentation;

	/* Start of tag */
	cString[i++] = '<';

	if (prefix != nil && ![_namespace isEqual: defaultNS]) {
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

	memcpy(cString + i, [_name UTF8String], [_name UTF8StringLength]);
	i += [_name UTF8StringLength];

	/* xmlns if necessary */
	if (prefix == nil && ((_namespace != nil &&
	    ![_namespace isEqual: defaultNS]) ||
	    (_namespace == nil && defaultNS != nil))) {
		length += [_namespace UTF8StringLength] + 9;
		@try {
			cString = [self resizeMemory: cString
						size: length];
		} @catch (id e) {
			[self freeMemory: cString];
			@throw e;
		}

		memcpy(cString + i, " xmlns='", 8);
		i += 8;
		memcpy(cString + i, [_namespace UTF8String],
		    [_namespace UTF8StringLength]);
		i += [_namespace UTF8StringLength];
		cString[i++] = '\'';
	}

	/* Attributes */
	attributesObjects = [_attributes objects];
	attributesCount = [_attributes count];

	for (j = 0; j < attributesCount; j++) {
		void *pool2 = objc_autoreleasePoolPush();
		OFString *attributeName = [attributesObjects[j] name];
		OFString *attributePrefix = nil;
		OFString *tmp =
		    [[attributesObjects[j] stringValue] stringByXMLEscaping];

		if ([attributesObjects[j] namespace] != nil &&
		    (attributePrefix = [allNamespaces objectForKey:
		    [attributesObjects[j] namespace]]) == nil)
			@throw [OFUnboundNamespaceException
			    exceptionWithNamespace: [attributesObjects[j]
							namespace]
					   element: self];

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

		objc_autoreleasePoolPop(pool2);
	}

	/* Childen */
	if (_children != nil) {
		OFXMLNode *const *childrenObjects = [_children objects];
		size_t childrenCount = [_children count];
		OFDataArray *tmp = [OFDataArray dataArray];
		bool indent;

		if (indentation > 0) {
			indent = true;

			for (j = 0; j < childrenCount; j++) {
				if ([childrenObjects[j] isKindOfClass:
				    charactersClass] || [childrenObjects[j]
				    isKindOfClass: CDATAClass]) {
					indent = false;
					break;
				}
			}
		} else
			indent = false;

		for (j = 0; j < childrenCount; j++) {
			OFString *child;
			unsigned int ind = (indent ? indentation : 0);

			if (ind)
				[tmp addItem: "\n"];

			if ([childrenObjects[j] isKindOfClass:
			    [OFXMLElement class]])
				child = [(OFXMLElement*)childrenObjects[j]
				    OF_XMLStringWithParent: self
						namespaces: allNamespaces
					       indentation: ind
						     level: level + 1];
			else
				child = [childrenObjects[j]
				    XMLStringWithIndentation: ind
						       level: level + 1];

			[tmp addItems: [child UTF8String]
				count: [child UTF8StringLength]];
		}

		if (indent)
			[tmp addItem: "\n"];

		length += [tmp count] + [_name UTF8StringLength] + 2 +
		    (indent ? level * indentation : 0);
		@try {
			cString = [self resizeMemory: cString
						size: length];
		} @catch (id e) {
			[self freeMemory: cString];
			@throw e;
		}

		cString[i++] = '>';

		memcpy(cString + i, [tmp items], [tmp count]);
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
		memcpy(cString + i, [_name UTF8String],
		    [_name UTF8StringLength]);
		i += [_name UTF8StringLength];
	} else
		cString[i++] = '/';

	cString[i++] = '>';
	assert(i == length);

	objc_autoreleasePoolPop(pool);

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
	return [self OF_XMLStringWithParent: nil
				 namespaces: nil
				indentation: 0
				      level: 0];
}

- (OFString*)XMLStringWithIndentation: (unsigned int)indentation
{
	return [self OF_XMLStringWithParent: nil
				 namespaces: nil
				indentation: indentation
				      level: 0];
}

- (OFString*)XMLStringWithIndentation: (unsigned int)indentation
				level: (unsigned int)level
{
	return [self OF_XMLStringWithParent: nil
				 namespaces: nil
				indentation: indentation
				      level: level];
}

- (OFXMLElement*)XMLElementBySerializing
{
	void *pool = objc_autoreleasePoolPush();
	OFXMLElement *element;

	element = [OFXMLElement elementWithName: [self className]
				      namespace: OF_SERIALIZATION_NS];

	if (_name != nil)
		[element addAttributeWithName: @"name"
				  stringValue: _name];

	if (_namespace != nil)
		[element addAttributeWithName: @"namespace"
				  stringValue: _namespace];

	if (_defaultNamespace != nil)
		[element addAttributeWithName: @"defaultNamespace"
				  stringValue: _defaultNamespace];

	if (_attributes != nil) {
		OFXMLElement *attributesElement;

		attributesElement =
		    [OFXMLElement elementWithName: @"attributes"
					namespace: OF_SERIALIZATION_NS];
		[attributesElement addChild:
		    [_attributes XMLElementBySerializing]];
		[element addChild: attributesElement];
	}

	if (_namespaces != nil) {
		OFXMLElement *namespacesElement;
		OFMutableDictionary *namespacesCopy =
		    [[_namespaces mutableCopy] autorelease];

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

	if (_children != nil) {
		OFXMLElement *childrenElement;

		childrenElement =
		    [OFXMLElement elementWithName: @"children"
					namespace: OF_SERIALIZATION_NS];
		[childrenElement addChild: [_children XMLElementBySerializing]];
		[element addChild: childrenElement];
	}

	[element retain];

	objc_autoreleasePoolPop(pool);

	return [element autorelease];
}

- (void)addAttribute: (OFXMLAttribute*)attribute
{
	if (_attributes == nil)
		_attributes = [[OFMutableArray alloc] init];

	if ([self attributeForName: attribute->_name
			 namespace: attribute->_namespace] == nil)
		[_attributes addObject: attribute];
}

- (void)addAttributeWithName: (OFString*)name
		 stringValue: (OFString*)stringValue
{
	[self addAttributeWithName: name
			 namespace: nil
		       stringValue: stringValue];
}

- (void)addAttributeWithName: (OFString*)name
		   namespace: (OFString*)namespace
		 stringValue: (OFString*)stringValue
{
	void *pool = objc_autoreleasePoolPush();

	[self addAttribute: [OFXMLAttribute attributeWithName: name
						    namespace: namespace
						  stringValue: stringValue]];

	objc_autoreleasePoolPop(pool);
}

- (OFXMLAttribute*)attributeForName: (OFString*)attributeName
{
	for (OFXMLAttribute *attribute in _attributes)
		if (attribute->_namespace == nil &&
		    [attribute->_name isEqual: attributeName])
			return [[attribute retain] autorelease];

	return nil;
}

- (OFXMLAttribute*)attributeForName: (OFString*)attributeName
			  namespace: (OFString*)attributeNS
{
	if (attributeNS == nil)
		return [self attributeForName: attributeName];

	for (OFXMLAttribute *attribute in _attributes)
		if ([attribute->_namespace isEqual: attributeNS] &&
		    [attribute->_name isEqual: attributeName])
			return [[attribute retain] autorelease];

	return nil;
}

- (void)removeAttributeForName: (OFString*)attributeName
{
	OFXMLAttribute *const *objects = [_attributes objects];
	size_t i, count = [_attributes count];

	for (i = 0; i < count; i++) {
		if (objects[i]->_namespace == nil &&
		    [objects[i]->_name isEqual: attributeName]) {
			[_attributes removeObjectAtIndex: i];

			return;
		}
	}
}

- (void)removeAttributeForName: (OFString*)attributeName
		     namespace: (OFString*)attributeNS
{
	OFXMLAttribute *const *objects;
	size_t i, count;

	if (attributeNS == nil) {
		[self removeAttributeForName: attributeName];
		return;
	}

	objects = [_attributes objects];
	count = [_attributes count];

	for (i = 0; i < count; i++) {
		if ([objects[i]->_namespace isEqual: attributeNS] &&
		    [objects[i]->_name isEqual: attributeName]) {
			[_attributes removeObjectAtIndex: i];
				return;
		}
	}
}

- (void)setPrefix: (OFString*)prefix
     forNamespace: (OFString*)namespace
{
	if ([prefix length] == 0)
		@throw [OFInvalidArgumentException exception];
	if (namespace == nil)
		namespace = @"";

	[_namespaces setObject: prefix
			forKey: namespace];
}

- (void)bindPrefix: (OFString*)prefix
      forNamespace: (OFString*)namespace
{
	[self setPrefix: prefix
	   forNamespace: namespace];
	[self addAttributeWithName: prefix
			 namespace: @"http://www.w3.org/2000/xmlns/"
		       stringValue: namespace];
}

- (void)addChild: (OFXMLNode*)child
{
	if ([child isKindOfClass: [OFXMLAttribute class]])
		@throw [OFInvalidArgumentException exception];

	if (_children == nil)
		_children = [[OFMutableArray alloc] init];

	[_children addObject: child];
}

- (void)insertChild: (OFXMLNode*)child
	    atIndex: (size_t)index
{
	if ([child isKindOfClass: [OFXMLAttribute class]])
		@throw [OFInvalidArgumentException exception];

	if (_children == nil)
		_children = [[OFMutableArray alloc] init];

	[_children insertObject: child
			atIndex: index];
}

- (void)insertChildren: (OFArray*)children
	       atIndex: (size_t)index
{
	for (OFXMLNode *node in children)
		if ([node isKindOfClass: [OFXMLAttribute class]])
			@throw [OFInvalidArgumentException exception];

	[_children insertObjectsFromArray: children
				  atIndex: index];
}

- (void)removeChild: (OFXMLNode*)child
{
	if ([child isKindOfClass: [OFXMLAttribute class]])
		@throw [OFInvalidArgumentException exception];

	[_children removeObject: child];
}

- (void)removeChildAtIndex: (size_t)index
{
	[_children removeObjectAtIndex: index];
}

- (void)replaceChild: (OFXMLNode*)child
	    withNode: (OFXMLNode*)node
{
	if ([node isKindOfClass: [OFXMLAttribute class]] ||
	    [child isKindOfClass: [OFXMLAttribute class]])
		@throw [OFInvalidArgumentException exception];

	[_children replaceObject: child
		      withObject: node];
}

- (void)replaceChildAtIndex: (size_t)index
		   withNode: (OFXMLNode*)node
{
	if ([node isKindOfClass: [OFXMLAttribute class]])
		@throw [OFInvalidArgumentException exception];

	[_children replaceObjectAtIndex: index
			     withObject: node];
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
	OFMutableArray OF_GENERIC(OFXMLElement*) *ret = [OFMutableArray array];

	for (OFXMLNode *child in _children)
		if ([child isKindOfClass: [OFXMLElement class]])
			[ret addObject: (OFXMLElement*)child];

	[ret makeImmutable];

	return ret;
}

- (OFArray*)elementsForName: (OFString*)elementName
{
	OFMutableArray OF_GENERIC(OFXMLElement*) *ret = [OFMutableArray array];

	for (OFXMLNode *child in _children) {
		if ([child isKindOfClass: [OFXMLElement class]]) {
			OFXMLElement *element = (OFXMLElement*)child;

			if (element->_namespace == nil &&
			    [element->_name isEqual: elementName])
				[ret addObject: element];
		}
	}

	[ret makeImmutable];

	return ret;
}

- (OFArray*)elementsForNamespace: (OFString*)elementNS
{
	OFMutableArray OF_GENERIC(OFXMLElement*) *ret = [OFMutableArray array];

	for (OFXMLNode *child in _children) {
		if ([child isKindOfClass: [OFXMLElement class]]) {
			OFXMLElement *element = (OFXMLElement*)child;

			if (element->_name != nil &&
			    [element->_namespace isEqual: elementNS])
				[ret addObject: element];
		}
	}

	[ret makeImmutable];

	return ret;
}

- (OFArray*)elementsForName: (OFString*)elementName
		  namespace: (OFString*)elementNS
{
	OFMutableArray OF_GENERIC(OFXMLElement*) *ret;

	if (elementNS == nil)
		return [self elementsForName: elementName];

	ret = [OFMutableArray array];

	for (OFXMLNode *child in _children) {
		if ([child isKindOfClass: [OFXMLElement class]]) {
			OFXMLElement *element = (OFXMLElement*)child;

			if ([element->_namespace isEqual: elementNS] &&
			    [element->_name isEqual: elementName])
				[ret addObject: element];
		}
	}

	[ret makeImmutable];

	return ret;
}

- (bool)isEqual: (id)object
{
	OFXMLElement *element;

	if (![object isKindOfClass: [OFXMLElement class]])
		return false;

	element = object;

	if (element->_name != _name && ![element->_name isEqual: _name])
		return false;
	if (element->_namespace != _namespace &&
	    ![element->_namespace isEqual: _namespace])
		return false;
	if (element->_defaultNamespace != _defaultNamespace &&
	    ![element->_defaultNamespace isEqual: _defaultNamespace])
		return false;
	if (element->_attributes != _attributes &&
	    ![element->_attributes isEqual: _attributes])
		return false;
	if (element->_namespaces != _namespaces &&
	    ![element->_namespaces isEqual: _namespaces])
		return false;
	if (element->_children != _children &&
	    ![element->_children isEqual: _children])
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD_HASH(hash, [_name hash]);
	OF_HASH_ADD_HASH(hash, [_namespace hash]);
	OF_HASH_ADD_HASH(hash, [_defaultNamespace hash]);
	OF_HASH_ADD_HASH(hash, [_attributes hash]);
	OF_HASH_ADD_HASH(hash, [_namespaces hash]);
	OF_HASH_ADD_HASH(hash, [_children hash]);

	OF_HASH_FINALIZE(hash);

	return hash;
}

- copy
{
	return [[[self class] alloc] initWithElement: self];
}
@end
