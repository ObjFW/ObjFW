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
	OFString *attributePrefix = attribute->ns;

	if (attributePrefix == nil)
		return;

	attributeNS = namespace_for_prefix(attributePrefix, namespaces);

	if ((attributePrefix != nil && attributeNS == nil))
		@throw [OFUnboundNamespaceException
		    exceptionWithClass: [self class]
				prefix: attributePrefix];

	[attribute->ns release];
	attribute->ns = [attributeNS retain];
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

		cache = [[OFBigDataArray alloc] init];
		previous = [[OFMutableArray alloc] init];
		namespaces = [[OFMutableArray alloc] init];
		attributes = [[OFMutableArray alloc] init];

		pool = objc_autoreleasePoolPush();
		dict = [OFMutableDictionary dictionaryWithKeysAndObjects:
		    @"xml", @"http://www.w3.org/XML/1998/namespace",
		    @"xmlns", @"http://www.w3.org/2000/xmlns/", nil];
		[namespaces addObject: dict];

		acceptProlog = YES;
		lineNumber = 1;
		encoding = OF_STRING_ENCODING_UTF_8;
		depthLimit = 32;

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[cache release];
	[name release];
	[prefix release];
	[namespaces release];
	[attributes release];
	[attributeName release];
	[attributePrefix release];
	[previous release];

	[super dealloc];
}

- (id <OFXMLParserDelegate>)delegate
{
	return delegate;
}

- (void)setDelegate: (id <OFXMLParserDelegate>)delegate_
{
	delegate = delegate_;
}

- (size_t)depthLimit
{
	return depthLimit;
}

- (void)setDepthLimit: (size_t)depthLimit_
{
	depthLimit = depthLimit_;
}

- (void)parseBuffer: (const char*)buffer
	     length: (size_t)length
{
	size_t i, last = 0;

	for (i = 0; i < length; i++) {
		size_t j = i;

		lookupTable[state](self, selectors[state], buffer, &i, &last);

		/* Ensure we don't count this character twice */
		if (i != j)
			continue;

		if (buffer[i] == '\r' || (buffer[i] == '\n' &&
		    !lastCarriageReturn))
			lineNumber++;

		lastCarriageReturn = (buffer[i] == '\r');
	}

	/* In OF_XMLPARSER_IN_TAG, there can be only spaces */
	if (length - last > 0 && state != OF_XMLPARSER_IN_TAG)
		cache_append(cache, buffer + last, encoding, length - last);
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

	if ((finishedParsing || [previous count] < 1) && buffer[*i] != ' ' &&
	    buffer[*i] != '\t' && buffer[*i] != '\n' && buffer[*i] != '\r' &&
	    buffer[*i] != '<')
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];

	if (buffer[*i] != '<')
		return;

	if ((length = *i - *last) > 0)
		cache_append(cache, buffer + *last, encoding, length);

	if ([cache count] > 0) {
		void *pool = objc_autoreleasePoolPush();
		OFString *characters = transform_string(cache, 0, YES, self);

		if ([delegate respondsToSelector:
		    @selector(parser:foundCharacters:)])
			[delegate    parser: self
			    foundCharacters: characters];

		objc_autoreleasePoolPop(pool);
	}

	[cache removeAllItems];

	*last = *i + 1;
	state = OF_XMLPARSER_TAG_OPENED;
}

/* Tag was just opened */
- (void)OF_parseTagOpenedWithBuffer: (const char*)buffer
				  i: (size_t*)i
			       last: (size_t*)last
{
	if (finishedParsing && buffer[*i] != '!' && buffer[*i] != '?')
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];

	switch (buffer[*i]) {
	case '?':
		*last = *i + 1;
		state = OF_XMLPARSER_IN_PROCESSING_INSTRUCTIONS;
		level = 0;
		break;
	case '/':
		*last = *i + 1;
		state = OF_XMLPARSER_IN_CLOSE_TAG_NAME;
		acceptProlog = NO;
		break;
	case '!':
		*last = *i + 1;
		state = OF_XMLPARSER_IN_EXCLAMATIONMARK;
		acceptProlog = NO;
		break;
	default:
		if (depthLimit > 0 && [previous count] >= depthLimit)
			@throw [OFMalformedXMLException
			    exceptionWithClass: [self class]
					parser: self];

		state = OF_XMLPARSER_IN_TAG_NAME;
		acceptProlog = NO;
		(*i)--;
		break;
	}
}

/* <?xml […]?> */
- (BOOL)OF_parseXMLProcessingInstructions: (OFString*)pi
{
	const char *cString;
	size_t i, last, length;
	int piState = 0;
	OFString *attribute = nil;
	OFMutableString *value = nil;
	char piDelimiter = 0;

	if (!acceptProlog)
		return NO;

	acceptProlog = NO;

	pi = [pi substringWithRange: of_range(3, [pi length] - 3)];
	pi = [pi stringByDeletingEnclosingWhitespaces];

	cString = [pi UTF8String];
	length = [pi UTF8StringLength];

	for (i = last = 0; i < length; i++) {
		switch (piState) {
		case 0:
			if (cString[i] == ' ' || cString[i] == '\t' ||
			    cString[i] == '\r' || cString[i] == '\n')
				continue;

			last = i;
			piState = 1;
			i--;

			break;
		case 1:
			if (cString[i] != '=')
				continue;

			attribute = [OFString
			    stringWithUTF8String: cString + last
					  length: i - last];
			last = i + 1;
			piState = 2;

			break;
		case 2:
			if (cString[i] != '\'' && cString[i] != '"')
				return NO;

			piDelimiter = cString[i];
			last = i + 1;
			piState = 3;

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
					encoding = OF_STRING_ENCODING_UTF_8;
				else if ([value isEqual: @"iso-8859-1"])
					encoding =
					    OF_STRING_ENCODING_ISO_8859_1;
				else if ([value isEqual: @"iso-8859-15"])
					encoding =
					    OF_STRING_ENCODING_ISO_8859_15;
				else if ([value isEqual: @"windows-1252"])
					encoding =
					    OF_STRING_ENCODING_WINDOWS_1252;
				else
					return NO;
			}

			last = i + 1;
			piState = 0;

			break;
		}
	}

	if (piState != 0)
		return NO;

	return YES;
}

/* Inside processing instructions */
- (void)OF_parseInProcessingInstructionsWithBuffer: (const char*)buffer
						 i: (size_t*)i
					      last: (size_t*)last
{
	if (buffer[*i] == '?')
		level = 1;
	else if (level == 1 && buffer[*i] == '>') {
		void *pool = objc_autoreleasePoolPush();
		OFString *pi;

		cache_append(cache, buffer + *last, encoding, *i - *last);
		pi = transform_string(cache, 1, NO, nil);

		if ([pi isEqual: @"xml"] || [pi hasPrefix: @"xml "] ||
		    [pi hasPrefix: @"xml\t"] || [pi hasPrefix: @"xml\r"] ||
		    [pi hasPrefix: @"xml\n"])
			if (![self OF_parseXMLProcessingInstructions: pi])
				@throw [OFMalformedXMLException
				    exceptionWithClass: [self class]
						parser: self];

		if ([delegate respondsToSelector:
		    @selector(parser:foundProcessingInstructions:)])
			[delegate		 parser: self
			    foundProcessingInstructions: pi];

		objc_autoreleasePoolPop(pool);

		[cache removeAllItems];

		*last = *i + 1;
		state = OF_XMLPARSER_OUTSIDE_TAG;
	} else
		level = 0;
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
		cache_append(cache, buffer + *last, encoding, length);

	pool = objc_autoreleasePoolPush();

	cacheCString = [cache items];
	cacheLength = [cache count];
	cacheString = [OFString stringWithUTF8String: cacheCString
					      length: cacheLength];

	if ((tmp = memchr(cacheCString, ':', cacheLength)) != NULL) {
		name = [[OFString alloc]
		    initWithUTF8String: tmp + 1
				length: cacheLength - (tmp - cacheCString) - 1];
		prefix = [[OFString alloc]
		    initWithUTF8String: cacheCString
				length: tmp - cacheCString];
	} else {
		name = [cacheString copy];
		prefix = nil;
	}

	if (buffer[*i] == '>' || buffer[*i] == '/') {
		OFString *ns;

		ns = namespace_for_prefix(prefix, namespaces);

		if (prefix != nil && ns == nil)
			@throw [OFUnboundNamespaceException
			    exceptionWithClass: [self class]
					prefix: prefix];

		if ([delegate respondsToSelector: @selector(parser:
		    didStartElement:prefix:namespace:attributes:)])
			[delegate    parser: self
			    didStartElement: name
				     prefix: prefix
				  namespace: ns
				 attributes: nil];

		if (buffer[*i] == '/') {
			if ([delegate respondsToSelector:
			    @selector(parser:didEndElement:prefix:namespace:)])
				[delegate  parser: self
				    didEndElement: name
					   prefix: prefix
					namespace: ns];

			if ([previous count] == 0)
				finishedParsing = YES;
		} else
			[previous addObject: cacheString];

		[name release];
		[prefix release];
		name = prefix = nil;

		state = (buffer[*i] == '/'
		    ? OF_XMLPARSER_EXPECT_CLOSE
		    : OF_XMLPARSER_OUTSIDE_TAG);
	} else
		state = OF_XMLPARSER_IN_TAG;

	if (buffer[*i] != '/')
		[namespaces addObject: [OFMutableDictionary dictionary]];

	objc_autoreleasePoolPop(pool);

	[cache removeAllItems];
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
	OFString *cacheString;
	OFString *ns;

	if (buffer[*i] != ' ' && buffer[*i] != '\t' && buffer[*i] != '\n' &&
	    buffer[*i] != '\r' && buffer[*i] != '>')
		return;

	if ((length = *i - *last) > 0)
		cache_append(cache, buffer + *last, encoding, length);

	pool = objc_autoreleasePoolPush();

	cacheCString = [cache items];
	cacheLength = [cache count];
	cacheString = [OFString stringWithUTF8String: cacheCString
					      length: cacheLength];

	if ((tmp = memchr(cacheCString, ':', cacheLength)) != NULL) {
		name = [[OFString alloc]
		    initWithUTF8String: tmp + 1
				length: cacheLength - (tmp - cacheCString) - 1];
		prefix = [[OFString alloc]
		    initWithUTF8String: cacheCString
				length: tmp - cacheCString];
	} else {
		name = [cacheString copy];
		prefix = nil;
	}

	if (![[previous lastObject] isEqual: cacheString])
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];

	[previous removeLastObject];

	[cache removeAllItems];

	ns = namespace_for_prefix(prefix, namespaces);
	if (prefix != nil && ns == nil)
		@throw [OFUnboundNamespaceException
		    exceptionWithClass: [self class]
				prefix: prefix];

	if ([delegate respondsToSelector:
	    @selector(parser:didEndElement:prefix:namespace:)])
		[delegate  parser: self
		    didEndElement: name
			   prefix: prefix
			namespace: ns];

	objc_autoreleasePoolPop(pool);

	[namespaces removeLastObject];
	[name release];
	[prefix release];
	name = prefix = nil;

	*last = *i + 1;
	state = (buffer[*i] == '>'
	    ? OF_XMLPARSER_OUTSIDE_TAG
	    : OF_XMLPARSER_EXPECT_SPACE_OR_CLOSE);

	if ([previous count] == 0)
		finishedParsing = YES;
}

/* Inside a tag, name found */
- (void)OF_parseInTagWithBuffer: (const char*)buffer
			      i: (size_t*)i
			   last: (size_t*)last
{
	void *pool;
	OFString *ns;
	OFXMLAttribute **attributesObjects;
	size_t j, attributesCount;

	if (buffer[*i] != '>' && buffer[*i] != '/') {
		if (buffer[*i] != ' ' && buffer[*i] != '\t' &&
		    buffer[*i] != '\n' && buffer[*i] != '\r') {
			*last = *i;
			state = OF_XMLPARSER_IN_ATTR_NAME;
			(*i)--;
		}

		return;
	}

	attributesObjects = [attributes objects];
	attributesCount = [attributes count];

	ns = namespace_for_prefix(prefix, namespaces);

	if (prefix != nil && ns == nil)
		@throw [OFUnboundNamespaceException
		    exceptionWithClass: [self class]
				prefix: prefix];

	for (j = 0; j < attributesCount; j++)
		resolve_attribute_namespace(attributesObjects[j], namespaces,
		    self);

	pool = objc_autoreleasePoolPush();

	if ([delegate respondsToSelector:
	    @selector(parser:didStartElement:prefix:namespace:attributes:)])
		[delegate    parser: self
		    didStartElement: name
			     prefix: prefix
			  namespace: ns
			 attributes: attributes];

	if (buffer[*i] == '/') {
		if ([delegate respondsToSelector:
		    @selector(parser:didEndElement:prefix:namespace:)])
			[delegate  parser: self
			    didEndElement: name
				   prefix: prefix
				namespace: ns];

		if ([previous count] == 0)
			finishedParsing = YES;

		[namespaces removeLastObject];
	} else if (prefix != nil) {
		OFString *str = [OFString stringWithFormat: @"%@:%@",
							    prefix, name];
		[previous addObject: str];
	} else
		[previous addObject: name];

	objc_autoreleasePoolPop(pool);

	[name release];
	[prefix release];
	[attributes removeAllObjects];
	name = prefix = nil;

	*last = *i + 1;
	state = (buffer[*i] == '/'
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
		cache_append(cache, buffer + *last, encoding, length);

	pool = objc_autoreleasePoolPush();

	cacheString = [OFMutableString stringWithUTF8String: [cache items]
						     length: [cache count]];
	[cacheString deleteEnclosingWhitespaces];
	/* Prevent a useless copy later */
	[cacheString makeImmutable];

	cacheCString = [cacheString UTF8String];
	cacheLength = [cacheString UTF8StringLength];

	if ((tmp = memchr(cacheCString, ':', cacheLength)) != NULL) {
		attributeName = [[OFString alloc]
		    initWithUTF8String: tmp + 1
				length: cacheLength - (tmp - cacheCString) - 1];
		attributePrefix = [[OFString alloc]
		    initWithUTF8String: cacheCString
				length: tmp - cacheCString];
	} else {
		attributeName = [cacheString copy];
		attributePrefix = nil;
	}

	objc_autoreleasePoolPop(pool);

	[cache removeAllItems];

	*last = *i + 1;
	state = OF_XMLPARSER_EXPECT_DELIM;
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

	delimiter = buffer[*i];
	state = OF_XMLPARSER_IN_ATTR_VALUE;
}

/* Looking for attribute value */
- (void)OF_parseInAttributeValueWithBuffer: (const char*)buffer
					 i: (size_t*)i
				      last: (size_t*)last
{
	void *pool;
	OFString *attributeValue;
	size_t length;

	if (buffer[*i] != delimiter)
		return;

	if ((length = *i - *last) > 0)
		cache_append(cache, buffer + *last, encoding, length);

	pool = objc_autoreleasePoolPush();
	attributeValue = transform_string(cache, 0, YES, self);

	if (attributePrefix == nil && [attributeName isEqual: @"xmlns"])
		[[namespaces lastObject] setObject: attributeValue
					    forKey: @""];
	if ([attributePrefix isEqual: @"xmlns"])
		[[namespaces lastObject] setObject: attributeValue
					    forKey: attributeName];

	[attributes addObject:
	    [OFXMLAttribute attributeWithName: attributeName
				    namespace: attributePrefix
				  stringValue: attributeValue]];

	objc_autoreleasePoolPop(pool);

	[cache removeAllItems];
	[attributeName release];
	[attributePrefix release];
	attributeName = attributePrefix = nil;

	*last = *i + 1;
	state = OF_XMLPARSER_IN_TAG;
}

/* Expecting closing '>' */
- (void)OF_parseExpectCloseWithBuffer: (const char*)buffer
				    i: (size_t*)i
				 last: (size_t*)last
{
	if (buffer[*i] == '>') {
		*last = *i + 1;
		state = OF_XMLPARSER_OUTSIDE_TAG;
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
		state = OF_XMLPARSER_OUTSIDE_TAG;
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
	if (finishedParsing && buffer[*i] != '-')
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];

	if (buffer[*i] == '-')
		state = OF_XMLPARSER_IN_COMMENT_OPENING;
	else if (buffer[*i] == '[') {
		state = OF_XMLPARSER_IN_CDATA_OPENING;
		level = 0;
	} else if (buffer[*i] == 'D') {
		state = OF_XMLPARSER_IN_DOCTYPE;
		level = 0;
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
	if (buffer[*i] != "CDATA["[level])
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];

	if (++level == 6) {
		state = OF_XMLPARSER_IN_CDATA_1;
		level = 0;
	}

	*last = *i + 1;
}

- (void)OF_parseInCDATA1WithBuffer: (const char*)buffer
				 i: (size_t*)i
			      last: (size_t*)last
{
	if (buffer[*i] == ']')
		level++;
	else
		level = 0;

	if (level == 2)
		state = OF_XMLPARSER_IN_CDATA_2;
}

- (void)OF_parseInCDATA2WithBuffer: (const char*)buffer
				 i: (size_t*)i
			      last: (size_t*)last
{
	void *pool;
	OFString *CDATA;

	if (buffer[*i] != '>') {
		state = OF_XMLPARSER_IN_CDATA_1;
		level = (buffer[*i] == ']' ? 1 : 0);

		return;
	}

	pool = objc_autoreleasePoolPush();

	cache_append(cache, buffer + *last, encoding, *i - *last);
	CDATA = transform_string(cache, 2, NO, nil);

	if ([delegate respondsToSelector: @selector(parser:foundCDATA:)])
		[delegate parser: self
		      foundCDATA: CDATA];

	objc_autoreleasePoolPop(pool);

	[cache removeAllItems];

	*last = *i + 1;
	state = OF_XMLPARSER_OUTSIDE_TAG;
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
	state = OF_XMLPARSER_IN_COMMENT_1;
	level = 0;
}

- (void)OF_parseInComment1WithBuffer: (const char*)buffer
				   i: (size_t*)i
				last: (size_t*)last
{
	if (buffer[*i] == '-')
		level++;
	else
		level = 0;

	if (level == 2)
		state = OF_XMLPARSER_IN_COMMENT_2;
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

	cache_append(cache, buffer + *last, encoding, *i - *last);
	comment = transform_string(cache, 2, NO, nil);

	if ([delegate respondsToSelector: @selector(parser:foundComment:)])
		[delegate parser: self
		    foundComment: comment];

	objc_autoreleasePoolPop(pool);

	[cache removeAllItems];

	*last = *i + 1;
	state = OF_XMLPARSER_OUTSIDE_TAG;
}

/* In <!DOCTYPE ...> */
- (void)OF_parseInDoctypeWithBuffer: (const char*)buffer
				  i: (size_t*)i
			       last: (size_t*)last
{
	if ((level < 6 && buffer[*i] != "OCTYPE"[level]) ||
	    (level == 6 && buffer[*i] != ' ' && buffer[*i] != '\t' &&
	    buffer[*i] != '\n' && buffer[*i] != '\r'))
		@throw [OFMalformedXMLException exceptionWithClass: [self class]
							    parser: self];

	if (level < 7 || buffer[*i] == '<')
		level++;

	if (buffer[*i] == '>') {
		if (level == 7)
			state = OF_XMLPARSER_OUTSIDE_TAG;
		else
			level--;
	}

	*last = *i + 1;
}

- (size_t)lineNumber
{
	return lineNumber;
}

- (BOOL)finishedParsing
{
	return finishedParsing;
}

-	   (OFString*)string: (OFString*)string
  containsUnknownEntityNamed: (OFString*)entity
{
	if ([delegate respondsToSelector:
	    @selector(parser:foundUnknownEntityNamed:)])
		return [delegate     parser: self
		    foundUnknownEntityNamed: entity];

	return nil;
}
@end
