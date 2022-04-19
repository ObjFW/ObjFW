/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedVersionException.h"

OFString *
OFHTTPStatusCodeString(short code)
{
	switch (code) {
	case 100:
		return @"Continue";
	case 101:
		return @"Switching Protocols";
	case 200:
		return @"OK";
	case 201:
		return @"Created";
	case 202:
		return @"Accepted";
	case 203:
		return @"Non-Authoritative Information";
	case 204:
		return @"No Content";
	case 205:
		return @"Reset Content";
	case 206:
		return @"Partial Content";
	case 300:
		return @"Multiple Choices";
	case 301:
		return @"Moved Permanently";
	case 302:
		return @"Found";
	case 303:
		return @"See Other";
	case 304:
		return @"Not Modified";
	case 305:
		return @"Use Proxy";
	case 307:
		return @"Temporary Redirect";
	case 400:
		return @"Bad Request";
	case 401:
		return @"Unauthorized";
	case 402:
		return @"Payment Required";
	case 403:
		return @"Forbidden";
	case 404:
		return @"Not Found";
	case 405:
		return @"Method Not Allowed";
	case 406:
		return @"Not Acceptable";
	case 407:
		return @"Proxy Authentication Required";
	case 408:
		return @"Request Timeout";
	case 409:
		return @"Conflict";
	case 410:
		return @"Gone";
	case 411:
		return @"Length Required";
	case 412:
		return @"Precondition Failed";
	case 413:
		return @"Request Entity Too Large";
	case 414:
		return @"Request-URI Too Long";
	case 415:
		return @"Unsupported Media Type";
	case 416:
		return @"Requested Range Not Satisfiable";
	case 417:
		return @"Expectation Failed";
	case 500:
		return @"Internal Server Error";
	case 501:
		return @"Not Implemented";
	case 502:
		return @"Bad Gateway";
	case 503:
		return @"Service Unavailable";
	case 504:
		return @"Gateway Timeout";
	case 505:
		return @"HTTP Version Not Supported";
	default:
		return @"(unknown)";
	}
}

static OFStringEncoding
encodingForContentType(OFString *contentType)
{
	const char *UTF8String = contentType.UTF8String;
	size_t last, length = contentType.UTF8StringLength;
	enum {
		stateType,
		stateBeforeParamName,
		stateParamName,
		stateParamValueOrQuote,
		stateParamValue,
		stateParamQuotedValue,
		stateAfterParamValue
	} state = stateType;
	OFString *name = nil, *value = nil, *charset = nil;
	OFStringEncoding ret;

	last = 0;
	for (size_t i = 0; i < length; i++) {
		switch (state) {
		case stateType:
			if (UTF8String[i] == ';') {
				state = stateBeforeParamName;
				last = i + 1;
			}
			break;
		case stateBeforeParamName:
			if (UTF8String[i] == ' ')
				last = i + 1;
			else {
				state = stateParamName;
				i--;
			}
			break;
		case stateParamName:
			if (UTF8String[i] == '=') {
				name = [OFString
				    stringWithUTF8String: UTF8String + last
						  length: i - last];

				state = stateParamValueOrQuote;
				last = i + 1;
			}
			break;
		case stateParamValueOrQuote:
			if (UTF8String[i] == '"') {
				state = stateParamQuotedValue;
				last = i + 1;
			} else {
				state = stateParamValue;
				i--;
			}
			break;
		case stateParamValue:
			if (UTF8String[i] == ';') {
				value = [OFString
				    stringWithUTF8String: UTF8String + last
						  length: i - last];
				value =
				    value.stringByDeletingTrailingWhitespaces;

				if ([name isEqual: @"charset"])
					charset = value;

				state = stateBeforeParamName;
				last = i + 1;
			}
			break;
		case stateParamQuotedValue:
			if (UTF8String[i] == '"') {
				value = [OFString
				    stringWithUTF8String: UTF8String + last
						  length: i - last];

				if ([name isEqual: @"charset"])
					charset = value;

				state = stateAfterParamValue;
			}
			break;
		case stateAfterParamValue:
			if (UTF8String[i] == ';') {
				state = stateBeforeParamName;
				last = i + 1;
			} else if (UTF8String[i] != ' ')
				return OFStringEncodingAutodetect;
			break;
		}
	}
	if (state == stateParamValue) {
		value = [OFString stringWithUTF8String: UTF8String + last
						length: length - last];
		value = value.stringByDeletingTrailingWhitespaces;

		if ([name isEqual: @"charset"])
			charset = value;
	}

	@try {
		ret = OFStringEncodingParseName(charset);
	} @catch (OFInvalidArgumentException *e) {
		ret = OFStringEncodingAutodetect;
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

- (void)setProtocolVersion: (OFHTTPRequestProtocolVersion)protocolVersion
{
	if (protocolVersion.major != 1 || protocolVersion.minor > 1)
		@throw [OFUnsupportedVersionException exceptionWithVersion:
		    [OFString stringWithFormat: @"%hhu.%hhu",
						protocolVersion.major,
						protocolVersion.minor]];

	_protocolVersion = protocolVersion;
}

- (OFHTTPRequestProtocolVersion)protocolVersion
{
	return _protocolVersion;
}

- (void)setProtocolVersionString: (OFString *)string
{
	void *pool = objc_autoreleasePoolPush();
	OFArray *components = [string componentsSeparatedByString: @"."];
	unsigned long long major, minor;
	OFHTTPRequestProtocolVersion protocolVersion;

	if (components.count != 2)
		@throw [OFInvalidFormatException exception];

	major = [components.firstObject unsignedLongLongValue];
	minor = [components.lastObject unsignedLongLongValue];

	if (major > UCHAR_MAX || minor > UCHAR_MAX)
		@throw [OFOutOfRangeException exception];

	protocolVersion.major = (unsigned char)major;
	protocolVersion.minor = (unsigned char)minor;

	self.protocolVersion = protocolVersion;

	objc_autoreleasePoolPop(pool);
}

- (OFString *)protocolVersionString
{
	return [OFString stringWithFormat: @"%hhu.%hhu",
					   _protocolVersion.major,
					   _protocolVersion.minor];
}

- (OFString *)string
{
	return [self stringWithEncoding: OFStringEncodingAutodetect];
}

- (OFString *)stringWithEncoding: (OFStringEncoding)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFString *contentType, *contentLengthString, *ret;
	OFData *data;

	if (encoding == OFStringEncodingAutodetect &&
	    (contentType = [_headers objectForKey: @"Content-Type"]) != nil)
		encoding = encodingForContentType(contentType);

	if (encoding == OFStringEncodingAutodetect)
		encoding = OFStringEncodingUTF8;

	data = [self readDataUntilEndOfStream];

	contentLengthString = [_headers objectForKey: @"Content-Length"];
	if (contentLengthString != nil) {
		unsigned long long contentLength =
		    contentLengthString.unsignedLongLongValue;

		if (contentLength > SIZE_MAX)
			@throw [OFOutOfRangeException exception];

		if (data.count != (size_t)contentLength)
			@throw [OFTruncatedDataException exception];
	}

	ret = [[OFString alloc] initWithCString: (char *)data.items
				       encoding: encoding
					 length: data.count];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString *)description
{
	void *pool = objc_autoreleasePoolPush();
	OFString *indentedHeaders, *ret;

	indentedHeaders = [_headers.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];

	ret = [[OFString alloc] initWithFormat:
	    @"<%@:\n"
	    @"\tStatus code = %hd\n"
	    @"\tHeaders = %@\n"
	    @">",
	    self.class, _statusCode, indentedHeaders];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
