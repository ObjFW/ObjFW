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

#define OF_XML_PARSER_M

#include <string.h>
#include <unistd.h>

#import "OFXMLParser.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFXMLAttribute.h"
#import "OFStream.h"
#import "OFFile.h"
#import "OFAutoreleasePool.h"

#import "OFInitializationFailedException.h"
#import "OFMalformedXMLException.h"
#import "OFUnboundNamespaceException.h"

#import "macros.h"

typedef void (*state_function)(id, SEL, const char*, size_t*, size_t*);
static SEL selectors[OF_XMLPARSER_NUM_STATES];
static state_function lookupTable[OF_XMLPARSER_NUM_STATES];

static void
cache_append(OFMutableString *cache, const char *string,
    of_string_encoding_t encoding, size_t length)
{
	if (OF_LIKELY(encoding == OF_STRING_ENCODING_UTF_8))
		[cache appendCStringWithoutUTF8Checking: string
						 length: length];
	else {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		[cache appendString: [OFString stringWithCString: string
							encoding: encoding
							  length: length]];
		[pool release];
	}
}

static OFString*
transform_string(OFMutableString *cache, size_t cut, BOOL unescape,
    OFObject <OFStringXMLUnescapingDelegate> *delegate)
{
	[cache replaceOccurrencesOfString: @"\r\n"
			       withString: @"\n"];
	[cache replaceOccurrencesOfString: @"\r"
			       withString: @"\n"];

	if (cut > 0) {
		size_t length = [cache length];

		[cache deleteCharactersFromIndex: length - cut
					 toIndex: length];
	}

	if (unescape)
		return [cache stringByXMLUnescapingWithDelegate: delegate];
	else
		return [[cache copy] autorelease];
}

static OFString*
namespace_for_prefix(OFString *prefix, OFArray *namespaces)
{
	OFDictionary **cArray = [namespaces cArray];
	ssize_t i;

	if (prefix == nil)
		prefix = @"";

	for (i = [namespaces count] - 1; i >= 0; i--) {
		OFString *tmp;

		if ((tmp = [cArray[i] objectForKey: prefix]) != nil)
			return tmp;
	}

	return nil;
}

static OF_INLINE void
resolve_attribute_namespace(OFXMLAttribute *attribute, OFArray *namespaces,
    Class isa)
{
	OFString *attributeNS;
	OFString *attributePrefix = attribute->ns;

	if (attributePrefix == nil)
		return;

	attributeNS = namespace_for_prefix(attributePrefix, namespaces);

	if ((attributePrefix != nil && attributeNS == nil))
		@throw [OFUnboundNamespaceException
		    newWithClass: isa
			  prefix: attributePrefix];

	[attribute->ns release];
	attribute->ns = [attributeNS retain];
}

@implementation OFXMLParser
#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
@synthesize processingInstructionsHandler, elementStartHandler;
@synthesize elementEndHandler, charactersHandler, CDATAHandler, commentHandler;
@synthesize unknownEntityHandler;
#endif

+ (void)initialize
{
	size_t i;

	const SEL selectors_[] = {
		@selector(_parseOutsideTagWithBuffer:i:last:),
		@selector(_parseTagOpenedWithBuffer:i:last:),
		@selector(_parseInProcessingInstructionsWithBuffer:i:last:),
		@selector(_parseInTagNameWithBuffer:i:last:),
		@selector(_parseInCloseTagNameWithBuffer:i:last:),
		@selector(_parseInTagWithBuffer:i:last:),
		@selector(_parseInAttributeNameWithBuffer:i:last:),
		@selector(_parseExpectDelimiterWithBuffer:i:last:),
		@selector(_parseInAttributeValueWithBuffer:i:last:),
		@selector(_parseExpectCloseWithBuffer:i:last:),
		@selector(_parseExpectSpaceOrCloseWithBuffer:i:last:),
		@selector(_parseInExclamationMarkWithBuffer:i:last:),
		@selector(_parseInCDATAOpeningWithBuffer:i:last:),
		@selector(_parseInCDATA1WithBuffer:i:last:),
		@selector(_parseInCDATA2WithBuffer:i:last:),
		@selector(_parseInCommentOpeningWithBuffer:i:last:),
		@selector(_parseInComment1WithBuffer:i:last:),
		@selector(_parseInComment2WithBuffer:i:last:),
		@selector(_parseInDoctypeWithBuffer:i:last:),
	};
	memcpy(selectors, selectors_, sizeof(selectors_));

	for (i = 0; i < OF_XMLPARSER_NUM_STATES; i++) {
		if (![self instancesRespondToSelector: selectors[i]])
			@throw [OFInitializationFailedException
			    newWithClass: self];

		lookupTable[i] = (state_function)
		    [self instanceMethodForSelector: selectors[i]];
	}
}

+ parser
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	@try {
		OFAutoreleasePool *pool;
		OFMutableDictionary *dict;

		cache = [[OFMutableString alloc] init];
		previous = [[OFMutableArray alloc] init];
		namespaces = [[OFMutableArray alloc] init];

		pool = [[OFAutoreleasePool alloc] init];
		dict = [OFMutableDictionary dictionaryWithKeysAndObjects:
		    @"xml", @"http://www.w3.org/XML/1998/namespace",
		    @"xmlns", @"http://www.w3.org/2000/xmlns/", nil];
		[namespaces addObject: dict];

		acceptProlog = YES;
		lineNumber = 1;
		encoding = OF_STRING_ENCODING_UTF_8;

		[pool release];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[(id)delegate release];

	[cache release];
	[name release];
	[prefix release];
	[namespaces release];
	[attributes release];
	[attributeName release];
	[attributePrefix release];
	[previous release];
#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
	[elementStartHandler release];
	[elementEndHandler release];
	[charactersHandler release];
	[CDATAHandler release];
	[commentHandler release];
	[unknownEntityHandler release];
#endif

	[super dealloc];
}

- (id <OFXMLParserDelegate>)delegate
{
	OF_GETTER(delegate, YES)
}

- (void)setDelegate: (id <OFXMLParserDelegate>)delegate_
{
	OF_SETTER(delegate, delegate_, YES, NO)
}

- (void)parseBuffer: (const char*)buffer
	 withLength: (size_t)length
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
	[self parseBuffer: [string cString]
	       withLength: [string cStringLength]];
}

- (void)parseStream: (OFStream*)stream
{
	char *buffer = [self allocMemoryWithSize: of_pagesize];

	@try {
		while (![stream isAtEndOfStream]) {
			size_t length = [stream readNBytes: of_pagesize
						intoBuffer: buffer];

			[self parseBuffer: buffer
			       withLength: length];
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
- (void)_parseOutsideTagWithBuffer: (const char*)buffer
				 i: (size_t*)i
			      last: (size_t*)last
{
	size_t length;

	if ((finishedParsing || [previous count] < 1) && buffer[*i] != ' ' &&
	    buffer[*i] != '\t' && buffer[*i] != '\n' && buffer[*i] != '\r' &&
	    buffer[*i] != '<')
		@throw [OFMalformedXMLException newWithClass: isa
						      parser: self];

	if (buffer[*i] != '<')
		return;

	if ((length = *i - *last) > 0)
		cache_append(cache, buffer + *last, encoding, length);

	if ([cache cStringLength] > 0) {
		OFString *characters;
		OFAutoreleasePool *pool;

		pool = [[OFAutoreleasePool alloc] init];
		characters = transform_string(cache, 0, YES, self);

#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
		if (charactersHandler != NULL)
			charactersHandler(self, characters);
		else
#endif
			[delegate parser: self
			 foundCharacters: characters];

		[pool release];
	}

	[cache setToCString: ""];

	*last = *i + 1;
	state = OF_XMLPARSER_TAG_OPENED;
}

/* Tag was just opened */
- (void)_parseTagOpenedWithBuffer: (const char*)buffer
				i: (size_t*)i
			     last: (size_t*)last
{
	if (finishedParsing && buffer[*i] != '!' && buffer[*i] != '?')
		@throw [OFMalformedXMLException newWithClass: isa
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
			state = OF_XMLPARSER_IN_TAG_NAME;
			acceptProlog = NO;
			(*i)--;
			break;
	}
}

/* <?xml […]?> */
- (BOOL)_parseXMLProcessingInstructions: (OFString*)pi
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

	pi = [pi substringFromIndex: 3
			    toIndex: [pi length]];
	pi = [pi stringByDeletingLeadingAndTrailingWhitespaces];

	cString = [pi cString];
	length = [pi cStringLength];

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

			attribute = [OFString stringWithCString: cString + last
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
			    stringWithCString: cString + last
				       length: i - last];

			if ([attribute isEqual: @"version"])
				if (![value hasPrefix: @"1."])
					return NO;

			if ([attribute isEqual: @"encoding"]) {
				[value lower];

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
- (void)_parseInProcessingInstructionsWithBuffer: (const char*)buffer
					       i: (size_t*)i
					    last: (size_t*)last
{
	if (buffer[*i] == '?')
		level = 1;
	else if (level == 1 && buffer[*i] == '>') {
		OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
		OFString *pi;

		cache_append(cache, buffer + *last, encoding, *i - *last);
		pi = transform_string(cache, 1, NO, nil);

		if ([pi isEqual: @"xml"] || [pi hasPrefix: @"xml "] ||
		    [pi hasPrefix: @"xml\t"] || [pi hasPrefix: @"xml\r"] ||
		    [pi hasPrefix: @"xml\n"])
			if (![self _parseXMLProcessingInstructions: pi])
				@throw [OFMalformedXMLException
				    newWithClass: isa
					parser: self];

		[delegate parser: self
		    foundProcessingInstructions: pi];

		[pool release];

		[cache setToCString: ""];

		*last = *i + 1;
		state = OF_XMLPARSER_OUTSIDE_TAG;
	} else
		level = 0;
}

/* Inside a tag, no name yet */
- (void)_parseInTagNameWithBuffer: (const char*)buffer
				i: (size_t*)i
			     last: (size_t*)last
{
	const char *cacheCString, *tmp;
	size_t length, cacheLength;

	if (buffer[*i] != ' ' && buffer[*i] != '\t' && buffer[*i] != '\n' &&
	    buffer[*i] != '\r' && buffer[*i] != '>' && buffer[*i] != '/')
		return;

	if ((length = *i - *last) > 0)
		cache_append(cache, buffer + *last, encoding, length);

	cacheCString = [cache cString];
	cacheLength = [cache cStringLength];

	if ((tmp = memchr(cacheCString, ':', cacheLength)) != NULL) {
		name = [[OFString alloc] initWithCString: tmp + 1
						  length: cacheLength -
							  (tmp - cacheCString) -
							  1];
		prefix = [[OFString alloc] initWithCString: cacheCString
						    length: tmp - cacheCString];
	} else {
		name = [cache copy];
		prefix = nil;
	}

	if (buffer[*i] == '>' || buffer[*i] == '/') {
		OFAutoreleasePool *pool;
		OFString *ns;

		ns = namespace_for_prefix(prefix, namespaces);

		if (prefix != nil && ns == nil)
			@throw
			    [OFUnboundNamespaceException newWithClass: isa
							       prefix: prefix];

		pool = [[OFAutoreleasePool alloc] init];

#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
		if (elementStartHandler != NULL)
			elementStartHandler(self, name, prefix, ns, nil);
		else
#endif
			[delegate parser: self
			 didStartElement: name
			      withPrefix: prefix
			       namespace: ns
			      attributes: nil];

		if (buffer[*i] == '/') {
#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
			if (elementEndHandler != NULL)
				elementEndHandler(self, name, prefix, ns);
			else
#endif
				[delegate parser: self
				   didEndElement: name
				      withPrefix: prefix
				       namespace: ns];
		} else
			[previous addObject: [[cache copy] autorelease]];

		[pool release];

		[name release];
		[prefix release];
		name = prefix = nil;

		state = (buffer[*i] == '/'
		    ? OF_XMLPARSER_EXPECT_CLOSE
		    : OF_XMLPARSER_OUTSIDE_TAG);
	} else
		state = OF_XMLPARSER_IN_TAG;

	if (buffer[*i] != '/') {
		OFAutoreleasePool *pool;

		pool = [[OFAutoreleasePool alloc] init];
		[namespaces addObject: [OFMutableDictionary dictionary]];
		[pool release];
	}

	[cache setToCString: ""];
	*last = *i + 1;
}

/* Inside a close tag, no name yet */
- (void)_parseInCloseTagNameWithBuffer: (const char*)buffer
				     i: (size_t*)i
				  last: (size_t*)last
{
	OFAutoreleasePool *pool;
	const char *cacheCString, *tmp;
	size_t length, cacheLength;
	OFString *ns;

	if (buffer[*i] != ' ' && buffer[*i] != '\t' && buffer[*i] != '\n' &&
	    buffer[*i] != '\r' && buffer[*i] != '>')
		return;

	if ((length = *i - *last) > 0)
		cache_append(cache, buffer + *last, encoding, length);

	cacheCString = [cache cString];
	cacheLength = [cache cStringLength];

	if ((tmp = memchr(cacheCString, ':', cacheLength)) != NULL) {
		name = [[OFString alloc] initWithCString: tmp + 1
						  length: cacheLength -
							  (tmp - cacheCString) -
							  1];
		prefix = [[OFString alloc] initWithCString: cacheCString
						    length: tmp - cacheCString];
	} else {
		name = [cache copy];
		prefix = nil;
	}

	if (![[previous lastObject] isEqual: cache])
		@throw [OFMalformedXMLException newWithClass: isa
						      parser: self];

	[previous removeNObjects: 1];

	[cache setToCString: ""];

	ns = namespace_for_prefix(prefix, namespaces);
	if (prefix != nil && ns == nil)
		@throw [OFUnboundNamespaceException newWithClass: isa
							  prefix: prefix];

	pool = [[OFAutoreleasePool alloc] init];

#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
	if (elementEndHandler != NULL)
		elementEndHandler(self, name, prefix, ns);
	else
#endif
		[delegate parser: self
		   didEndElement: name
		      withPrefix: prefix
		       namespace: ns];

	[pool release];

	[namespaces removeNObjects: 1];
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
- (void)_parseInTagWithBuffer: (const char*)buffer
			    i: (size_t*)i
			 last: (size_t*)last
{
	OFAutoreleasePool *pool;
	OFString *ns;
	OFXMLAttribute **attributesCArray;
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

	attributesCArray = [attributes cArray];
	attributesCount = [attributes count];

	ns = namespace_for_prefix(prefix, namespaces);

	if (prefix != nil && ns == nil)
		@throw [OFUnboundNamespaceException newWithClass: isa
							  prefix: prefix];

	for (j = 0; j < attributesCount; j++)
		resolve_attribute_namespace(attributesCArray[j], namespaces,
		    isa);

	pool = [[OFAutoreleasePool alloc] init];

#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
	if (elementStartHandler != NULL)
		elementStartHandler(self, name, prefix, ns, attributes);
	else
#endif
		[delegate parser: self
		 didStartElement: name
		      withPrefix: prefix
		       namespace: ns
		      attributes: attributes];

	if (buffer[*i] == '/') {
#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
		if (elementEndHandler != NULL)
			elementEndHandler(self, name, prefix, ns);
		else
#endif
			[delegate parser: self
			   didEndElement: name
			      withPrefix: prefix
			       namespace: ns];

		[namespaces removeNObjects: 1];
	} else if (prefix != nil) {
		OFString *str = [OFString stringWithFormat: @"%@:%@",
							    prefix, name];
		[previous addObject: str];
	} else
		[previous addObject: name];

	[pool release];

	[name release];
	[prefix release];
	[attributes release];
	name = prefix = nil;
	attributes = nil;

	*last = *i + 1;
	state = (buffer[*i] == '/'
	    ? OF_XMLPARSER_EXPECT_CLOSE
	    : OF_XMLPARSER_OUTSIDE_TAG);
}

/* Looking for attribute name */
- (void)_parseInAttributeNameWithBuffer: (const char*)buffer
				      i: (size_t*)i
				   last: (size_t*)last
{
	const char *cacheCString, *tmp;
	size_t length, cacheLength;

	if (buffer[*i] != '=')
		return;

	if ((length = *i - *last) > 0)
		cache_append(cache, buffer + *last, encoding, length);

	[cache deleteLeadingAndTrailingWhitespaces];

	cacheCString = [cache cString];
	cacheLength = [cache cStringLength];

	if ((tmp = memchr(cacheCString, ':', cacheLength)) != NULL) {
		attributeName = [[OFString alloc]
		    initWithCString: tmp + 1
			     length: cacheLength - (tmp - cacheCString) - 1];
		attributePrefix = [[OFString alloc]
		    initWithCString: cacheCString
			     length: tmp - cacheCString];
	} else {
		attributeName = [cache copy];
		attributePrefix = nil;
	}

	[cache setToCString: ""];

	*last = *i + 1;
	state = OF_XMLPARSER_EXPECT_DELIM;
}

/* Expecting delimiter */
- (void)_parseExpectDelimiterWithBuffer: (const char*)buffer
				      i: (size_t*)i
				   last: (size_t*)last
{
	*last = *i + 1;

	if (buffer[*i] == ' ' || buffer[*i] == '\t' || buffer[*i] == '\n' ||
	    buffer[*i] == '\r')
		return;

	if (buffer[*i] != '\'' && buffer[*i] != '"')
		@throw [OFMalformedXMLException newWithClass: isa
						      parser: self];

	delimiter = buffer[*i];
	state = OF_XMLPARSER_IN_ATTR_VALUE;
}

/* Looking for attribute value */
- (void)_parseInAttributeValueWithBuffer: (const char*)buffer
				       i: (size_t*)i
				    last: (size_t*)last
{
	OFAutoreleasePool *pool;
	OFString *attributeValue;
	size_t length;

	if (buffer[*i] != delimiter)
		return;

	if ((length = *i - *last) > 0)
		cache_append(cache, buffer + *last, encoding, length);

	pool = [[OFAutoreleasePool alloc] init];
	attributeValue = transform_string(cache, 0, YES, self);

	if (attributePrefix == nil && [attributeName isEqual: @"xmlns"])
		[[namespaces lastObject] setObject: attributeValue
					    forKey: @""];
	if ([attributePrefix isEqual: @"xmlns"])
		[[namespaces lastObject] setObject: attributeValue
					    forKey: attributeName];

	if (attributes == nil)
		attributes = [[OFMutableArray alloc] init];

	[attributes addObject:
	    [OFXMLAttribute attributeWithName: attributeName
				    namespace: attributePrefix
				  stringValue: attributeValue]];

	[pool release];

	[cache setToCString: ""];
	[attributeName release];
	[attributePrefix release];
	attributeName = attributePrefix = nil;

	*last = *i + 1;
	state = OF_XMLPARSER_IN_TAG;
}

/* Expecting closing '>' */
- (void)_parseExpectCloseWithBuffer: (const char*)buffer
				  i: (size_t*)i
			       last: (size_t*)last
{
	if (buffer[*i] == '>') {
		*last = *i + 1;
		state = OF_XMLPARSER_OUTSIDE_TAG;
	} else
		@throw [OFMalformedXMLException newWithClass: isa
						      parser: self];
}

/* Expecting closing '>' or space */
- (void)_parseExpectSpaceOrCloseWithBuffer: (const char*)buffer
					 i: (size_t*)i
				      last: (size_t*)last
{
	if (buffer[*i] == '>') {
		*last = *i + 1;
		state = OF_XMLPARSER_OUTSIDE_TAG;
	} else if (buffer[*i] != ' ' && buffer[*i] != '\t' &&
	    buffer[*i] != '\n' && buffer[*i] != '\r')
		@throw [OFMalformedXMLException newWithClass: isa
						      parser: self];
}

/* In <! */
- (void)_parseInExclamationMarkWithBuffer: (const char*)buffer
					i: (size_t*)i
				     last: (size_t*)last
{
	if (finishedParsing && buffer[*i] != '-')
		@throw [OFMalformedXMLException newWithClass: isa
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
		@throw [OFMalformedXMLException newWithClass: isa
						      parser: self];

	*last = *i + 1;
}

/* CDATA */
- (void)_parseInCDATAOpeningWithBuffer: (const char*)buffer
				     i: (size_t*)i
				  last: (size_t*)last
{
	if (buffer[*i] != "CDATA["[level])
		@throw [OFMalformedXMLException newWithClass: isa
						      parser: self];

	if (++level == 6) {
		state = OF_XMLPARSER_IN_CDATA_1;
		level = 0;
	}

	*last = *i + 1;
}

- (void)_parseInCDATA1WithBuffer: (const char*)buffer
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

- (void)_parseInCDATA2WithBuffer: (const char*)buffer
			       i: (size_t*)i
			    last: (size_t*)last
{
	OFAutoreleasePool *pool;
	OFString *CDATA;

	if (buffer[*i] != '>') {
		state = OF_XMLPARSER_IN_CDATA_1;
		level = (buffer[*i] == ']' ? 1 : 0);

		return;
	}

	pool = [[OFAutoreleasePool alloc] init];

	cache_append(cache, buffer + *last, encoding, *i - *last);
	CDATA = transform_string(cache, 2, NO, nil);

#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
	if (CDATAHandler != NULL)
		CDATAHandler(self, CDATA);
	else
#endif
		[delegate parser: self
		      foundCDATA: CDATA];

	[pool release];

	[cache setToCString: ""];

	*last = *i + 1;
	state = OF_XMLPARSER_OUTSIDE_TAG;
}

/* Comment */
- (void)_parseInCommentOpeningWithBuffer: (const char*)buffer
				       i: (size_t*)i
				    last: (size_t*)last
{
	if (buffer[*i] != '-')
		@throw [OFMalformedXMLException newWithClass: isa
						      parser: self];

	*last = *i + 1;
	state = OF_XMLPARSER_IN_COMMENT_1;
	level = 0;
}

- (void)_parseInComment1WithBuffer: (const char*)buffer
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

- (void)_parseInComment2WithBuffer: (const char*)buffer
				 i: (size_t*)i
			      last: (size_t*)last
{
	OFAutoreleasePool *pool;
	OFString *comment;

	if (buffer[*i] != '>')
		@throw [OFMalformedXMLException newWithClass: isa
						      parser: self];

	pool = [[OFAutoreleasePool alloc] init];

	cache_append(cache, buffer + *last, encoding, *i - *last);
	comment = transform_string(cache, 2, NO, nil);

#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
	if (commentHandler != NULL)
		commentHandler(self, comment);
	else
#endif
		[delegate parser: self
		    foundComment: comment];

	[pool release];

	[cache setToCString: ""];

	*last = *i + 1;
	state = OF_XMLPARSER_OUTSIDE_TAG;
}

/* In <!DOCTYPE ...> */
- (void)_parseInDoctypeWithBuffer: (const char*)buffer
				i: (size_t*)i
			     last: (size_t*)last
{
	if ((level < 6 && buffer[*i] != "OCTYPE"[level]) ||
	    (level == 6 && buffer[*i] != ' ' && buffer[*i] != '\t' &&
	    buffer[*i] != '\n' && buffer[*i] != '\r'))
		@throw [OFMalformedXMLException newWithClass: isa
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
#if defined(OF_HAVE_PROPERTIES) && defined(OF_HAVE_BLOCKS)
	if (unknownEntityHandler != NULL)
		return unknownEntityHandler(self, entity);
#endif

	return [delegate parser: self
	foundUnknownEntityNamed: entity];
}
@end

@implementation OFObject (OFXMLParserDelegate)
-		 (void)parser: (OFXMLParser*)parser
  foundProcessingInstructions: (OFString*)pi
{
}

-    (void)parser: (OFXMLParser*)parser
  didStartElement: (OFString*)name
       withPrefix: (OFString*)prefix
	namespace: (OFString*)ns
       attributes: (OFArray*)attributes
{
}

-  (void)parser: (OFXMLParser*)parser
  didEndElement: (OFString*)name
     withPrefix: (OFString*)prefix
      namespace: (OFString*)ns
{
}

-    (void)parser: (OFXMLParser*)parser
  foundCharacters: (OFString*)characters
{
}

- (void)parser: (OFXMLParser*)parser
    foundCDATA: (OFString*)CDATA
{
}

- (void)parser: (OFXMLParser*)parser
  foundComment: (OFString*)comment
{
}

-	(OFString*)parser: (OFXMLParser*)parser
  foundUnknownEntityNamed: (OFString*)entity
{
	return nil;
}
@end
