/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#include <string.h>

#include <sys/types.h>

#import "OFXMLParser.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OFBigDataArray.h"
#import "OFXMLAttribute.h"
#import "OFStream.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
#endif
#import "OFSystemInfo.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidFormatException.h"
#import "OFMalformedXMLException.h"
#import "OFOutOfRangeException.h"
#import "OFUnboundPrefixException.h"

typedef void (*state_function_t)(id, SEL);
static SEL selectors[OF_XMLPARSER_NUM_STATES];
static state_function_t lookupTable[OF_XMLPARSER_NUM_STATES];

static OF_INLINE void
appendToBuffer(OFDataArray *buffer, const char *string,
    of_string_encoding_t encoding, size_t length)
{
	if (OF_LIKELY(encoding == OF_STRING_ENCODING_UTF_8))
		[buffer addItems: string
			   count: length];
	else {
		void *pool = objc_autoreleasePoolPush();
		OFString *tmp = [OFString stringWithCString: string
						   encoding: encoding
						     length: length];
		[buffer addItems: [tmp UTF8String]
			   count: [tmp UTF8StringLength]];
		objc_autoreleasePoolPop(pool);
	}
}

static OFString*
transformString(OFXMLParser *parser, OFDataArray *buffer, size_t cut,
    bool unescape)
{
	char *items = [buffer items];
	size_t length = [buffer count] - cut;
	bool hasEntities = false;
	OFString *ret;

	for (size_t i = 0; i < length; i++) {
		if (items[i] == '\r') {
			if (i + 1 < length && items[i + 1] == '\n') {
				[buffer removeItemAtIndex: i];
				items = [buffer items];

				i--;
				length--;
			} else
				items[i] = '\n';
		} else if (items[i] == '&')
			hasEntities = true;
	}

	ret = [OFString stringWithUTF8String: items
				      length: length];

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

static OFString*
namespaceForPrefix(OFString *prefix, OFArray *namespaces)
{
	OFDictionary *const *objects = [namespaces objects];
	size_t count = [namespaces count];

	if (prefix == nil)
		prefix = @"";

	if (count - 1 > SSIZE_MAX)
		@throw [OFOutOfRangeException exception];

	for (ssize_t i = count - 1; i >= 0; i--) {
		OFString *tmp;

		if ((tmp = [objects[i] objectForKey: prefix]) != nil)
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

+ (void)initialize
{
	const SEL selectors_[OF_XMLPARSER_NUM_STATES] = {
		@selector(OF_inByteOrderMarkState),
		@selector(OF_outsideTagState),
		@selector(OF_tagOpenedState),
		@selector(OF_inProcessingInstructionsState),
		@selector(OF_inTagNameState),
		@selector(OF_inCloseTagNameState),
		@selector(OF_inTagState),
		@selector(OF_inAttributeNameState),
		@selector(OF_expectAttributeEqualSignState),
		@selector(OF_expectAttributeDelimiterState),
		@selector(OF_inAttributeValueState),
		@selector(OF_expectTagCloseState),
		@selector(OF_expectSpaceOrTagCloseState),
		@selector(OF_inExclamationMarkState),
		@selector(OF_inCDATAOpeningState),
		@selector(OF_inCDATAState),
		@selector(OF_inCommentOpeningState),
		@selector(OF_inCommentState1),
		@selector(OF_inCommentState2),
		@selector(OF_inDOCTYPEState)
	};
	memcpy(selectors, selectors_, sizeof(selectors_));

	for (size_t i = 0; i < OF_XMLPARSER_NUM_STATES; i++) {
		if (![self instancesRespondToSelector: selectors[i]])
			@throw [OFInitializationFailedException
			    exceptionWithClass: self];

		lookupTable[i] = (state_function_t)
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

		_buffer = [[OFBigDataArray alloc] init];
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

- (void)parseBuffer: (const char*)buffer
	     length: (size_t)length
{
	_data = buffer;

	for (_i = _last = 0; _i < length; _i++) {
		size_t j = _i;

		lookupTable[_state](self, selectors[_state]);

		/* Ensure we don't count this character twice */
		if (_i != j)
			continue;

		if (_data[_i] == '\r' || (_data[_i] == '\n' &&
		    !_lastCarriageReturn))
			_lineNumber++;

		_lastCarriageReturn = (_data[_i] == '\r');
	}

	/* In OF_XMLPARSER_IN_TAG, there can be only spaces */
	if (length - _last > 0 && _state != OF_XMLPARSER_IN_TAG)
		appendToBuffer(_buffer, _data + _last, _encoding,
		    length - _last);
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

#ifdef OF_HAVE_FILES
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
#endif

/*
 * The following methods handle the different states of the parser. They are
 * looked up in +[initialize] and put in a lookup table to speed things up.
 * One dispatch for every character would be way too slow!
 */

- (void)OF_inByteOrderMarkState
{
	if (_data[_i] != "\xEF\xBB\xBF"[_level]) {
		if (_level == 0) {
			_state = OF_XMLPARSER_OUTSIDE_TAG;
			_i--;
			return;
		}

		@throw [OFMalformedXMLException exceptionWithParser: self];
	}

	if (_level++ == 2)
		_state = OF_XMLPARSER_OUTSIDE_TAG;

	_last = _i + 1;
}

/* Not in a tag */
- (void)OF_outsideTagState
{
	size_t length;

	if ((_finishedParsing || [_previous count] < 1) && _data[_i] != ' ' &&
	    _data[_i] != '\t' && _data[_i] != '\n' && _data[_i] != '\r' &&
	    _data[_i] != '<')
		@throw [OFMalformedXMLException exceptionWithParser: self];

	if (_data[_i] != '<')
		return;

	if ((length = _i - _last) > 0)
		appendToBuffer(_buffer, _data + _last, _encoding, length);

	if ([_buffer count] > 0) {
		void *pool = objc_autoreleasePoolPush();
		OFString *characters = transformString(self, _buffer, 0, true);

		if ([_delegate respondsToSelector:
		    @selector(parser:foundCharacters:)])
			[_delegate parser: self
			  foundCharacters: characters];

		objc_autoreleasePoolPop(pool);
	}

	[_buffer removeAllItems];

	_last = _i + 1;
	_state = OF_XMLPARSER_TAG_OPENED;
}

/* Tag was just opened */
- (void)OF_tagOpenedState
{
	if (_finishedParsing && _data[_i] != '!' && _data[_i] != '?')
		@throw [OFMalformedXMLException exceptionWithParser: self];

	switch (_data[_i]) {
	case '?':
		_last = _i + 1;
		_state = OF_XMLPARSER_IN_PROCESSING_INSTRUCTIONS;
		_level = 0;
		break;
	case '/':
		_last = _i + 1;
		_state = OF_XMLPARSER_IN_CLOSE_TAG_NAME;
		_acceptProlog = false;
		break;
	case '!':
		_last = _i + 1;
		_state = OF_XMLPARSER_IN_EXCLAMATIONMARK;
		_acceptProlog = false;
		break;
	default:
		if (_depthLimit > 0 && [_previous count] >= _depthLimit)
			@throw [OFMalformedXMLException
			    exceptionWithParser: self];

		_state = OF_XMLPARSER_IN_TAG_NAME;
		_acceptProlog = false;
		_i--;
		break;
	}
}

/* <?xml […]?> */
- (bool)OF_parseXMLProcessingInstructions: (OFString*)pi
{
	const char *cString;
	size_t length, last;
	int PIState = 0;
	OFString *attribute = nil;
	OFMutableString *value = nil;
	char piDelimiter = 0;
	bool hasVersion = false;

	if (!_acceptProlog)
		return false;

	_acceptProlog = false;

	pi = [pi substringWithRange: of_range(3, [pi length] - 3)];
	pi = [pi stringByDeletingEnclosingWhitespaces];

	cString = [pi UTF8String];
	length = [pi UTF8StringLength];

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
				     encoding: _encoding
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
				     encoding: _encoding
				       length: i - last];

			if ([attribute isEqual: @"version"]) {
				if (![value hasPrefix: @"1."])
					return false;

				hasVersion = true;
			}

			if ([attribute isEqual: @"encoding"]) {
				[value lowercase];

				if ([value isEqual: @"utf-8"])
					_encoding = OF_STRING_ENCODING_UTF_8;
				else if ([value isEqual: @"iso-8859-1"] ||
				    [value isEqual: @"iso_8859-1"])
					_encoding =
					    OF_STRING_ENCODING_ISO_8859_1;
				else if ([value isEqual: @"iso-8859-2"] ||
				    [value isEqual: @"iso_8859-2"])
					_encoding =
					    OF_STRING_ENCODING_ISO_8859_2;
				else if ([value isEqual: @"iso-8859-15"] ||
				    [value isEqual: @"iso_8859-15"])
					_encoding =
					    OF_STRING_ENCODING_ISO_8859_15;
				else if ([value isEqual: @"windows-1251"] ||
				    [value isEqual: @"cp1251"] ||
				    [value isEqual: @"cp-1251"])
					_encoding =
					    OF_STRING_ENCODING_WINDOWS_1251;
				else if ([value isEqual: @"windows-1252"] ||
				    [value isEqual: @"cp1252"] ||
				    [value isEqual: @"cp-1252"])
					_encoding =
					    OF_STRING_ENCODING_WINDOWS_1252;
				else if ([value isEqual: @"cp437"] ||
				    [value isEqual: @"cp-437"])
					_encoding =
					    OF_STRING_ENCODING_CODEPAGE_437;
				else if ([value isEqual: @"cp850"] ||
				    [value isEqual: @"cp-850"])
					_encoding =
					    OF_STRING_ENCODING_CODEPAGE_850;
				else if ([value isEqual: @"cp858"] ||
				    [value isEqual: @"cp-858"])
					_encoding =
					    OF_STRING_ENCODING_CODEPAGE_858;
				else if ([value isEqual: @"macintosh"])
					_encoding =
					    OF_STRING_ENCODING_MAC_ROMAN;
				else
					return false;
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

/* Inside processing instructions */
- (void)OF_inProcessingInstructionsState
{
	if (_data[_i] == '?')
		_level = 1;
	else if (_level == 1 && _data[_i] == '>') {
		void *pool = objc_autoreleasePoolPush();
		OFString *PI;

		appendToBuffer(_buffer, _data + _last, _encoding, _i - _last);
		PI = transformString(self, _buffer, 1, false);

		if ([PI isEqual: @"xml"] || [PI hasPrefix: @"xml "] ||
		    [PI hasPrefix: @"xml\t"] || [PI hasPrefix: @"xml\r"] ||
		    [PI hasPrefix: @"xml\n"])
			if (![self OF_parseXMLProcessingInstructions: PI])
				@throw [OFMalformedXMLException
				    exceptionWithParser: self];

		if ([_delegate respondsToSelector:
		    @selector(parser:foundProcessingInstructions:)])
			[_delegate		 parser: self
			    foundProcessingInstructions: PI];

		objc_autoreleasePoolPop(pool);

		[_buffer removeAllItems];

		_last = _i + 1;
		_state = OF_XMLPARSER_OUTSIDE_TAG;
	} else
		_level = 0;
}

/* Inside a tag, no name yet */
- (void)OF_inTagNameState
{
	void *pool;
	const char *bufferCString, *tmp;
	size_t length, bufferLength;
	OFString *bufferString;

	if (_data[_i] != ' ' && _data[_i] != '\t' && _data[_i] != '\n' &&
	    _data[_i] != '\r' && _data[_i] != '>' && _data[_i] != '/')
		return;

	if ((length = _i - _last) > 0)
		appendToBuffer(_buffer, _data + _last, _encoding, length);

	pool = objc_autoreleasePoolPush();

	bufferCString = [_buffer items];
	bufferLength = [_buffer count];
	bufferString = [OFString stringWithUTF8String: bufferCString
					       length: bufferLength];

	if ((tmp = memchr(bufferCString, ':', bufferLength)) != NULL) {
		_name = [[OFString alloc]
		    initWithUTF8String: tmp + 1
				length: bufferLength -
					(tmp - bufferCString) - 1];
		_prefix = [[OFString alloc]
		    initWithUTF8String: bufferCString
				length: tmp - bufferCString];
	} else {
		_name = [bufferString copy];
		_prefix = nil;
	}

	if (_data[_i] == '>' || _data[_i] == '/') {
		OFString *namespace;

		namespace = namespaceForPrefix(_prefix, _namespaces);

		if (_prefix != nil && namespace == nil)
			@throw [OFUnboundPrefixException
			    exceptionWithPrefix: _prefix
					 parser: self];

		if ([_delegate respondsToSelector: @selector(parser:
		    didStartElement:prefix:namespace:attributes:)])
			[_delegate parser: self
			  didStartElement: _name
				   prefix: _prefix
				namespace: namespace
			       attributes: nil];

		if (_data[_i] == '/') {
			if ([_delegate respondsToSelector:
			    @selector(parser:didEndElement:prefix:namespace:)])
				[_delegate parser: self
				    didEndElement: _name
					   prefix: _prefix
					namespace: namespace];

			if ([_previous count] == 0)
				_finishedParsing = true;
		} else
			[_previous addObject: bufferString];

		[_name release];
		[_prefix release];
		_name = _prefix = nil;

		_state = (_data[_i] == '/'
		    ? OF_XMLPARSER_EXPECT_TAG_CLOSE
		    : OF_XMLPARSER_OUTSIDE_TAG);
	} else
		_state = OF_XMLPARSER_IN_TAG;

	if (_data[_i] != '/')
		[_namespaces addObject: [OFMutableDictionary dictionary]];

	objc_autoreleasePoolPop(pool);

	[_buffer removeAllItems];
	_last = _i + 1;
}

/* Inside a close tag, no name yet */
- (void)OF_inCloseTagNameState
{
	void *pool;
	const char *bufferCString, *tmp;
	size_t length, bufferLength;
	OFString *bufferString, *namespace;

	if (_data[_i] != ' ' && _data[_i] != '\t' && _data[_i] != '\n' &&
	    _data[_i] != '\r' && _data[_i] != '>')
		return;

	if ((length = _i - _last) > 0)
		appendToBuffer(_buffer, _data + _last, _encoding, length);

	pool = objc_autoreleasePoolPush();

	bufferCString = [_buffer items];
	bufferLength = [_buffer count];
	bufferString = [OFString stringWithUTF8String: bufferCString
					       length: bufferLength];

	if ((tmp = memchr(bufferCString, ':', bufferLength)) != NULL) {
		_name = [[OFString alloc]
		    initWithUTF8String: tmp + 1
				length: bufferLength -
					(tmp - bufferCString) - 1];
		_prefix = [[OFString alloc]
		    initWithUTF8String: bufferCString
				length: tmp - bufferCString];
	} else {
		_name = [bufferString copy];
		_prefix = nil;
	}

	if (![[_previous lastObject] isEqual: bufferString])
		@throw [OFMalformedXMLException exceptionWithParser: self];

	[_previous removeLastObject];

	[_buffer removeAllItems];

	namespace = namespaceForPrefix(_prefix, _namespaces);
	if (_prefix != nil && namespace == nil)
		@throw [OFUnboundPrefixException exceptionWithPrefix: _prefix
							      parser: self];

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

	_last = _i + 1;
	_state = (_data[_i] == '>'
	    ? OF_XMLPARSER_OUTSIDE_TAG
	    : OF_XMLPARSER_EXPECT_SPACE_OR_TAG_CLOSE);

	if ([_previous count] == 0)
		_finishedParsing = true;
}

/* Inside a tag, name found */
- (void)OF_inTagState
{
	void *pool;
	OFString *namespace;
	OFXMLAttribute *const *attributesObjects;
	size_t attributesCount;

	if (_data[_i] != '>' && _data[_i] != '/') {
		if (_data[_i] != ' ' && _data[_i] != '\t' &&
		    _data[_i] != '\n' && _data[_i] != '\r') {
			_last = _i;
			_state = OF_XMLPARSER_IN_ATTRIBUTE_NAME;
			_i--;
		}

		return;
	}

	attributesObjects = [_attributes objects];
	attributesCount = [_attributes count];

	namespace = namespaceForPrefix(_prefix, _namespaces);

	if (_prefix != nil && namespace == nil)
		@throw [OFUnboundPrefixException exceptionWithPrefix: _prefix
							      parser: self];

	for (size_t j = 0; j < attributesCount; j++)
		resolveAttributeNamespace(attributesObjects[j], _namespaces,
		    self);

	pool = objc_autoreleasePoolPush();

	if ([_delegate respondsToSelector:
	    @selector(parser:didStartElement:prefix:namespace:attributes:)])
		[_delegate parser: self
		  didStartElement: _name
			   prefix: _prefix
			namespace: namespace
		       attributes: _attributes];

	if (_data[_i] == '/') {
		if ([_delegate respondsToSelector:
		    @selector(parser:didEndElement:prefix:namespace:)])
			[_delegate parser: self
			    didEndElement: _name
				   prefix: _prefix
				namespace: namespace];

		if ([_previous count] == 0)
			_finishedParsing = true;

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

	_last = _i + 1;
	_state = (_data[_i] == '/'
	    ? OF_XMLPARSER_EXPECT_TAG_CLOSE
	    : OF_XMLPARSER_OUTSIDE_TAG);
}

/* Looking for attribute name */
- (void)OF_inAttributeNameState
{
	void *pool;
	OFString *bufferString;
	const char *bufferCString, *tmp;
	size_t length, bufferLength;

	if (_data[_i] != '=' && _data[_i] != ' ' && _data[_i] != '\t' &&
	    _data[_i] != '\n' && _data[_i] != '\r')
		return;

	if ((length = _i - _last) > 0)
		appendToBuffer(_buffer, _data + _last, _encoding, length);

	pool = objc_autoreleasePoolPush();

	bufferString = [OFString stringWithUTF8String: [_buffer items]
					       length: [_buffer count]];

	bufferCString = [bufferString UTF8String];
	bufferLength = [bufferString UTF8StringLength];

	if ((tmp = memchr(bufferCString, ':', bufferLength)) != NULL) {
		_attributeName = [[OFString alloc]
		    initWithUTF8String: tmp + 1
				length: bufferLength -
					(tmp - bufferCString) - 1];
		_attributePrefix = [[OFString alloc]
		    initWithUTF8String: bufferCString
				length: tmp - bufferCString];
	} else {
		_attributeName = [bufferString copy];
		_attributePrefix = nil;
	}

	objc_autoreleasePoolPop(pool);

	[_buffer removeAllItems];

	_last = _i + 1;
	_state = (_data[_i] == '='
	    ? OF_XMLPARSER_EXPECT_ATTRIBUTE_DELIMITER
	    : OF_XMLPARSER_EXPECT_ATTRIBUTE_EQUAL_SIGN);
}

/* Expecting equal sign of an attribute */
- (void)OF_expectAttributeEqualSignState
{
	if (_data[_i] == '=') {
		_last = _i + 1;
		_state = OF_XMLPARSER_EXPECT_ATTRIBUTE_DELIMITER;
		return;
	}

	if (_data[_i] != ' ' && _data[_i] != '\t' && _data[_i] != '\n' &&
	    _data[_i] != '\r')
		@throw [OFMalformedXMLException exceptionWithParser: self];
}

/* Expecting name/value delimiter of an attribute */
- (void)OF_expectAttributeDelimiterState
{
	_last = _i + 1;

	if (_data[_i] == ' ' || _data[_i] == '\t' || _data[_i] == '\n' ||
	    _data[_i] == '\r')
		return;

	if (_data[_i] != '\'' && _data[_i] != '"')
		@throw [OFMalformedXMLException exceptionWithParser: self];

	_delimiter = _data[_i];
	_state = OF_XMLPARSER_IN_ATTRIBUTE_VALUE;
}

/* Looking for attribute value */
- (void)OF_inAttributeValueState
{
	void *pool;
	OFString *attributeValue;
	size_t length;

	if (_data[_i] != _delimiter)
		return;

	if ((length = _i - _last) > 0)
		appendToBuffer(_buffer, _data + _last, _encoding, length);

	pool = objc_autoreleasePoolPush();
	attributeValue = transformString(self, _buffer, 0, true);

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

	[_buffer removeAllItems];
	[_attributeName release];
	[_attributePrefix release];
	_attributeName = _attributePrefix = nil;

	_last = _i + 1;
	_state = OF_XMLPARSER_IN_TAG;
}

/* Expecting closing '>' */
- (void)OF_expectTagCloseState
{
	if (_data[_i] == '>') {
		_last = _i + 1;
		_state = OF_XMLPARSER_OUTSIDE_TAG;
	} else
		@throw [OFMalformedXMLException exceptionWithParser: self];
}

/* Expecting closing '>' or space */
- (void)OF_expectSpaceOrTagCloseState
{
	if (_data[_i] == '>') {
		_last = _i + 1;
		_state = OF_XMLPARSER_OUTSIDE_TAG;
	} else if (_data[_i] != ' ' && _data[_i] != '\t' &&
	    _data[_i] != '\n' && _data[_i] != '\r')
		@throw [OFMalformedXMLException exceptionWithParser: self];
}

/* In <! */
- (void)OF_inExclamationMarkState
{
	if (_finishedParsing && _data[_i] != '-')
		@throw [OFMalformedXMLException exceptionWithParser: self];

	if (_data[_i] == '-')
		_state = OF_XMLPARSER_IN_COMMENT_OPENING;
	else if (_data[_i] == '[') {
		_state = OF_XMLPARSER_IN_CDATA_OPENING;
		_level = 0;
	} else if (_data[_i] == 'D') {
		_state = OF_XMLPARSER_IN_DOCTYPE;
		_level = 0;
	} else
		@throw [OFMalformedXMLException exceptionWithParser: self];

	_last = _i + 1;
}

/* CDATA */
- (void)OF_inCDATAOpeningState
{
	if (_data[_i] != "CDATA["[_level])
		@throw [OFMalformedXMLException exceptionWithParser: self];

	if (++_level == 6) {
		_state = OF_XMLPARSER_IN_CDATA;
		_level = 0;
	}

	_last = _i + 1;
}

- (void)OF_inCDATAState
{

	if (_data[_i] == ']')
		_level++;
	else if (_data[_i] == '>' && _level >= 2) {
		void *pool = objc_autoreleasePoolPush();
		OFString *CDATA;

		appendToBuffer(_buffer, _data + _last, _encoding, _i - _last);
		CDATA = transformString(self, _buffer, 2, false);

		if ([_delegate respondsToSelector:
		    @selector(parser:foundCDATA:)])
			[_delegate parser: self
			       foundCDATA: CDATA];

		objc_autoreleasePoolPop(pool);

		[_buffer removeAllItems];

		_last = _i + 1;
		_state = OF_XMLPARSER_OUTSIDE_TAG;
	} else
		_level = 0;
}

/* Comment */
- (void)OF_inCommentOpeningState
{
	if (_data[_i] != '-')
		@throw [OFMalformedXMLException exceptionWithParser: self];

	_last = _i + 1;
	_state = OF_XMLPARSER_IN_COMMENT_1;
	_level = 0;
}

- (void)OF_inCommentState1
{
	if (_data[_i] == '-')
		_level++;
	else
		_level = 0;

	if (_level == 2)
		_state = OF_XMLPARSER_IN_COMMENT_2;
}

- (void)OF_inCommentState2
{
	void *pool;
	OFString *comment;

	if (_data[_i] != '>')
		@throw [OFMalformedXMLException exceptionWithParser: self];

	pool = objc_autoreleasePoolPush();

	appendToBuffer(_buffer, _data + _last, _encoding, _i - _last);
	comment = transformString(self, _buffer, 2, false);

	if ([_delegate respondsToSelector: @selector(parser:foundComment:)])
		[_delegate parser: self
		     foundComment: comment];

	objc_autoreleasePoolPop(pool);

	[_buffer removeAllItems];

	_last = _i + 1;
	_state = OF_XMLPARSER_OUTSIDE_TAG;
}

/* In <!DOCTYPE ...> */
- (void)OF_inDOCTYPEState
{
	if ((_level < 6 && _data[_i] != "OCTYPE"[_level]) ||
	    (_level == 6 && _data[_i] != ' ' && _data[_i] != '\t' &&
	    _data[_i] != '\n' && _data[_i] != '\r'))
		@throw [OFMalformedXMLException exceptionWithParser: self];

	_level++;

	if (_level > 6 && _data[_i] == '>')
		_state = OF_XMLPARSER_OUTSIDE_TAG;

	_last = _i + 1;
}

- (size_t)lineNumber
{
	return _lineNumber;
}

- (bool)hasFinishedParsing
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
