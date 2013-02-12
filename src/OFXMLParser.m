/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#include <sys/types.h>

#import "OFXMLParser.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFDataArray.h"
#import "OFXMLAttribute.h"
#import "OFStream.h"
#import "OFFile.h"
#import "OFSystemInfo.h"

#import "OFInitializationFailedException.h"
#import "OFMalformedXMLException.h"
#import "OFUnboundNamespaceException.h"

#import "autorelease.h"
#import "macros.h"

typedef void (*state_function)(id, SEL, const char*, size_t*, size_t*);
static SEL selectors[OF_XMLPARSER_NUM_STATES];
static state_function lookupTable[OF_XMLPARSER_NUM_STATES];

static OF_INLINE void
cache_append(OFDataArray *cache, const char *string,
    of_string_encoding_t encoding, size_t length)
{
	if (OF_LIKELY(encoding == OF_STRING_ENCODING_UTF_8))
		[cache addItems: string
			  count: length];
	else {
		void *pool = objc_autoreleasePoolPush();
		OFString *tmp = [OFString stringWithCString: string
						   encoding: encoding
						     length: length];
		[cache addItems: [tmp UTF8String]
			  count: [tmp UTF8StringLength]];
		objc_autoreleasePoolPop(pool);
	}
}

static OFString*
transform_string(OFDataArray *cache, size_t cut, BOOL unescape,
    id <OFStringXMLUnescapingDelegate> delegate)
{
	char *items;
	size_t i, length;
	BOOL hasEntities = NO;
	OFString *ret;

	items = [cache items];
	length = [cache count] - cut;

	for (i = 0; i < length; i++) {
		if (items[i] == '\r') {
			if (i + 1 < length && items[i + 1] == '\n') {
				[cache removeItemAtIndex: i];
				items = [cache items];

				i--;
				length--;
			} else
				items[i] = '\n';
		} else if (items[i] == '&')
			hasEntities = YES;
	}

	ret = [OFString stringWithUTF8String: items
				      length: length];

	if (unescape && hasEntities)
		return [ret stringByXMLUnescapingWithDelegate: delegate];

	return ret;
}

static OFString*
namespace_for_prefix(OFString *prefix, OFArray *namespaces)
{
	OFDictionary **objects = [namespaces objects];
	ssize_t i;

	if (prefix == nil)
		prefix = @"";

	for (i = [namespaces count] - 1; i >= 0; i--) {
		OFString *tmp;

		if ((tmp = [objects[i] objectForKey: prefix]) != nil)
			return tmp;
	}

	return nil;
}

static OF_INLINE void
resolve_attribute_namespace(OFXMLAttribute *attribute, OFArray *namespaces,
    OFXMLParser *self)
{
	OFString *attributeNS;
	OFString *attributePrefix = attribute->_namespace;

	if (attributePrefix == nil)
		return;

	attributeNS = namespace_for_prefix(attributePrefix, namespaces);

	if ((attributePrefix != nil && attributeNS == nil))
		@throw [OFUnboundNamespaceException
		    exceptionWithClass: [self class]
				prefix: attributePrefix];

	[attribute->_namespace release];
	attribute->_namespace = [attributeNS retain];
}

@implementation OFXMLParser
+ (void)initialize
{
	size_t i;

	const SEL selectors_[] = {
		@selector(OF_parseOutsideTagWithBuffer:i:last:),
		@selector(OF_parseTagOpenedWithBuffer:i:last:),
		@selector(OF_parseInProcessingInstructionsWithBuffer:i:last:),
		@selector(OF_parseInTagNameWithBuffer:i:last:),
		@selector(OF_parseInCloseTagNameWithBuffer:i:last:),
		@selector(OF_parseInTagWithBuffer:i:last:),
		@selector(OF_parseInAttributeNameWithBuffer:i:last:),
		@selector(OF_parseExpectDelimiterWithBuffer:i:last:),
		@selector(OF_parseInAttributeValueWithBuffer:i:last:),
		@selector(OF_parseExpectCloseWithBuffer:i:last:),
		@selector(OF_parseExpectSpaceOrCloseWithBuffer:i:last:),
		@selector(OF_parseInExclamationMarkWithBuffer:i:last:),
		@selector(OF_parseInCDATAOpeningWithBuffer:i:last:),
		@selector(OF_parseInCDATA1WithBuffer:i:last:),
		@selector(OF_parseInCDATA2WithBuffer:i:last:),
		@selector(OF_parseInCommentOpeningWithBuffer:i:last:),
		@selector(OF_parseInComment1WithBuffer:i:last:),
		@selector(OF_parseInComment2WithBuffer:i:last:),
		@selector(OF_parseInDoctypeWithBuffer:i:last:),
	};
	memcpy(selectors, selectors_, sizeof(selectors_));

	for (i = 0; i < OF_XMLPARSER_NUM_STATES; i++) {
		if (![self instancesRespondToSelector: selectors[i]])
			@throw [OFInitializationFailedException
			    exceptionWithClass: self];

		lookupTable[i] = (state_function)
		    [self instanceMethodForSelector: selectors[i]];
	}
}

+ (instancetype)parser
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	@try {
		void *pool;
		OFMutableDictionary *dict;

		_cache = [[OFBigDataArray alloc] init];
		_previous = [[OFMutableArray alloc] init];
		_namespaces = [[OFMutableArray alloc] init];
		_attributes = [[OFMutableArray alloc] init];

		pool = objc_autoreleasePoolPush();
		dict = [OFMutableDictionary dictionaryWithKeysAndObjects:
		    @"xml", @"http://www.w3.org/XML/1998/namespace",
		    @"xmlns", @"http://www.w3.org/2000/xmlns/", nil];
		[_namespaces addObject: dict];

		_acceptProlog = YES;
		_lineNumber = 1;
		_encoding = OF_STRING_ENCODING_UTF_8;
		_depthLimit = 32;

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_cache release];
	[_name release];
	[_prefix release];
	[_namespaces release];
	[_attributes release];
	[_attributeName release];
	[_attributePrefix release];
	[_previous release];

	[super dealloc];
}

- (id <OFXMLParserDelegate>)delegate
{
	return _delegate;
}

- (void)setDelegate: (id <OFXMLParserDelegate>)delegate
{
	_delegate = delegate;
}

- (size_t)depthLimit
{
	return _depthLimit;
}

- (void)setDepthLimit: (size_t)depthLimit
{
	_depthLimit = depthLimit;
}

- (void)parseBuffer: (const char*)buffer
	     length: (size_t)length
{
	size_t i, last = 0;

	for (i = 0; i < length; i++) {
		size_t j = i;

		lookupTable[_state](self, selectors[_state], buffer, &i, &last);

		/* Ensure we don't count this character twice */
		if (i != j)
			continue;

		if (buffer[i] == '\r' || (buffer[i] == '\n' &&
		    !_lastCarriageReturn))
			_lineNumber++;

		_lastCarriageReturn = (buffer[i] == '\r');
	}

	/* In OF_XMLPARSER_IN_TAG, there can be only spaces */
	if (length - last > 0 && _state != OF_XMLPARSER_IN_TAG)
		cache_append(_cache, buffer + last, _encoding, length - last);
}

- (void)parseString: (OFString*)string
{
	[self parseBuffer: [string UTF8String]
		   length: [string UTF8StringLength]];
}

- (void)parseStream: (OFStream*)stream
{
	size_t pageSize = [OFSystemInfo pageSize];
	char *buffer = [self allocMemoryWithSize: pageSize];

	@try {
		while (![stream isAtEndOfStream]) {
			size_t length = [stream readIntoBuffer: buffer
							length: pageSize];

			[self parseBuffer: buffer
				   length: length];
		}
	} @finally {
		[self freeMemory: buffer];
	}
}

- (void)parseFile: (OFString*)path
{
	OFFile *file = [[OFFile alloc] initWithPath: path
					       mode: @"rb"];

	@try {
		[self parseStream: file];
	} @finally {
		[file release];
	}
}

/*
 * The following methods handle the different states of the parser. They are
 * looked up in +[initialize] and put in a lookup table to speed things up.
 * One dispatch for every character would be way too slow!
 */

/* Not in a tag */
- (void)OF_parseOutsideTagWithBuffer: (const char*)buffer
				   i: (size_t*)i
				last: (size_t*)last
{
	size_t length;

	if ((_finishedParsing || [_previous count] < 1) && buffer[*i] != ' ' &&
	    buffer[*i] != '\t' && buffer[*i] != '\n' && buffer[*i] != '\r' &&
	    buffer[*i] != '<')
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];

	if (buffer[*i] != '<')
		return;

	if ((length = *i - *last) > 0)
		cache_append(_cache, buffer + *last, _encoding, length);

	if ([_cache count] > 0) {
		void *pool = objc_autoreleasePoolPush();
		OFString *characters = transform_string(_cache, 0, YES, self);

		if ([_delegate respondsToSelector:
		    @selector(parser:foundCharacters:)])
			[_delegate parser: self
			  foundCharacters: characters];

		objc_autoreleasePoolPop(pool);
	}

	[_cache removeAllItems];

	*last = *i + 1;
	_state = OF_XMLPARSER_TAG_OPENED;
}

/* Tag was just opened */
- (void)OF_parseTagOpenedWithBuffer: (const char*)buffer
				  i: (size_t*)i
			       last: (size_t*)last
{
	if (_finishedParsing && buffer[*i] != '!' && buffer[*i] != '?')
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];

	switch (buffer[*i]) {
	case '?':
		*last = *i + 1;
		_state = OF_XMLPARSER_IN_PROCESSING_INSTRUCTIONS;
		_level = 0;
		break;
	case '/':
		*last = *i + 1;
		_state = OF_XMLPARSER_IN_CLOSE_TAG_NAME;
		_acceptProlog = NO;
		break;
	case '!':
		*last = *i + 1;
		_state = OF_XMLPARSER_IN_EXCLAMATIONMARK;
		_acceptProlog = NO;
		break;
	default:
		if (_depthLimit > 0 && [_previous count] >= _depthLimit)
			@throw [OFMalformedXMLException
			    exceptionWithClass: [self class]
					parser: self];

		_state = OF_XMLPARSER_IN_TAG_NAME;
		_acceptProlog = NO;
		(*i)--;
		break;
	}
}

/* <?xml […]?> */
- (BOOL)OF_parseXMLProcessingInstructions: (OFString*)pi
{
	const char *cString;
	size_t i, last, length;
	int PIState = 0;
	OFString *attribute = nil;
	OFMutableString *value = nil;
	char piDelimiter = 0;

	if (!_acceptProlog)
		return NO;

	_acceptProlog = NO;

	pi = [pi substringWithRange: of_range(3, [pi length] - 3)];
	pi = [pi stringByDeletingEnclosingWhitespaces];

	cString = [pi UTF8String];
	length = [pi UTF8StringLength];

	for (i = last = 0; i < length; i++) {
		switch (PIState) {
		case 0:
			if (cString[i] == ' ' || cString[i] == '\t' ||
			    cString[i] == '\r' || cString[i] == '\n')
				continue;

			last = i;
			PIState = 1;
			i--;

			break;
		case 1:
			if (cString[i] != '=')
				continue;

			attribute = [OFString
			    stringWithUTF8String: cString + last
					  length: i - last];
			last = i + 1;
			PIState = 2;

			break;
		case 2:
			if (cString[i] != '\'' && cString[i] != '"')
				return NO;

			piDelimiter = cString[i];
			last = i + 1;
			PIState = 3;

			break;
		case 3:
			if (cString[i] != piDelimiter)
				continue;

			value = [OFMutableString
			    stringWithUTF8String: cString + last
					  length: i - last];

			if ([attribute isEqual: @"version"])
				if (![value hasPrefix: @"1."])
					return NO;

			if ([attribute isEqual: @"encoding"]) {
				[value lowercase];

				if ([value isEqual: @"utf-8"])
					_encoding = OF_STRING_ENCODING_UTF_8;
				else if ([value isEqual: @"iso-8859-1"])
					_encoding =
					    OF_STRING_ENCODING_ISO_8859_1;
				else if ([value isEqual: @"iso-8859-15"])
					_encoding =
					    OF_STRING_ENCODING_ISO_8859_15;
				else if ([value isEqual: @"windows-1252"])
					_encoding =
					    OF_STRING_ENCODING_WINDOWS_1252;
				else
					return NO;
			}

			last = i + 1;
			PIState = 0;

			break;
		}
	}

	if (PIState != 0)
		return NO;

	return YES;
}

/* Inside processing instructions */
- (void)OF_parseInProcessingInstructionsWithBuffer: (const char*)buffer
						 i: (size_t*)i
					      last: (size_t*)last
{
	if (buffer[*i] == '?')
		_level = 1;
	else if (_level == 1 && buffer[*i] == '>') {
		void *pool = objc_autoreleasePoolPush();
		OFString *PI;

		cache_append(_cache, buffer + *last, _encoding, *i - *last);
		PI = transform_string(_cache, 1, NO, nil);

		if ([PI isEqual: @"xml"] || [PI hasPrefix: @"xml "] ||
		    [PI hasPrefix: @"xml\t"] || [PI hasPrefix: @"xml\r"] ||
		    [PI hasPrefix: @"xml\n"])
			if (![self OF_parseXMLProcessingInstructions: PI])
				@throw [OFMalformedXMLException
				    exceptionWithClass: [self class]
						parser: self];

		if ([_delegate respondsToSelector:
		    @selector(parser:foundProcessingInstructions:)])
			[_delegate		 parser: self
			    foundProcessingInstructions: PI];

		objc_autoreleasePoolPop(pool);

		[_cache removeAllItems];

		*last = *i + 1;
		_state = OF_XMLPARSER_OUTSIDE_TAG;
	} else
		_level = 0;
}

/* Inside a tag, no name yet */
- (void)OF_parseInTagNameWithBuffer: (const char*)buffer
				  i: (size_t*)i
			       last: (size_t*)last
{
	void *pool;
	const char *cacheCString, *tmp;
	size_t length, cacheLength;
	OFString *cacheString;

	if (buffer[*i] != ' ' && buffer[*i] != '\t' && buffer[*i] != '\n' &&
	    buffer[*i] != '\r' && buffer[*i] != '>' && buffer[*i] != '/')
		return;

	if ((length = *i - *last) > 0)
		cache_append(_cache, buffer + *last, _encoding, length);

	pool = objc_autoreleasePoolPush();

	cacheCString = [_cache items];
	cacheLength = [_cache count];
	cacheString = [OFString stringWithUTF8String: cacheCString
					      length: cacheLength];

	if ((tmp = memchr(cacheCString, ':', cacheLength)) != NULL) {
		_name = [[OFString alloc]
		    initWithUTF8String: tmp + 1
				length: cacheLength - (tmp - cacheCString) - 1];
		_prefix = [[OFString alloc]
		    initWithUTF8String: cacheCString
				length: tmp - cacheCString];
	} else {
		_name = [cacheString copy];
		_prefix = nil;
	}

	if (buffer[*i] == '>' || buffer[*i] == '/') {
		OFString *namespace;

		namespace = namespace_for_prefix(_prefix, _namespaces);

		if (_prefix != nil && namespace == nil)
			@throw [OFUnboundNamespaceException
			    exceptionWithClass: [self class]
					prefix: _prefix];

		if ([_delegate respondsToSelector: @selector(parser:
		    didStartElement:prefix:namespace:attributes:)])
			[_delegate parser: self
			  didStartElement: _name
				   prefix: _prefix
				namespace: namespace
			       attributes: nil];

		if (buffer[*i] == '/') {
			if ([_delegate respondsToSelector:
			    @selector(parser:didEndElement:prefix:namespace:)])
				[_delegate parser: self
				    didEndElement: _name
					   prefix: _prefix
					namespace: namespace];

			if ([_previous count] == 0)
				_finishedParsing = YES;
		} else
			[_previous addObject: cacheString];

		[_name release];
		[_prefix release];
		_name = _prefix = nil;

		_state = (buffer[*i] == '/'
		    ? OF_XMLPARSER_EXPECT_CLOSE
		    : OF_XMLPARSER_OUTSIDE_TAG);
	} else
		_state = OF_XMLPARSER_IN_TAG;

	if (buffer[*i] != '/')
		[_namespaces addObject: [OFMutableDictionary dictionary]];

	objc_autoreleasePoolPop(pool);

	[_cache removeAllItems];
	*last = *i + 1;
}

/* Inside a close tag, no name yet */
- (void)OF_parseInCloseTagNameWithBuffer: (const char*)buffer
				       i: (size_t*)i
				    last: (size_t*)last
{
	void *pool;
	const char *cacheCString, *tmp;
	size_t length, cacheLength;
	OFString *cacheString, *namespace;

	if (buffer[*i] != ' ' && buffer[*i] != '\t' && buffer[*i] != '\n' &&
	    buffer[*i] != '\r' && buffer[*i] != '>')
		return;

	if ((length = *i - *last) > 0)
		cache_append(_cache, buffer + *last, _encoding, length);

	pool = objc_autoreleasePoolPush();

	cacheCString = [_cache items];
	cacheLength = [_cache count];
	cacheString = [OFString stringWithUTF8String: cacheCString
					      length: cacheLength];

	if ((tmp = memchr(cacheCString, ':', cacheLength)) != NULL) {
		_name = [[OFString alloc]
		    initWithUTF8String: tmp + 1
				length: cacheLength - (tmp - cacheCString) - 1];
		_prefix = [[OFString alloc]
		    initWithUTF8String: cacheCString
				length: tmp - cacheCString];
	} else {
		_name = [cacheString copy];
		_prefix = nil;
	}

	if (![[_previous lastObject] isEqual: cacheString])
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];

	[_previous removeLastObject];

	[_cache removeAllItems];

	namespace = namespace_for_prefix(_prefix, _namespaces);
	if (_prefix != nil && namespace == nil)
		@throw [OFUnboundNamespaceException
		    exceptionWithClass: [self class]
				prefix: _prefix];

	if ([_delegate respondsToSelector:
	    @selector(parser:didEndElement:prefix:namespace:)])
		[_delegate parser: self
		    didEndElement: _name
			   prefix: _prefix
			namespace: namespace];

	objc_autoreleasePoolPop(pool);

	[_namespaces removeLastObject];
	[_name release];
	[_prefix release];
	_name = _prefix = nil;

	*last = *i + 1;
	_state = (buffer[*i] == '>'
	    ? OF_XMLPARSER_OUTSIDE_TAG
	    : OF_XMLPARSER_EXPECT_SPACE_OR_CLOSE);

	if ([_previous count] == 0)
		_finishedParsing = YES;
}

/* Inside a tag, name found */
- (void)OF_parseInTagWithBuffer: (const char*)buffer
			      i: (size_t*)i
			   last: (size_t*)last
{
	void *pool;
	OFString *namespace;
	OFXMLAttribute **attributesObjects;
	size_t j, attributesCount;

	if (buffer[*i] != '>' && buffer[*i] != '/') {
		if (buffer[*i] != ' ' && buffer[*i] != '\t' &&
		    buffer[*i] != '\n' && buffer[*i] != '\r') {
			*last = *i;
			_state = OF_XMLPARSER_IN_ATTR_NAME;
			(*i)--;
		}

		return;
	}

	attributesObjects = [_attributes objects];
	attributesCount = [_attributes count];

	namespace = namespace_for_prefix(_prefix, _namespaces);

	if (_prefix != nil && namespace == nil)
		@throw [OFUnboundNamespaceException
		    exceptionWithClass: [self class]
				prefix: _prefix];

	for (j = 0; j < attributesCount; j++)
		resolve_attribute_namespace(attributesObjects[j], _namespaces,
		    self);

	pool = objc_autoreleasePoolPush();

	if ([_delegate respondsToSelector:
	    @selector(parser:didStartElement:prefix:namespace:attributes:)])
		[_delegate parser: self
		  didStartElement: _name
			   prefix: _prefix
			namespace: namespace
		       attributes: _attributes];

	if (buffer[*i] == '/') {
		if ([_delegate respondsToSelector:
		    @selector(parser:didEndElement:prefix:namespace:)])
			[_delegate parser: self
			    didEndElement: _name
				   prefix: _prefix
				namespace: namespace];

		if ([_previous count] == 0)
			_finishedParsing = YES;

		[_namespaces removeLastObject];
	} else if (_prefix != nil) {
		OFString *str = [OFString stringWithFormat: @"%@:%@",
							    _prefix, _name];
		[_previous addObject: str];
	} else
		[_previous addObject: _name];

	objc_autoreleasePoolPop(pool);

	[_name release];
	[_prefix release];
	[_attributes removeAllObjects];
	_name = _prefix = nil;

	*last = *i + 1;
	_state = (buffer[*i] == '/'
	    ? OF_XMLPARSER_EXPECT_CLOSE
	    : OF_XMLPARSER_OUTSIDE_TAG);
}

/* Looking for attribute name */
- (void)OF_parseInAttributeNameWithBuffer: (const char*)buffer
					i: (size_t*)i
				     last: (size_t*)last
{
	void *pool;
	OFMutableString *cacheString;
	const char *cacheCString, *tmp;
	size_t length, cacheLength;

	if (buffer[*i] != '=')
		return;

	if ((length = *i - *last) > 0)
		cache_append(_cache, buffer + *last, _encoding, length);

	pool = objc_autoreleasePoolPush();

	cacheString = [OFMutableString stringWithUTF8String: [_cache items]
						     length: [_cache count]];
	[cacheString deleteEnclosingWhitespaces];
	/* Prevent a useless copy later */
	[cacheString makeImmutable];

	cacheCString = [cacheString UTF8String];
	cacheLength = [cacheString UTF8StringLength];

	if ((tmp = memchr(cacheCString, ':', cacheLength)) != NULL) {
		_attributeName = [[OFString alloc]
		    initWithUTF8String: tmp + 1
				length: cacheLength - (tmp - cacheCString) - 1];
		_attributePrefix = [[OFString alloc]
		    initWithUTF8String: cacheCString
				length: tmp - cacheCString];
	} else {
		_attributeName = [cacheString copy];
		_attributePrefix = nil;
	}

	objc_autoreleasePoolPop(pool);

	[_cache removeAllItems];

	*last = *i + 1;
	_state = OF_XMLPARSER_EXPECT_DELIM;
}

/* Expecting delimiter */
- (void)OF_parseExpectDelimiterWithBuffer: (const char*)buffer
					i: (size_t*)i
				     last: (size_t*)last
{
	*last = *i + 1;

	if (buffer[*i] == ' ' || buffer[*i] == '\t' || buffer[*i] == '\n' ||
	    buffer[*i] == '\r')
		return;

	if (buffer[*i] != '\'' && buffer[*i] != '"')
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];

	_delimiter = buffer[*i];
	_state = OF_XMLPARSER_IN_ATTR_VALUE;
}

/* Looking for attribute value */
- (void)OF_parseInAttributeValueWithBuffer: (const char*)buffer
					 i: (size_t*)i
				      last: (size_t*)last
{
	void *pool;
	OFString *attributeValue;
	size_t length;

	if (buffer[*i] != _delimiter)
		return;

	if ((length = *i - *last) > 0)
		cache_append(_cache, buffer + *last, _encoding, length);

	pool = objc_autoreleasePoolPush();
	attributeValue = transform_string(_cache, 0, YES, self);

	if (_attributePrefix == nil && [_attributeName isEqual: @"xmlns"])
		[[_namespaces lastObject] setObject: attributeValue
					     forKey: @""];
	if ([_attributePrefix isEqual: @"xmlns"])
		[[_namespaces lastObject] setObject: attributeValue
					     forKey: _attributeName];

	[_attributes addObject:
	    [OFXMLAttribute attributeWithName: _attributeName
				    namespace: _attributePrefix
				  stringValue: attributeValue]];

	objc_autoreleasePoolPop(pool);

	[_cache removeAllItems];
	[_attributeName release];
	[_attributePrefix release];
	_attributeName = _attributePrefix = nil;

	*last = *i + 1;
	_state = OF_XMLPARSER_IN_TAG;
}

/* Expecting closing '>' */
- (void)OF_parseExpectCloseWithBuffer: (const char*)buffer
				    i: (size_t*)i
				 last: (size_t*)last
{
	if (buffer[*i] == '>') {
		*last = *i + 1;
		_state = OF_XMLPARSER_OUTSIDE_TAG;
	} else
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];
}

/* Expecting closing '>' or space */
- (void)OF_parseExpectSpaceOrCloseWithBuffer: (const char*)buffer
					   i: (size_t*)i
					last: (size_t*)last
{
	if (buffer[*i] == '>') {
		*last = *i + 1;
		_state = OF_XMLPARSER_OUTSIDE_TAG;
	} else if (buffer[*i] != ' ' && buffer[*i] != '\t' &&
	    buffer[*i] != '\n' && buffer[*i] != '\r')
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];
}

/* In <! */
- (void)OF_parseInExclamationMarkWithBuffer: (const char*)buffer
					  i: (size_t*)i
				       last: (size_t*)last
{
	if (_finishedParsing && buffer[*i] != '-')
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];

	if (buffer[*i] == '-')
		_state = OF_XMLPARSER_IN_COMMENT_OPENING;
	else if (buffer[*i] == '[') {
		_state = OF_XMLPARSER_IN_CDATA_OPENING;
		_level = 0;
	} else if (buffer[*i] == 'D') {
		_state = OF_XMLPARSER_IN_DOCTYPE;
		_level = 0;
	} else
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];

	*last = *i + 1;
}

/* CDATA */
- (void)OF_parseInCDATAOpeningWithBuffer: (const char*)buffer
				       i: (size_t*)i
				    last: (size_t*)last
{
	if (buffer[*i] != "CDATA["[_level])
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];

	if (++_level == 6) {
		_state = OF_XMLPARSER_IN_CDATA_1;
		_level = 0;
	}

	*last = *i + 1;
}

- (void)OF_parseInCDATA1WithBuffer: (const char*)buffer
				 i: (size_t*)i
			      last: (size_t*)last
{
	if (buffer[*i] == ']')
		_level++;
	else
		_level = 0;

	if (_level == 2)
		_state = OF_XMLPARSER_IN_CDATA_2;
}

- (void)OF_parseInCDATA2WithBuffer: (const char*)buffer
				 i: (size_t*)i
			      last: (size_t*)last
{
	void *pool;
	OFString *CDATA;

	if (buffer[*i] != '>') {
		_state = OF_XMLPARSER_IN_CDATA_1;
		_level = (buffer[*i] == ']' ? 1 : 0);

		return;
	}

	pool = objc_autoreleasePoolPush();

	cache_append(_cache, buffer + *last, _encoding, *i - *last);
	CDATA = transform_string(_cache, 2, NO, nil);

	if ([_delegate respondsToSelector: @selector(parser:foundCDATA:)])
		[_delegate parser: self
		       foundCDATA: CDATA];

	objc_autoreleasePoolPop(pool);

	[_cache removeAllItems];

	*last = *i + 1;
	_state = OF_XMLPARSER_OUTSIDE_TAG;
}

/* Comment */
- (void)OF_parseInCommentOpeningWithBuffer: (const char*)buffer
					 i: (size_t*)i
				      last: (size_t*)last
{
	if (buffer[*i] != '-')
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];

	*last = *i + 1;
	_state = OF_XMLPARSER_IN_COMMENT_1;
	_level = 0;
}

- (void)OF_parseInComment1WithBuffer: (const char*)buffer
				   i: (size_t*)i
				last: (size_t*)last
{
	if (buffer[*i] == '-')
		_level++;
	else
		_level = 0;

	if (_level == 2)
		_state = OF_XMLPARSER_IN_COMMENT_2;
}

- (void)OF_parseInComment2WithBuffer: (const char*)buffer
				   i: (size_t*)i
				last: (size_t*)last
{
	void *pool;
	OFString *comment;

	if (buffer[*i] != '>')
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];

	pool = objc_autoreleasePoolPush();

	cache_append(_cache, buffer + *last, _encoding, *i - *last);
	comment = transform_string(_cache, 2, NO, nil);

	if ([_delegate respondsToSelector: @selector(parser:foundComment:)])
		[_delegate parser: self
		     foundComment: comment];

	objc_autoreleasePoolPop(pool);

	[_cache removeAllItems];

	*last = *i + 1;
	_state = OF_XMLPARSER_OUTSIDE_TAG;
}

/* In <!DOCTYPE ...> */
- (void)OF_parseInDoctypeWithBuffer: (const char*)buffer
				  i: (size_t*)i
			       last: (size_t*)last
{
	if ((_level < 6 && buffer[*i] != "OCTYPE"[_level]) ||
	    (_level == 6 && buffer[*i] != ' ' && buffer[*i] != '\t' &&
	    buffer[*i] != '\n' && buffer[*i] != '\r'))
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];

	if (_level < 7 || buffer[*i] == '<')
		_level++;

	if (buffer[*i] == '>') {
		if (_level == 7)
			_state = OF_XMLPARSER_OUTSIDE_TAG;
		else
			_level--;
	}

	*last = *i + 1;
}

- (size_t)lineNumber
{
	return _lineNumber;
}

- (BOOL)finishedParsing
{
	return _finishedParsing;
}

-	   (OFString*)string: (OFString*)string
  containsUnknownEntityNamed: (OFString*)entity
{
	if ([_delegate respondsToSelector:
	    @selector(parser:foundUnknownEntityNamed:)])
		return [_delegate parser: self
		 foundUnknownEntityNamed: entity];

	return nil;
}
@end
