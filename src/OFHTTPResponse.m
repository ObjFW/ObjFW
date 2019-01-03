/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#import "OFHTTPResponse.h"
#import "OFString.h"
#import "OFDictionary.h"
#import "OFArray.h"
#import "OFData.h"

#import "OFInvalidEncodingException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedVersionException.h"

static of_string_encoding_t
encodingForContentType(OFString *contentType)
{
	const char *UTF8String = [contentType UTF8String];
	size_t last, length = [contentType UTF8StringLength];
	enum {
		STATE_TYPE,
		STATE_BEFORE_PARAM_NAME,
		STATE_PARAM_NAME,
		STATE_PARAM_VALUE_OR_QUOTE,
		STATE_PARAM_VALUE,
		STATE_PARAM_QUOTED_VALUE,
		STATE_AFTER_PARAM_VALUE
	} state = STATE_TYPE;
	OFString *name = nil, *value = nil, *charset = nil;
	of_string_encoding_t ret;

	last = 0;
	for (size_t i = 0; i < length; i++) {
		switch (state) {
		case STATE_TYPE:
			if (UTF8String[i] == ';') {
				state = STATE_BEFORE_PARAM_NAME;
				last = i + 1;
			}
			break;
		case STATE_BEFORE_PARAM_NAME:
			if (UTF8String[i] == ' ')
				last = i + 1;
			else {
				state = STATE_PARAM_NAME;
				i--;
			}
			break;
		case STATE_PARAM_NAME:
			if (UTF8String[i] == '=') {
				name = [OFString
				    stringWithUTF8String: UTF8String + last
						  length: i - last];

				state = STATE_PARAM_VALUE_OR_QUOTE;
				last = i + 1;
			}
			break;
		case STATE_PARAM_VALUE_OR_QUOTE:
			if (UTF8String[i] == '"') {
				state = STATE_PARAM_QUOTED_VALUE;
				last = i + 1;
			} else {
				state = STATE_PARAM_VALUE;
				i--;
			}
			break;
		case STATE_PARAM_VALUE:
			if (UTF8String[i] == ';') {
				value = [OFString
				    stringWithUTF8String: UTF8String + last
						  length: i - last];
				value = [value
				    stringByDeletingTrailingWhitespaces];

				if ([name isEqual: @"charset"])
					charset = value;

				state = STATE_BEFORE_PARAM_NAME;
				last = i + 1;
			}
			break;
		case STATE_PARAM_QUOTED_VALUE:
			if (UTF8String[i] == '"') {
				value = [OFString
				    stringWithUTF8String: UTF8String + last
						  length: i - last];

				if ([name isEqual: @"charset"])
					charset = value;

				state = STATE_AFTER_PARAM_VALUE;
			}
			break;
		case STATE_AFTER_PARAM_VALUE:
			if (UTF8String[i] == ';') {
				state = STATE_BEFORE_PARAM_NAME;
				last = i + 1;
			} else if (UTF8String[i] != ' ')
				return OF_STRING_ENCODING_AUTODETECT;
			break;
		}
	}
	if (state == STATE_PARAM_VALUE) {
		value = [OFString stringWithUTF8String: UTF8String + last
						length: length - last];
		value = [value stringByDeletingTrailingWhitespaces];

		if ([name isEqual: @"charset"])
			charset = value;
	}

	@try {
		ret = of_string_parse_encoding(charset);
	} @catch (OFInvalidEncodingException *e) {
		ret = OF_STRING_ENCODING_AUTODETECT;
	}

	return ret;
}

@implementation OFHTTPResponse
@synthesize statusCode = _statusCode, headers = _headers;

- (instancetype)init
{
	self = [super init];

	@try {
		_protocolVersion.major = 1;
		_protocolVersion.minor = 1;
		_headers = [[OFDictionary alloc] init];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_headers release];

	[super dealloc];
}

- (void)setProtocolVersion: (of_http_request_protocol_version_t)protocolVersion
{
	if (protocolVersion.major != 1 || protocolVersion.minor > 1)
		@throw [OFUnsupportedVersionException exceptionWithVersion:
		    [OFString stringWithFormat: @"%u.%u",
						protocolVersion.major,
						protocolVersion.minor]];

	_protocolVersion = protocolVersion;
}

- (of_http_request_protocol_version_t)protocolVersion
{
	return _protocolVersion;
}

- (void)setProtocolVersionString: (OFString *)string
{
	void *pool = objc_autoreleasePoolPush();
	OFArray *components = [string componentsSeparatedByString: @"."];
	intmax_t major, minor;
	of_http_request_protocol_version_t protocolVersion;

	if ([components count] != 2)
		@throw [OFInvalidFormatException exception];

	major = [[components firstObject] decimalValue];
	minor = [[components lastObject] decimalValue];

	if (major < 0 || major > UINT8_MAX || minor < 0 || minor > UINT8_MAX)
		@throw [OFOutOfRangeException exception];

	protocolVersion.major = (uint8_t)major;
	protocolVersion.minor = (uint8_t)minor;

	[self setProtocolVersion: protocolVersion];

	objc_autoreleasePoolPop(pool);
}

- (OFString *)protocolVersionString
{
	return [OFString stringWithFormat: @"%u.%u",
					   _protocolVersion.major,
					   _protocolVersion.minor];
}

- (OFString *)string
{
	return [self stringWithEncoding: OF_STRING_ENCODING_AUTODETECT];
}

- (OFString *)stringWithEncoding: (of_string_encoding_t)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFString *contentType, *contentLength, *ret;
	OFData *data;

	if (encoding == OF_STRING_ENCODING_AUTODETECT &&
	    (contentType = [_headers objectForKey: @"Content-Type"]) != nil)
		encoding = encodingForContentType(contentType);

	if (encoding == OF_STRING_ENCODING_AUTODETECT)
		encoding = OF_STRING_ENCODING_UTF_8;

	data = [self readDataUntilEndOfStream];

	if ((contentLength = [_headers objectForKey: @"Content-Length"]) != nil)
		if ([data count] != (size_t)[contentLength decimalValue])
			@throw [OFTruncatedDataException exception];

	ret = [[OFString alloc] initWithCString: (char *)[data items]
				       encoding: encoding
					 length: [data count]];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString *)description
{
	void *pool = objc_autoreleasePoolPush();
	OFString *indentedHeaders, *ret;

	indentedHeaders = [[_headers description]
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];

	ret = [[OFString alloc] initWithFormat:
	    @"<%@:\n"
	    @"\tStatus code = %d\n"
	    @"\tHeaders = %@\n"
	    @">",
	    [self class], _statusCode, indentedHeaders];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
