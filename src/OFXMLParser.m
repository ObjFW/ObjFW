/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFXMLParser.h"
#import "OFArray.h"
#import "OFCharacterSet.h"
#import "OFData.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
#endif
#import "OFStream.h"
#import "OFString.h"
#import "OFSystemInfo.h"
#import "OFXMLAttribute.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFMalformedXMLException.h"
#import "OFOutOfRangeException.h"
#import "OFUnboundPrefixException.h"

enum {
	stateInByteOrderMark,
	stateOutsideTag,
	stateTagOpened,
	stateInProcessingInstruction,
	stateInTagName,
	stateInCloseTagName,
	stateInTag,
	stateInAttributeName,
	stateExpectAttributeEqualSign,
	stateExpectAttributeDelimiter,
	stateInAttributeValue,
	stateExpectTagClose,
	stateExpectSpaceOrTagClose,
	stateInExclamationMark,
	stateInCDATAOpening,
	stateInCDATA,
	stateInCommentOpening,
	stateInComment1,
	stateInComment2,
	stateInDOCTYPE
};

@interface OFXMLParser () <OFStringXMLUnescapingDelegate>
@end

static void inByteOrderMarkState(OFXMLParser *);
static void outsideTagState(OFXMLParser *);
static void tagOpenedState(OFXMLParser *);
static void inProcessingInstructionState(OFXMLParser *);
static void inTagNameState(OFXMLParser *);
static void inCloseTagNameState(OFXMLParser *);
static void inTagState(OFXMLParser *);
static void inAttributeNameState(OFXMLParser *);
static void expectAttributeEqualSignState(OFXMLParser *);
static void expectAttributeDelimiterState(OFXMLParser *);
static void inAttributeValueState(OFXMLParser *);
static void expectTagCloseState(OFXMLParser *);
static void expectSpaceOrTagCloseState(OFXMLParser *);
static void inExclamationMarkState(OFXMLParser *);
static void inCDATAOpeningState(OFXMLParser *);
static void inCDATAState(OFXMLParser *);
static void inCommentOpeningState(OFXMLParser *);
static void inCommentState1(OFXMLParser *);
static void inCommentState2(OFXMLParser *);
static void inDOCTYPEState(OFXMLParser *);
typedef void (*StateFunction)(OFXMLParser *);
static StateFunction lookupTable[] = {
	[stateInByteOrderMark] = inByteOrderMarkState,
	[stateOutsideTag] = outsideTagState,
	[stateTagOpened] = tagOpenedState,
	[stateInProcessingInstruction] = inProcessingInstructionState,
	[stateInTagName] = inTagNameState,
	[stateInCloseTagName] = inCloseTagNameState,
	[stateInTag] = inTagState,
	[stateInAttributeName] = inAttributeNameState,
	[stateExpectAttributeEqualSign] = expectAttributeEqualSignState,
	[stateExpectAttributeDelimiter] = expectAttributeDelimiterState,
	[stateInAttributeValue] = inAttributeValueState,
	[stateExpectTagClose] = expectTagCloseState,
	[stateExpectSpaceOrTagClose] = expectSpaceOrTagCloseState,
	[stateInExclamationMark] = inExclamationMarkState,
	[stateInCDATAOpening] = inCDATAOpeningState,
	[stateInCDATA] = inCDATAState,
	[stateInCommentOpening] = inCommentOpeningState,
	[stateInComment1] = inCommentState1,
	[stateInComment2] = inCommentState2,
	[stateInDOCTYPE] = inDOCTYPEState
};

static OF_INLINE void
appendToBuffer(OFMutableData *buffer, const char *string,
    OFStringEncoding encoding, size_t length)
{
	if OF_LIKELY (encoding == OFStringEncodingUTF8)
		[buffer addItems: string count: length];
	else {
		void *pool = objc_autoreleasePoolPush();
		OFString *tmp = [OFString stringWithCString: string
						   encoding: encoding
						     length: length];
		[buffer addItems: tmp.UTF8String count: tmp.UTF8StringLength];
		objc_autoreleasePoolPop(pool);
	}
}

static OFString *
transformString(OFXMLParser *parser, OFMutableData *buffer, size_t cut,
    bool unescape)
{
	char *items = buffer.mutableItems;
	size_t length = buffer.count - cut;
	bool hasEntities = false;
	OFString *ret;

	for (size_t i = 0; i < length; i++) {
		if (items[i] == '\r') {
			if (i + 1 < length && items[i + 1] == '\n') {
				[buffer removeItemAtIndex: i];
				items = buffer.mutableItems;

				i--;
				length--;
			} else
				items[i] = '\n';
		} else if (items[i] == '&')
			hasEntities = true;
	}

	ret = [OFString stringWithUTF8String: items length: length];

	if (unescape && hasEntities) {
		@try {
			return [ret stringByXMLUnescapingWithDelegate: parser];
		} @catch (OFInvalidFormatException *e) {
			@throw [OFMalformedXMLException
			    exceptionWithParser: parser];
		}
	}

	return ret;
}

static OFString *
namespaceForPrefix(OFString *prefix, OFArray *namespaces)
{
	OFDictionary *const *objects = namespaces.objects;
	size_t count = namespaces.count;

	if (prefix == nil)
		prefix = @"";

	while (count > 0) {
		OFString *tmp;

		if ((tmp = [objects[--count] objectForKey: prefix]) != nil)
			return tmp;
	}

	return nil;
}

static OF_INLINE void
resolveAttributeNamespace(OFXMLAttribute *attribute, OFArray *namespaces,
    OFXMLParser *self)
{
	OFString *attributeNS;
	OFString *attributePrefix = attribute->_namespace;

	if (attributePrefix == nil)
		return;

	attributeNS = namespaceForPrefix(attributePrefix, namespaces);

	if ((attributePrefix != nil && attributeNS == nil))
		@throw [OFUnboundPrefixException
		    exceptionWithPrefix: attributePrefix
				 parser: self];

	[attribute->_namespace release];
	attribute->_namespace = [attributeNS retain];
}

@implementation OFXMLParser
@synthesize delegate = _delegate, depthLimit = _depthLimit;

+ (instancetype)parser
{
	return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
	self = [super init];

	@try {
		void *pool;
		OFMutableDictionary *dict;

		_buffer = [[OFMutableData alloc] init];
		_previous = [[OFMutableArray alloc] init];
		_namespaces = [[OFMutableArray alloc] init];
		_attributes = [[OFMutableArray alloc] init];

		pool = objc_autoreleasePoolPush();
		dict = [OFMutableDictionary dictionaryWithKeysAndObjects:
		    @"xml", @"http://www.w3.org/XML/1998/namespace",
		    @"xmlns", @"http://www.w3.org/2000/xmlns/", nil];
		[_namespaces addObject: dict];

		_acceptProlog = true;
		_lineNumber = 1;
		_encoding = OFStringEncodingUTF8;
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
	[_buffer release];
	[_name release];
	[_prefix release];
	[_namespaces release];
	[_attributes release];
	[_attributeName release];
	[_attributePrefix release];
	[_previous release];

	[super dealloc];
}

- (void)parseBuffer: (const char *)buffer length: (size_t)length
{
	_data = buffer;

	for (_i = _last = 0; _i < length; _i++) {
		size_t j = _i;

		lookupTable[_state](self);

		/* Ensure we don't count this character twice */
		if (_i != j)
			continue;

		if (_data[_i] == '\r' || (_data[_i] == '\n' &&
		    !_lastCarriageReturn))
			_lineNumber++;

		_lastCarriageReturn = (_data[_i] == '\r');
	}

	/* In stateInTag, there can be only spaces */
	if (length - _last > 0 && _state != stateInTag)
		appendToBuffer(_buffer, _data + _last, _encoding,
		    length - _last);
}

- (void)parseString: (OFString *)string
{
	[self parseBuffer: string.UTF8String length: string.UTF8StringLength];
}

- (void)parseStream: (OFStream *)stream
{
	size_t pageSize = [OFSystemInfo pageSize];
	char *buffer = OFAllocMemory(1, pageSize);

	@try {
		while (!stream.atEndOfStream) {
			size_t length = [stream readIntoBuffer: buffer
							length: pageSize];
			[self parseBuffer: buffer length: length];
		}
	} @finally {
		OFFreeMemory(buffer);
	}
}

static void
inByteOrderMarkState(OFXMLParser *self)
{
	if (self->_data[self->_i] != "\xEF\xBB\xBF"[self->_level]) {
		if (self->_level == 0) {
			self->_state = stateOutsideTag;
			self->_i--;
			return;
		}

		@throw [OFMalformedXMLException exceptionWithParser: self];
	}

	if (self->_level++ == 2)
		self->_state = stateOutsideTag;

	self->_last = self->_i + 1;
}

/* Not in a tag */
static void
outsideTagState(OFXMLParser *self)
{
	size_t length;

	if ((self->_finishedParsing || self->_previous.count < 1) &&
	    self->_data[self->_i] != ' '  && self->_data[self->_i] != '\t' &&
	    self->_data[self->_i] != '\n' && self->_data[self->_i] != '\r' &&
	    self->_data[self->_i] != '<')
		@throw [OFMalformedXMLException exceptionWithParser: self];

	if (self->_data[self->_i] != '<')
		return;

	if ((length = self->_i - self->_last) > 0)
		appendToBuffer(self->_buffer, self->_data + self->_last,
		    self->_encoding, length);

	if (self->_buffer.count > 0) {
		void *pool = objc_autoreleasePoolPush();
		OFString *characters = transformString(self, self->_buffer, 0,
		    true);

		if ([self->_delegate respondsToSelector:
		    @selector(parser:foundCharacters:)])
			[self->_delegate parser: self
				foundCharacters: characters];

		objc_autoreleasePoolPop(pool);
	}

	[self->_buffer removeAllItems];

	self->_last = self->_i + 1;
	self->_state = stateTagOpened;
}

/* Tag was just opened */
static void
tagOpenedState(OFXMLParser *self)
{
	if (self->_finishedParsing && self->_data[self->_i] != '!' &&
	    self->_data[self->_i] != '?')
		@throw [OFMalformedXMLException exceptionWithParser: self];

	switch (self->_data[self->_i]) {
	case '?':
		self->_last = self->_i + 1;
		self->_state = stateInProcessingInstruction;
		self->_level = 0;
		break;
	case '/':
		self->_last = self->_i + 1;
		self->_state = stateInCloseTagName;
		self->_acceptProlog = false;
		break;
	case '!':
		self->_last = self->_i + 1;
		self->_state = stateInExclamationMark;
		self->_acceptProlog = false;
		break;
	default:
		if (self->_depthLimit > 0 &&
		    self->_previous.count >= self->_depthLimit)
			@throw [OFOutOfRangeException exception];

		self->_state = stateInTagName;
		self->_acceptProlog = false;
		self->_i--;
		break;
	}
}

/* <?xml […]?> */
static bool
parseXMLProcessingInstruction(OFXMLParser *self, OFString *data)
{
	const char *cString;
	size_t length, last;
	int PIState = 0;
	OFString *attribute = nil;
	OFMutableString *value = nil;
	char piDelimiter = 0;
	bool hasVersion = false;

	if (!self->_acceptProlog)
		return false;

	self->_acceptProlog = false;

	cString = data.UTF8String;
	length = data.UTF8StringLength;

	last = 0;
	for (size_t i = 0; i < length; i++) {
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
			    stringWithCString: cString + last
				     encoding: self->_encoding
				       length: i - last];
			last = i + 1;
			PIState = 2;

			break;
		case 2:
			if (cString[i] != '\'' && cString[i] != '"')
				return false;

			piDelimiter = cString[i];
			last = i + 1;
			PIState = 3;

			break;
		case 3:
			if (cString[i] != piDelimiter)
				continue;

			value = [OFMutableString
			    stringWithCString: cString + last
				     encoding: self->_encoding
				       length: i - last];

			if ([attribute isEqual: @"version"]) {
				if (![value hasPrefix: @"1."])
					return false;

				hasVersion = true;
			}

			if ([attribute isEqual: @"encoding"]) {
				@try {
					self->_encoding =
					    OFStringEncodingParseName(value);
				} @catch (OFInvalidArgumentException *e) {
					@throw [OFInvalidEncodingException
					    exception];
				}
			}

			last = i + 1;
			PIState = 0;

			break;
		}
	}

	if (PIState != 0 || !hasVersion)
		return false;

	return true;
}

/* Inside processing instruction */
static void
inProcessingInstructionState(OFXMLParser *self)
{
	if (self->_data[self->_i] == '?')
		self->_level = 1;
	else if (self->_level == 1 && self->_data[self->_i] == '>') {
		void *pool = objc_autoreleasePoolPush();
		OFString *PI, *target, *text = nil;
		OFCharacterSet *whitespaceCS;
		size_t pos;

		appendToBuffer(self->_buffer, self->_data + self->_last,
		    self->_encoding, self->_i - self->_last);
		PI = transformString(self, self->_buffer, 1, false);

		whitespaceCS = [OFCharacterSet
		    characterSetWithCharactersInString: @" \r\n\r"];
		pos = [PI indexOfCharacterFromSet: whitespaceCS];
		if (pos != OFNotFound) {
			target = [PI substringToIndex: pos];
			text = [[PI substringFromIndex: pos + 1]
			    stringByDeletingEnclosingWhitespaces];

			if (text.length == 0)
				text = nil;
		} else
			target = PI;

		if ([target caseInsensitiveCompare: @"xml"] == OFOrderedSame)
			if (!parseXMLProcessingInstruction(self, text))
				@throw [OFMalformedXMLException
				    exceptionWithParser: self];

		if ([self->_delegate respondsToSelector: @selector(
		    parser:foundProcessingInstructionWithTarget:text:)])
			[self->_delegate parser: self
			    foundProcessingInstructionWithTarget: target
							    text: text];

		objc_autoreleasePoolPop(pool);

		[self->_buffer removeAllItems];

		self->_last = self->_i + 1;
		self->_state = stateOutsideTag;
	} else
		self->_level = 0;
}

/* Inside a tag, no name yet */
static void
inTagNameState(OFXMLParser *self)
{
	void *pool;
	const char *bufferCString, *tmp;
	size_t length, bufferLength;
	OFString *bufferString;

	if (self->_data[self->_i] != ' '  && self->_data[self->_i] != '\t' &&
	    self->_data[self->_i] != '\n' && self->_data[self->_i] != '\r' &&
	    self->_data[self->_i] != '>'  && self->_data[self->_i] != '/')
		return;

	if ((length = self->_i - self->_last) > 0)
		appendToBuffer(self->_buffer, self->_data + self->_last,
		    self->_encoding, length);

	pool = objc_autoreleasePoolPush();

	bufferCString = self->_buffer.items;
	bufferLength = self->_buffer.count;
	bufferString = [OFString stringWithUTF8String: bufferCString
					       length: bufferLength];

	if ((tmp = memchr(bufferCString, ':', bufferLength)) != NULL) {
		self->_name = [[OFString alloc]
		    initWithUTF8String: tmp + 1
				length: bufferLength -
					(tmp - bufferCString) - 1];
		self->_prefix = [[OFString alloc]
		    initWithUTF8String: bufferCString
				length: tmp - bufferCString];
	} else {
		self->_name = [bufferString copy];
		self->_prefix = nil;
	}

	if (self->_data[self->_i] == '>' || self->_data[self->_i] == '/') {
		OFString *namespace = namespaceForPrefix(self->_prefix,
		    self->_namespaces);

		if (self->_prefix != nil && namespace == nil)
			@throw [OFUnboundPrefixException
			    exceptionWithPrefix: self->_prefix
					 parser: self];

		if ([self->_delegate respondsToSelector: @selector(parser:
		    didStartElement:prefix:namespace:attributes:)])
			[self->_delegate parser: self
				didStartElement: self->_name
					 prefix: self->_prefix
				      namespace: namespace
				     attributes: nil];

		if (self->_data[self->_i] == '/') {
			if ([self->_delegate respondsToSelector:
			    @selector(parser:didEndElement:prefix:namespace:)])
				[self->_delegate parser: self
					  didEndElement: self->_name
						 prefix: self->_prefix
					      namespace: namespace];

			if (self->_previous.count == 0)
				self->_finishedParsing = true;
		} else
			[self->_previous addObject: bufferString];

		[self->_name release];
		[self->_prefix release];
		self->_name = self->_prefix = nil;

		self->_state = (self->_data[self->_i] == '/'
		    ? stateExpectTagClose : stateOutsideTag);
	} else
		self->_state = stateInTag;

	if (self->_data[self->_i] != '/')
		[self->_namespaces addObject: [OFMutableDictionary dictionary]];

	objc_autoreleasePoolPop(pool);

	[self->_buffer removeAllItems];
	self->_last = self->_i + 1;
}

/* Inside a close tag, no name yet */
static void
inCloseTagNameState(OFXMLParser *self)
{
	void *pool;
	const char *bufferCString, *tmp;
	size_t length, bufferLength;
	OFString *bufferString, *namespace;

	if (self->_data[self->_i] != ' '  && self->_data[self->_i] != '\t' &&
	    self->_data[self->_i] != '\n' && self->_data[self->_i] != '\r' &&
	    self->_data[self->_i] != '>')
		return;

	if ((length = self->_i - self->_last) > 0)
		appendToBuffer(self->_buffer, self->_data + self->_last,
		    self->_encoding, length);

	pool = objc_autoreleasePoolPush();

	bufferCString = self->_buffer.items;
	bufferLength = self->_buffer.count;
	bufferString = [OFString stringWithUTF8String: bufferCString
					       length: bufferLength];

	if ((tmp = memchr(bufferCString, ':', bufferLength)) != NULL) {
		self->_name = [[OFString alloc]
		    initWithUTF8String: tmp + 1
				length: bufferLength -
					(tmp - bufferCString) - 1];
		self->_prefix = [[OFString alloc]
		    initWithUTF8String: bufferCString
				length: tmp - bufferCString];
	} else {
		self->_name = [bufferString copy];
		self->_prefix = nil;
	}

	if (![self->_previous.lastObject isEqual: bufferString])
		@throw [OFMalformedXMLException exceptionWithParser: self];

	[self->_previous removeLastObject];

	[self->_buffer removeAllItems];

	namespace = namespaceForPrefix(self->_prefix, self->_namespaces);
	if (self->_prefix != nil && namespace == nil)
		@throw [OFUnboundPrefixException
		    exceptionWithPrefix: self->_prefix
				 parser: self];

	if ([self->_delegate respondsToSelector:
	    @selector(parser:didEndElement:prefix:namespace:)])
		[self->_delegate parser: self
			  didEndElement: self->_name
				 prefix: self->_prefix
			      namespace: namespace];

	objc_autoreleasePoolPop(pool);

	[self->_namespaces removeLastObject];
	[self->_name release];
	[self->_prefix release];
	self->_name = self->_prefix = nil;

	self->_last = self->_i + 1;
	self->_state = (self->_data[self->_i] == '>'
	    ? stateOutsideTag : stateExpectSpaceOrTagClose);

	if (self->_previous.count == 0)
		self->_finishedParsing = true;
}

/* Inside a tag, name found */
static void
inTagState(OFXMLParser *self)
{
	void *pool;
	OFString *namespace;
	OFXMLAttribute *const *attributesObjects;
	size_t attributesCount;

	if (self->_data[self->_i] != '>' && self->_data[self->_i] != '/') {
		if (self->_data[self->_i] != ' ' &&
		    self->_data[self->_i] != '\t' &&
		    self->_data[self->_i] != '\n' &&
		    self->_data[self->_i] != '\r') {
			self->_last = self->_i;
			self->_state = stateInAttributeName;
			self->_i--;
		}

		return;
	}

	attributesObjects = self->_attributes.objects;
	attributesCount = self->_attributes.count;

	namespace = namespaceForPrefix(self->_prefix, self->_namespaces);

	if (self->_prefix != nil && namespace == nil)
		@throw [OFUnboundPrefixException
		    exceptionWithPrefix: self->_prefix
				 parser: self];

	for (size_t j = 0; j < attributesCount; j++)
		resolveAttributeNamespace(attributesObjects[j],
		    self->_namespaces, self);

	pool = objc_autoreleasePoolPush();

	if ([self->_delegate respondsToSelector:
	    @selector(parser:didStartElement:prefix:namespace:attributes:)])
		[self->_delegate parser: self
			didStartElement: self->_name
				 prefix: self->_prefix
			      namespace: namespace
			     attributes: self->_attributes];

	if (self->_data[self->_i] == '/') {
		if ([self->_delegate respondsToSelector:
		    @selector(parser:didEndElement:prefix:namespace:)])
			[self->_delegate parser: self
				  didEndElement: self->_name
					 prefix: self->_prefix
				      namespace: namespace];

		if (self->_previous.count == 0)
			self->_finishedParsing = true;

		[self->_namespaces removeLastObject];
	} else if (self->_prefix != nil) {
		OFString *str = [OFString stringWithFormat:
		    @"%@:%@", self->_prefix, self->_name];
		[self->_previous addObject: str];
	} else
		[self->_previous addObject: self->_name];

	objc_autoreleasePoolPop(pool);

	[self->_name release];
	[self->_prefix release];
	[self->_attributes removeAllObjects];
	self->_name = self->_prefix = nil;

	self->_last = self->_i + 1;
	self->_state = (self->_data[self->_i] == '/'
	    ? stateExpectTagClose : stateOutsideTag);
}

/* Looking for attribute name */
static void
inAttributeNameState(OFXMLParser *self)
{
	void *pool;
	OFString *bufferString;
	const char *bufferCString, *tmp;
	size_t length, bufferLength;

	if (self->_data[self->_i] != '='  && self->_data[self->_i] != ' '  &&
	    self->_data[self->_i] != '\t' && self->_data[self->_i] != '\n' &&
	    self->_data[self->_i] != '\r')
		return;

	if ((length = self->_i - self->_last) > 0)
		appendToBuffer(self->_buffer, self->_data + self->_last,
		    self->_encoding, length);

	pool = objc_autoreleasePoolPush();

	bufferString = [OFString stringWithUTF8String: self->_buffer.items
					       length: self->_buffer.count];

	bufferCString = bufferString.UTF8String;
	bufferLength = bufferString.UTF8StringLength;

	if ((tmp = memchr(bufferCString, ':', bufferLength)) != NULL) {
		self->_attributeName = [[OFString alloc]
		    initWithUTF8String: tmp + 1
				length: bufferLength -
					(tmp - bufferCString) - 1];
		self->_attributePrefix = [[OFString alloc]
		    initWithUTF8String: bufferCString
				length: tmp - bufferCString];
	} else {
		self->_attributeName = [bufferString copy];
		self->_attributePrefix = nil;
	}

	objc_autoreleasePoolPop(pool);

	[self->_buffer removeAllItems];

	self->_last = self->_i + 1;
	self->_state = (self->_data[self->_i] == '='
	    ? stateExpectAttributeDelimiter : stateExpectAttributeEqualSign);
}

/* Expecting equal sign of an attribute */
static void
expectAttributeEqualSignState(OFXMLParser *self)
{
	if (self->_data[self->_i] == '=') {
		self->_last = self->_i + 1;
		self->_state = stateExpectAttributeDelimiter;
		return;
	}

	if (self->_data[self->_i] != ' '  && self->_data[self->_i] != '\t' &&
	    self->_data[self->_i] != '\n' && self->_data[self->_i] != '\r')
		@throw [OFMalformedXMLException exceptionWithParser: self];
}

/* Expecting name/value delimiter of an attribute */
static void
expectAttributeDelimiterState(OFXMLParser *self)
{
	self->_last = self->_i + 1;

	if (self->_data[self->_i] == ' '  || self->_data[self->_i] == '\t' ||
	    self->_data[self->_i] == '\n' || self->_data[self->_i] == '\r')
		return;

	if (self->_data[self->_i] != '\'' && self->_data[self->_i] != '"')
		@throw [OFMalformedXMLException exceptionWithParser: self];

	self->_delimiter = self->_data[self->_i];
	self->_state = stateInAttributeValue;
}

/* Looking for attribute value */
static void
inAttributeValueState(OFXMLParser *self)
{
	void *pool;
	OFString *attributeValue;
	size_t length;
	OFXMLAttribute *attribute;

	if (self->_data[self->_i] != self->_delimiter)
		return;

	if ((length = self->_i - self->_last) > 0)
		appendToBuffer(self->_buffer, self->_data + self->_last,
		    self->_encoding, length);

	pool = objc_autoreleasePoolPush();
	attributeValue = transformString(self, self->_buffer, 0, true);

	if (self->_attributePrefix == nil &&
	    [self->_attributeName isEqual: @"xmlns"])
		[self->_namespaces.lastObject setObject: attributeValue
						 forKey: @""];
	if ([self->_attributePrefix isEqual: @"xmlns"])
		[self->_namespaces.lastObject setObject: attributeValue
						 forKey: self->_attributeName];

	attribute = [OFXMLAttribute attributeWithName: self->_attributeName
					    namespace: self->_attributePrefix
					  stringValue: attributeValue];
	attribute->_useDoubleQuotes = (self->_delimiter == '"');
	[self->_attributes addObject: attribute];

	objc_autoreleasePoolPop(pool);

	[self->_buffer removeAllItems];
	[self->_attributeName release];
	[self->_attributePrefix release];
	self->_attributeName = self->_attributePrefix = nil;

	self->_last = self->_i + 1;
	self->_state = stateInTag;
}

/* Expecting closing '>' */
static void
expectTagCloseState(OFXMLParser *self)
{
	if (self->_data[self->_i] == '>') {
		self->_last = self->_i + 1;
		self->_state = stateOutsideTag;
	} else
		@throw [OFMalformedXMLException exceptionWithParser: self];
}

/* Expecting closing '>' or space */
static void
expectSpaceOrTagCloseState(OFXMLParser *self)
{
	if (self->_data[self->_i] == '>') {
		self->_last = self->_i + 1;
		self->_state = stateOutsideTag;
	} else if (self->_data[self->_i] != ' ' &&
	    self->_data[self->_i] != '\t' && self->_data[self->_i] != '\n' &&
	    self->_data[self->_i] != '\r')
		@throw [OFMalformedXMLException exceptionWithParser: self];
}

/* In <! */
static void
inExclamationMarkState(OFXMLParser *self)
{
	if (self->_finishedParsing && self->_data[self->_i] != '-')
		@throw [OFMalformedXMLException exceptionWithParser: self];

	if (self->_data[self->_i] == '-')
		self->_state = stateInCommentOpening;
	else if (self->_data[self->_i] == '[') {
		self->_state = stateInCDATAOpening;
		self->_level = 0;
	} else if (self->_data[self->_i] == 'D') {
		self->_state = stateInDOCTYPE;
		self->_level = 0;
	} else
		@throw [OFMalformedXMLException exceptionWithParser: self];

	self->_last = self->_i + 1;
}

/* CDATA */
static void
inCDATAOpeningState(OFXMLParser *self)
{
	if (self->_data[self->_i] != "CDATA["[self->_level])
		@throw [OFMalformedXMLException exceptionWithParser: self];

	if (++self->_level == 6) {
		self->_state = stateInCDATA;
		self->_level = 0;
	}

	self->_last = self->_i + 1;
}

static void
inCDATAState(OFXMLParser *self)
{
	if (self->_data[self->_i] == ']')
		self->_level++;
	else if (self->_data[self->_i] == '>' && self->_level >= 2) {
		void *pool = objc_autoreleasePoolPush();
		OFString *CDATA;

		appendToBuffer(self->_buffer, self->_data + self->_last,
		    self->_encoding, self->_i - self->_last);
		CDATA = transformString(self, self->_buffer, 2, false);

		if ([self->_delegate respondsToSelector:
		    @selector(parser:foundCDATA:)])
			[self->_delegate parser: self foundCDATA: CDATA];

		objc_autoreleasePoolPop(pool);

		[self->_buffer removeAllItems];

		self->_last = self->_i + 1;
		self->_state = stateOutsideTag;
	} else
		self->_level = 0;
}

/* Comment */
static void
inCommentOpeningState(OFXMLParser *self)
{
	if (self->_data[self->_i] != '-')
		@throw [OFMalformedXMLException exceptionWithParser: self];

	self->_last = self->_i + 1;
	self->_state = stateInComment1;
	self->_level = 0;
}

static void
inCommentState1(OFXMLParser *self)
{
	if (self->_data[self->_i] == '-')
		self->_level++;
	else
		self->_level = 0;

	if (self->_level == 2)
		self->_state = stateInComment2;
}

static void
inCommentState2(OFXMLParser *self)
{
	void *pool;
	OFString *comment;

	if (self->_data[self->_i] != '>')
		@throw [OFMalformedXMLException exceptionWithParser: self];

	pool = objc_autoreleasePoolPush();

	appendToBuffer(self->_buffer, self->_data + self->_last,
	    self->_encoding, self->_i - self->_last);
	comment = transformString(self, self->_buffer, 2, false);

	if ([self->_delegate respondsToSelector:
	    @selector(parser:foundComment:)])
		[self->_delegate parser: self foundComment: comment];

	objc_autoreleasePoolPop(pool);

	[self->_buffer removeAllItems];

	self->_last = self->_i + 1;
	self->_state = stateOutsideTag;
}

/* In <!DOCTYPE ...> */
static void
inDOCTYPEState(OFXMLParser *self)
{
	if ((self->_level < 6 &&
	    self->_data[self->_i] != "OCTYPE"[self->_level]) ||
	    (self->_level == 6 && self->_data[self->_i] != ' ' &&
	    self->_data[self->_i] != '\t' && self->_data[self->_i] != '\n' &&
	    self->_data[self->_i] != '\r'))
		@throw [OFMalformedXMLException exceptionWithParser: self];

	self->_level++;

	if (self->_level > 6 && self->_data[self->_i] == '>')
		self->_state = stateOutsideTag;

	self->_last = self->_i + 1;
}

- (size_t)lineNumber
{
	return _lineNumber;
}

- (bool)hasFinishedParsing
{
	return _finishedParsing;
}

-	  (OFString *)string: (OFString *)string
  containsUnknownEntityNamed: (OFString *)entity
{
	if ([_delegate respondsToSelector:
	    @selector(parser:foundUnknownEntityNamed:)])
		return [_delegate parser: self foundUnknownEntityNamed: entity];

	return nil;
}
@end
