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

#import "OFHTTPRequestReply.h"
#import "OFString.h"
#import "OFDictionary.h"
#import "OFArray.h"

#import "autorelease.h"
#import "macros.h"

#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"
#import "OFUnsupportedVersionException.h"

@implementation OFHTTPRequestReply
- init
{
	self = [super init];

	protocolVersion.major = 1;
	protocolVersion.minor = 1;

	return self;
}

- (void)dealloc
{
	[headers release];

	[super dealloc];
}

- (void)setProtocolVersion: (of_http_request_protocol_version_t)protocolVersion_
{
	if (protocolVersion_.major != 1 || protocolVersion.minor > 1)
		@throw [OFUnsupportedVersionException
		    exceptionWithClass: [self class]
			       version: [OFString stringWithFormat: @"%u.%u",
					    protocolVersion_.major,
					    protocolVersion_.minor]];

	protocolVersion = protocolVersion_;
}

- (of_http_request_protocol_version_t)protocolVersion
{
	return protocolVersion;
}

- (void)setProtocolVersionFromString: (OFString*)string
{
	void *pool = objc_autoreleasePoolPush();
	OFArray *components = [string componentsSeparatedByString: @"."];
	intmax_t major, minor;
	of_http_request_protocol_version_t protocolVersion_;

	if ([components count] != 2)
		@throw [OFInvalidFormatException
		    exceptionWithClass: [self class]];

	major = [[components firstObject] decimalValue];
	minor = [[components lastObject] decimalValue];

	if (major < 0 || major > UINT8_MAX || minor < 0 || minor > UINT8_MAX)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

	protocolVersion_.major = (uint8_t)major;
	protocolVersion_.minor = (uint8_t)minor;

	[self setProtocolVersion: protocolVersion_];

	objc_autoreleasePoolPop(pool);
}

- (OFString*)protocolVersionString
{
	return [OFString stringWithFormat: @"%u.%u", protocolVersion.major,
					   protocolVersion.minor];
}

- (short)statusCode
{
	return statusCode;
}

- (void)setStatusCode: (short)statusCode_
{
	statusCode = statusCode_;
}

- (OFDictionary*)headers
{
	OF_GETTER(headers, YES)
}

- (void)setHeaders: (OFDictionary*)headers_
{
	OF_SETTER(headers, headers_, YES, YES)
}

- (OFString*)description
{
	void *pool = objc_autoreleasePoolPush();
	OFString *indentedHeaders, *ret;

	indentedHeaders = [[headers description]
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];

	ret = [[OFString alloc] initWithFormat:
	    @"<%@:\n"
	    @"\tStatus code = %d\n"
	    @"\tHeaders = %@\n"
	    @">",
	    [self class], statusCode, indentedHeaders];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
