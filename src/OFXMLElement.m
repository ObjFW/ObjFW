/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#define OF_XML_ELEMENT_M

#include <stdlib.h>
#include <string.h>

#import "OFXMLElement.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDictionary.h"
#import "OFStream.h"
#import "OFString.h"
#import "OFXMLAttribute.h"
#import "OFXMLCDATA.h"
#import "OFXMLCharacters.h"
#import "OFXMLElementBuilder.h"
#import "OFXMLNode+Private.h"
#import "OFXMLParser.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFMalformedXMLException.h"
#import "OFUnboundNamespaceException.h"

@interface OFXMLElementElementBuilderDelegate: OFObject
    <OFXMLElementBuilderDelegate>
{
@public
	OFXMLElement *_element;
}
@end

@implementation OFXMLElementElementBuilderDelegate
- (void)elementBuilder: (OFXMLElementBuilder *)builder
       didBuildElement: (OFXMLElement *)element
{
	if (_element == nil)
		_element = objc_retain(element);
}

- (void)dealloc
{
	objc_release(_element);

	[super dealloc];
}
@end

@implementation OFXMLElement
@synthesize name = _name, namespace = _namespace;

+ (instancetype)elementWithName: (OFString *)name
{
	return objc_autoreleaseReturnValue([[self alloc] initWithName: name]);
}

+ (instancetype)elementWithName: (OFString *)name
		    stringValue: (OFString *)stringValue
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithName: name
			   stringValue: stringValue]);
}

+ (instancetype)elementWithName: (OFString *)name
		      namespace: (OFString *)namespace
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithName: name
			     namespace: namespace]);
}

+ (instancetype)elementWithName: (OFString *)name
		      namespace: (OFString *)namespace
		    stringValue: (OFString *)stringValue
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithName: name
			     namespace: namespace
			   stringValue: stringValue]);
}

+ (instancetype)elementWithElement: (OFXMLElement *)element
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithElement: element]);
}

+ (instancetype)elementWithXMLString: (OFString *)string
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithXMLString: string]);
}

+ (instancetype)elementWithStream: (OFStream *)stream
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithStream: stream]);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
{
	return [self initWithName: name namespace: nil stringValue: nil];
}

- (instancetype)initWithName: (OFString *)name
		 stringValue: (OFString *)stringValue
{
	return [self initWithName: name
			namespace: nil
		      stringValue: stringValue];
}

- (instancetype)initWithName: (OFString *)name
		   namespace: (OFString *)namespace
{
	self = [super of_init];

	@try {
		if (name == nil)
			@throw [OFInvalidArgumentException exception];

		_name = [name copy];
		_namespace = [namespace copy];

		_namespaces = [[OFMutableDictionary alloc]
		    initWithKeysAndObjects:
		    @"http://www.w3.org/XML/1998/namespace", @"xml",
		    @"http://www.w3.org/2000/xmlns/", @"xmlns", nil];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithName: (OFString *)name
		   namespace: (OFString *)namespace
		 stringValue: (OFString *)stringValue
{
	self = [self initWithName: name namespace: namespace];

	@try {
		if (stringValue != nil)
			self.stringValue = stringValue;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithElement: (OFXMLElement *)element
{
	self = [self initWithName: element->_name
			namespace: element->_namespace];

	@try {
		_attributes = [element->_attributes mutableCopy];
		_namespaces = [element->_namespaces mutableCopy];
		_children = [element->_children mutableCopy];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithXMLString: (OFString *)string
{
	void *pool;
	OFXMLElement *element;

	@try {
		OFXMLParser *parser;
		OFXMLElementBuilder *builder;
		OFXMLElementElementBuilderDelegate *delegate;

		if (string == nil)
			@throw [OFInvalidArgumentException exception];

		pool = objc_autoreleasePoolPush();

		parser = [OFXMLParser parser];
		builder = [OFXMLElementBuilder builder];
		delegate = objc_autorelease(
		    [[OFXMLElementElementBuilderDelegate alloc] init]);

		parser.delegate = builder;
		builder.delegate = delegate;

		[parser parseString: string];

		if (!parser.hasFinishedParsing)
			@throw [OFMalformedXMLException
			    exceptionWithParser: parser];

		element = delegate->_element;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithName: element->_name
			namespace: element->_namespace];

	@try {
		objc_release(_attributes);
		_attributes = objc_retain(element->_attributes);
		objc_release(_namespaces);
		_namespaces = objc_retain(element->_namespaces);
		objc_release(_children);
		_children = objc_retain(element->_children);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)initWithStream: (OFStream *)stream
{
	void *pool;
	OFXMLElement *element;

	@try {
		OFXMLParser *parser;
		OFXMLElementBuilder *builder;
		OFXMLElementElementBuilderDelegate *delegate;

		pool = objc_autoreleasePoolPush();

		parser = [OFXMLParser parser];
		builder = [OFXMLElementBuilder builder];
		delegate = objc_autorelease(
		    [[OFXMLElementElementBuilderDelegate alloc] init]);

		parser.delegate = builder;
		builder.delegate = delegate;

		[parser parseStream: stream];

		if (!parser.hasFinishedParsing)
			@throw [OFMalformedXMLException
			    exceptionWithParser: parser];

		element = delegate->_element;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithName: element->_name
			namespace: element->_namespace];

	@try {
		objc_release(_attributes);
		_attributes = objc_retain(element->_attributes);
		objc_release(_namespaces);
		_namespaces = objc_retain(element->_namespaces);
		objc_release(_children);
		_children = objc_retain(element->_children);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_name);
	objc_release(_namespace);
	objc_release(_attributes);
	objc_release(_namespaces);
	objc_release(_children);

	[super dealloc];
}

- (OFArray *)attributes
{
	return objc_autoreleaseReturnValue([_attributes copy]);
}

- (void)setChildren: (OFArray *)children
{
	OFArray *old = _children;
	_children = [children mutableCopy];
	objc_release(old);
}

- (OFArray *)children
{
	return objc_autoreleaseReturnValue([_children copy]);
}

- (void)setStringValue: (OFString *)stringValue
{
	void *pool = objc_autoreleasePoolPush();

	self.children = [OFArray arrayWithObject:
	    [OFXMLCharacters charactersWithString: stringValue]];

	objc_autoreleasePoolPop(pool);
}

- (OFString *)stringValue
{
	OFMutableString *ret;

	if (_children.count == 0)
		return @"";

	ret = [OFMutableString string];

	for (OFXMLNode *child in _children) {
		void *pool = objc_autoreleasePoolPush();

		[ret appendString: child.stringValue];

		objc_autoreleasePoolPop(pool);
	}

	[ret makeImmutable];

	return ret;
}

- (OFString *)of_XMLStringWithDefaultNS: (OFString *)defaultNS
			     namespaces: (OFDictionary *)allNS
			    indentation: (unsigned int)indentation
				  level: (unsigned int)level OF_DIRECT
{
	void *pool;
	char *cString;
	size_t length, i;
	OFString *prefix, *ret;

	pool = objc_autoreleasePoolPush();

	/* Add the namespaces of the current element */
	if (allNS != nil) {
		OFEnumerator *keyEnumerator = [_namespaces keyEnumerator];
		OFEnumerator *objectEnumerator = [_namespaces objectEnumerator];
		OFMutableDictionary *tmp;
		OFString *key, *object;

		tmp = objc_autorelease([allNS mutableCopy]);

		while ((key = [keyEnumerator nextObject]) != nil &&
		    (object = [objectEnumerator nextObject]) != nil)
			[tmp setObject: object forKey: key];

		allNS = tmp;
	} else
		allNS = _namespaces;

	prefix = [allNS objectForKey:
	    (_namespace != nil ? _namespace : (OFString *)@"")];

	i = 0;
	length = _name.UTF8StringLength + 3 + (level * indentation);
	cString = OFAllocMemory(length, 1);

	@try {
		memset(cString + i, ' ', level * indentation);
		i += level * indentation;

		/* Start of tag */
		cString[i++] = '<';

		if (prefix.length > 0) {
			length += prefix.UTF8StringLength + 1;
			cString = OFResizeMemory(cString, length, 1);

			memcpy(cString + i, prefix.UTF8String,
			    prefix.UTF8StringLength);
			i += prefix.UTF8StringLength;
			cString[i++] = ':';
		}

		memcpy(cString + i, _name.UTF8String, _name.UTF8StringLength);
		i += _name.UTF8StringLength;

		/* xmlns if necessary */
		if (prefix.length == 0 && defaultNS != _namespace &&
		    ![defaultNS isEqual: _namespace]) {
			length += _namespace.UTF8StringLength + 9;
			cString = OFResizeMemory(cString, length, 1);

			memcpy(cString + i, " xmlns='", 8);
			i += 8;
			memcpy(cString + i, _namespace.UTF8String,
			    _namespace.UTF8StringLength);
			i += _namespace.UTF8StringLength;
			cString[i++] = '\'';

			defaultNS = _namespace;
		}

		/* Attributes */
		for (OFXMLAttribute *attribute in _attributes) {
			void *pool2 = objc_autoreleasePoolPush();
			const char *attributeNameCString =
			    attribute->_name.UTF8String;
			size_t attributeNameLength =
			    attribute->_name.UTF8StringLength;
			OFString *attributePrefix = nil;
			OFString *tmp =
			    attribute.stringValue.stringByXMLEscaping;
			char delimiter = (attribute->_useDoubleQuotes
			    ? '"' : '\'');

			if (attribute->_namespace != nil &&
			    [(attributePrefix = [allNS objectForKey:
			    attribute->_namespace]) length] == 0)
				@throw [OFUnboundNamespaceException
				    exceptionWithNamespace: attribute.namespace
						   element: self];

			length += attributeNameLength + (attributePrefix != nil
			    ? attributePrefix.UTF8StringLength + 1 : 0) +
			    tmp.UTF8StringLength + 4;
			cString = OFResizeMemory(cString, length, 1);

			cString[i++] = ' ';
			if (attributePrefix != nil) {
				memcpy(cString + i, attributePrefix.UTF8String,
				    attributePrefix.UTF8StringLength);
				i += attributePrefix.UTF8StringLength;
				cString[i++] = ':';
			}
			memcpy(cString + i, attributeNameCString,
			    attributeNameLength);
			i += attributeNameLength;
			cString[i++] = '=';
			cString[i++] = delimiter;
			memcpy(cString + i, tmp.UTF8String,
			    tmp.UTF8StringLength);
			i += tmp.UTF8StringLength;
			cString[i++] = delimiter;

			objc_autoreleasePoolPop(pool2);
		}

		/* Children */
		if (_children != nil) {
			OFMutableData *tmp = [OFMutableData data];
			bool indent;

			if (indentation > 0) {
				indent = true;

				for (OFXMLNode *child in _children) {
					if ([child isKindOfClass:
					    [OFXMLCharacters class]] ||
					    [child isKindOfClass:
					    [OFXMLCDATA class]]) {
						indent = false;
						break;
					}
				}
			} else
				indent = false;

			for (OFXMLNode *child in _children) {
				OFString *childString;
				unsigned int ind = (indent ? indentation : 0);

				if (ind)
					[tmp addItem: "\n"];

				if ([child isKindOfClass: [OFXMLElement class]])
					childString = [(OFXMLElement *)child
					    of_XMLStringWithDefaultNS: defaultNS
							   namespaces: allNS
							  indentation: ind
								level: level +
									   1];
				else {
					childString = child.XMLString;
					for (unsigned int j = 0;
					    j < ind * (level + 1); j++)
						[tmp addItem: " "];
				}

				[tmp addItems: childString.UTF8String
					count: childString.UTF8StringLength];
			}

			if (indent)
				[tmp addItem: "\n"];

			length += tmp.count + _name.UTF8StringLength + 2 +
			    (indent ? level * indentation : 0);
			cString = OFResizeMemory(cString, length, 1);

			cString[i++] = '>';

			memcpy(cString + i, tmp.items, tmp.count);
			i += tmp.count;

			if (indent) {
				memset(cString + i, ' ', level * indentation);
				i += level * indentation;
			}

			cString[i++] = '<';
			cString[i++] = '/';
			if (prefix.length > 0) {
				length += prefix.UTF8StringLength + 1;
				cString = OFResizeMemory(cString, length, 1);

				memcpy(cString + i, prefix.UTF8String,
				    prefix.UTF8StringLength);
				i += prefix.UTF8StringLength;
				cString[i++] = ':';
			}
			memcpy(cString + i, _name.UTF8String,
			    _name.UTF8StringLength);
			i += _name.UTF8StringLength;
		} else
			cString[i++] = '/';

		cString[i++] = '>';
		OFAssert(i == length);

		objc_autoreleasePoolPop(pool);

		ret = [OFString stringWithUTF8String: cString
					      length: length];
	} @finally {
		OFFreeMemory(cString);
	}
	return ret;
}

- (OFString *)XMLString
{
	return [self of_XMLStringWithDefaultNS: nil
				    namespaces: nil
				   indentation: 0
					 level: 0];
}

- (OFString *)XMLStringWithIndentation: (unsigned int)indentation
{
	return [self of_XMLStringWithDefaultNS: nil
				    namespaces: nil
				   indentation: indentation
					 level: 0];
}

- (OFString *)XMLStringWithDefaultNamespace: (OFString *)defaultNS
				indentation: (unsigned int)indentation
{
	return [self of_XMLStringWithDefaultNS: defaultNS
				    namespaces: nil
				   indentation: indentation
					 level: 0];
}

- (void)addAttribute: (OFXMLAttribute *)attribute
{
	if (![attribute isKindOfClass: [OFXMLAttribute class]])
		@throw [OFInvalidArgumentException exception];

	if (_attributes == nil)
		_attributes = [[OFMutableArray alloc] init];

	if ([self attributeForName: attribute->_name
			 namespace: attribute->_namespace] == nil)
		[_attributes addObject: attribute];
}

- (void)addAttributeWithName: (OFString *)name
		 stringValue: (OFString *)stringValue
{
	[self addAttributeWithName: name
			 namespace: nil
		       stringValue: stringValue];
}

- (void)addAttributeWithName: (OFString *)name
		   namespace: (OFString *)namespace
		 stringValue: (OFString *)stringValue
{
	void *pool = objc_autoreleasePoolPush();

	[self addAttribute: [OFXMLAttribute attributeWithName: name
						    namespace: namespace
						  stringValue: stringValue]];

	objc_autoreleasePoolPop(pool);
}

- (OFXMLAttribute *)attributeForName: (OFString *)attributeName
{
	for (OFXMLAttribute *attribute in _attributes)
		if (attribute->_namespace == nil &&
		    [attribute->_name isEqual: attributeName])
			return attribute;

	return nil;
}

- (OFXMLAttribute *)attributeForName: (OFString *)attributeName
			   namespace: (OFString *)attributeNS
{
	if (attributeNS == nil)
		return [self attributeForName: attributeName];

	for (OFXMLAttribute *attribute in _attributes)
		if ([attribute->_namespace isEqual: attributeNS] &&
		    [attribute->_name isEqual: attributeName])
			return attribute;

	return nil;
}

- (void)removeAttributeForName: (OFString *)attributeName
{
	OFXMLAttribute *const *objects = _attributes.objects;
	size_t count = _attributes.count;

	for (size_t i = 0; i < count; i++) {
		if (objects[i]->_namespace == nil &&
		    [objects[i]->_name isEqual: attributeName]) {
			[_attributes removeObjectAtIndex: i];

			return;
		}
	}
}

- (void)removeAttributeForName: (OFString *)attributeName
		     namespace: (OFString *)attributeNS
{
	OFXMLAttribute *const *objects;
	size_t count;

	if (attributeNS == nil) {
		[self removeAttributeForName: attributeName];
		return;
	}

	objects = _attributes.objects;
	count = _attributes.count;

	for (size_t i = 0; i < count; i++) {
		if ([objects[i]->_namespace isEqual: attributeNS] &&
		    [objects[i]->_name isEqual: attributeName]) {
			[_attributes removeObjectAtIndex: i];
				return;
		}
	}
}

- (void)setPrefix: (OFString *)prefix forNamespace: (OFString *)namespace
{
	if (prefix.length == 0)
		@throw [OFInvalidArgumentException exception];

	[_namespaces setObject: prefix forKey: namespace];
}

- (void)bindPrefix: (OFString *)prefix forNamespace: (OFString *)namespace
{
	[self setPrefix: prefix forNamespace: namespace];
	[self addAttributeWithName: prefix
			 namespace: @"http://www.w3.org/2000/xmlns/"
		       stringValue: namespace];
}

- (void)addChild: (OFXMLNode *)child
{
	if ([child isKindOfClass: [OFXMLAttribute class]])
		@throw [OFInvalidArgumentException exception];

	if (_children == nil)
		_children = [[OFMutableArray alloc] init];

	[_children addObject: child];
}

- (void)insertChild: (OFXMLNode *)child atIndex: (size_t)idx
{
	if ([child isKindOfClass: [OFXMLAttribute class]])
		@throw [OFInvalidArgumentException exception];

	if (_children == nil)
		_children = [[OFMutableArray alloc] init];

	[_children insertObject: child atIndex: idx];
}

- (void)insertChildren: (OFArray *)children atIndex: (size_t)idx
{
	for (OFXMLNode *node in children)
		if ([node isKindOfClass: [OFXMLAttribute class]])
			@throw [OFInvalidArgumentException exception];

	[_children insertObjectsFromArray: children atIndex: idx];
}

- (void)removeChild: (OFXMLNode *)child
{
	if ([child isKindOfClass: [OFXMLAttribute class]])
		@throw [OFInvalidArgumentException exception];

	[_children removeObject: child];
}

- (void)removeChildAtIndex: (size_t)idx
{
	[_children removeObjectAtIndex: idx];
}

- (void)replaceChild: (OFXMLNode *)child withNode: (OFXMLNode *)node
{
	if ([node isKindOfClass: [OFXMLAttribute class]] ||
	    [child isKindOfClass: [OFXMLAttribute class]])
		@throw [OFInvalidArgumentException exception];

	[_children replaceObject: child withObject: node];
}

- (void)replaceChildAtIndex: (size_t)idx withNode: (OFXMLNode *)node
{
	if ([node isKindOfClass: [OFXMLAttribute class]])
		@throw [OFInvalidArgumentException exception];

	[_children replaceObjectAtIndex: idx withObject: node];
}

- (OFXMLElement *)elementForName: (OFString *)elementName
{
	return [self elementsForName: elementName].firstObject;
}

- (OFXMLElement *)elementForName: (OFString *)elementName
		       namespace: (OFString *)elementNS
{
	return [self elementsForName: elementName
			   namespace: elementNS].firstObject;
}

- (OFArray *)elements
{
	OFMutableArray OF_GENERIC(OFXMLElement *) *ret = [OFMutableArray array];

	for (OFXMLNode *child in _children)
		if ([child isKindOfClass: [OFXMLElement class]])
			[ret addObject: (OFXMLElement *)child];

	[ret makeImmutable];

	return ret;
}

- (OFArray *)elementsForName: (OFString *)elementName
{
	OFMutableArray OF_GENERIC(OFXMLElement *) *ret = [OFMutableArray array];

	for (OFXMLNode *child in _children) {
		if ([child isKindOfClass: [OFXMLElement class]]) {
			OFXMLElement *element = (OFXMLElement *)child;

			if (element->_namespace == nil &&
			    [element->_name isEqual: elementName])
				[ret addObject: element];
		}
	}

	[ret makeImmutable];

	return ret;
}

- (OFArray *)elementsForNamespace: (OFString *)elementNS
{
	OFMutableArray OF_GENERIC(OFXMLElement *) *ret = [OFMutableArray array];

	for (OFXMLNode *child in _children) {
		if ([child isKindOfClass: [OFXMLElement class]]) {
			OFXMLElement *element = (OFXMLElement *)child;

			if (element->_name != nil &&
			    [element->_namespace isEqual: elementNS])
				[ret addObject: element];
		}
	}

	[ret makeImmutable];

	return ret;
}

- (OFArray *)elementsForName: (OFString *)elementName
		   namespace: (OFString *)elementNS
{
	OFMutableArray OF_GENERIC(OFXMLElement *) *ret;

	if (elementNS == nil)
		return [self elementsForName: elementName];

	ret = [OFMutableArray array];

	for (OFXMLNode *child in _children) {
		if ([child isKindOfClass: [OFXMLElement class]]) {
			OFXMLElement *element = (OFXMLElement *)child;

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

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFXMLElement class]])
		return false;

	element = object;

	if (element->_name != _name && ![element->_name isEqual: _name])
		return false;
	if (element->_namespace != _namespace &&
	    ![element->_namespace isEqual: _namespace])
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

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddHash(&hash, _name.hash);
	OFHashAddHash(&hash, _namespace.hash);
	OFHashAddHash(&hash, _attributes.hash);
	OFHashAddHash(&hash, _namespaces.hash);
	OFHashAddHash(&hash, _children.hash);

	OFHashFinalize(&hash);

	return hash;
}

- (id)copy
{
	return [[OFXMLElement alloc] initWithElement: self];
}
@end
