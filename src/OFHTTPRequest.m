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

#import "OFHTTPRequest.h"
#import "OFString.h"
#import "OFURL.h"
#import "OFDictionary.h"
#import "OFDataArray.h"
#import "OFArray.h"

#import "autorelease.h"
#import "macros.h"

#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"
#import "OFUnsupportedVersionException.h"

@implementation OFHTTPRequest
+ (instancetype)request
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)requestWithURL: (OFURL*)URL
{
	return [[[self alloc] initWithURL: URL] autorelease];
}

- init
{
	self = [super init];

	_requestType = OF_HTTP_REQUEST_TYPE_GET;
	_protocolVersion.major = 1;
	_protocolVersion.minor = 1;

	return self;
}

- initWithURL: (OFURL*)URL
{
	self = [self init];

	@try {
		[self setURL: URL];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_URL release];
	[_headers release];
	[_POSTData release];
	[_MIMEType release];
	[_remoteAddress release];

	[super dealloc];
}

- (void)setURL: (OFURL*)URL
{
	OF_SETTER(_URL, URL, YES, 1)
}

- (OFURL*)URL
{
	OF_GETTER(_URL, YES)
}

- (void)setRequestType: (of_http_request_type_t)requestType
{
	_requestType = requestType;
}

- (of_http_request_type_t)requestType
{
	return _requestType;
}

- (void)setProtocolVersion: (of_http_request_protocol_version_t)protocolVersion
{
	if (protocolVersion.major != 1 || protocolVersion.minor > 1)
		@throw [OFUnsupportedVersionException
		    exceptionWithClass: [self class]
			       version: [OFString stringWithFormat: @"%u.%u",
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
		@throw [OFInvalidFormatException
		    exceptionWithClass: [self class]];

	major = [[components firstObject] decimalValue];
	minor = [[components lastObject] decimalValue];

	if (major < 0 || major > UINT8_MAX || minor < 0 || minor > UINT8_MAX)
		@throw [OFOutOfRangeException exceptionWithClass: [self class]];

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

- (void)setHeaders: (OFDictionary*)headers
{
	OF_SETTER(_headers, headers, YES, 1)
}

- (OFDictionary*)headers
{
	OF_GETTER(_headers, YES)
}

- (void)setPOSTData: (OFDataArray*)POSTData
{
	OF_SETTER(_POSTData, POSTData, YES, 0)
}

- (OFDataArray*)POSTData
{
	OF_GETTER(_POSTData, YES)
}

- (void)setMIMEType: (OFString*)MIMEType
{
	OF_SETTER(_MIMEType, MIMEType, YES, 1)
}

- (OFString*)MIMEType
{
	OF_GETTER(_MIMEType, YES)
}

- (void)setRemoteAddress: (OFString*)remoteAddress
{
	OF_SETTER(_remoteAddress, remoteAddress, YES, 1)
}

- (OFString*)remoteAddress
{
	OF_GETTER(_remoteAddress, YES)
}

- (OFString*)description
{
	void *pool = objc_autoreleasePoolPush();
	const char *requestTypeStr = NULL;
	OFString *indentedHeaders, *indentedPOSTData, *ret;

	switch (_requestType) {
	case OF_HTTP_REQUEST_TYPE_GET:
		requestTypeStr = "GET";
		break;
	case OF_HTTP_REQUEST_TYPE_POST:
		requestTypeStr = "POST";
		break;
	case OF_HTTP_REQUEST_TYPE_HEAD:
		requestTypeStr = "HEAD";
		break;
	}

	indentedHeaders = [[_headers description]
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	indentedPOSTData = [[_POSTData description]
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];

	ret = [[OFString alloc] initWithFormat:
	    @"<%@:\n\tURL = %@\n"
	    @"\tRequest type = %s\n"
	    @"\tHeaders = %@\n"
	    @"\tPOST data = %@\n"
	    @"\tPOST data MIME type = %@\n"
	    @"\tRemote address = %@\n"
	    @">",
	    [self class], _URL, requestTypeStr, indentedHeaders,
	    indentedPOSTData, _MIMEType, _remoteAddress];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
