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

#import "OFHTTPResponse.h"
#import "OFString.h"
#import "OFDictionary.h"
#import "OFArray.h"
#import "OFDataArray.h"

#import "autorelease.h"
#import "macros.h"

#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"
#import "OFTruncatedDataException.h"
#import "OFUnsupportedVersionException.h"

@implementation OFHTTPResponse
- init
{
	self = [super init];

	_protocolVersion.major = 1;
	_protocolVersion.minor = 1;

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
		@throw [OFUnsupportedVersionException
		    exceptionWithVersion: [OFString stringWithFormat: @"%u.%u",
					      protocolVersion.major,
					      protocolVersion.minor]];

	_protocolVersion = protocolVersion;
}

- (of_http_request_protocol_version_t)protocolVersion
{
	return _protocolVersion;
}

- (void)setProtocolVersionFromString: (OFString*)string
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

- (OFString*)protocolVersionString
{
	return [OFString stringWithFormat: @"%u.%u", _protocolVersion.major,
					   _protocolVersion.minor];
}

- (short)statusCode
{
	return _statusCode;
}

- (void)setStatusCode: (short)statusCode
{
	_statusCode = statusCode;
}

- (OFDictionary*)headers
{
	OF_GETTER(_headers, true)
}

- (void)setHeaders: (OFDictionary*)headers
{
	OF_SETTER(_headers, headers, true, 1)
}

- (OFString*)string
{
	return [self stringWithEncoding: OF_STRING_ENCODING_AUTODETECT];
}

- (OFString*)stringWithEncoding: (of_string_encoding_t)encoding
{
	void *pool = objc_autoreleasePoolPush();
	OFString *contentType, *contentLength, *ret;
	OFDataArray *data;

	if (encoding == OF_STRING_ENCODING_AUTODETECT &&
	    (contentType = [_headers objectForKey: @"Content-Type"]) != nil) {
		contentType = [contentType lowercaseString];

		if ([contentType hasSuffix: @"charset=utf-8"])
			encoding = OF_STRING_ENCODING_UTF_8;
		if ([contentType hasSuffix: @"charset=iso-8859-1"])
			encoding = OF_STRING_ENCODING_ISO_8859_1;
		if ([contentType hasSuffix: @"charset=iso-8859-15"])
			encoding = OF_STRING_ENCODING_ISO_8859_15;
		if ([contentType hasSuffix: @"charset=windows-1252"])
			encoding = OF_STRING_ENCODING_WINDOWS_1252;
	}

	if (encoding == OF_STRING_ENCODING_AUTODETECT)
		encoding = OF_STRING_ENCODING_UTF_8;

	data = [self readDataArrayTillEndOfStream];

	if ((contentLength = [_headers objectForKey: @"Content-Length"]) != nil)
		if ([data count] != (size_t)[contentLength decimalValue])
			@throw [OFTruncatedDataException exception];

	ret = [[OFString alloc] initWithCString: (char*)[data items]
				       encoding: encoding
					 length: [data count]];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}

- (OFString*)description
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
