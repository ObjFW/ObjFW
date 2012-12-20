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

#import "OFHTTPRequest.h"
#import "OFString.h"
#import "OFURL.h"
#import "OFDictionary.h"
#import "OFDataArray.h"

#import "autorelease.h"
#import "macros.h"

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

	requestType = OF_HTTP_REQUEST_TYPE_GET;

	return self;
}

- initWithURL: (OFURL*)URL_
{
	self = [self init];

	@try {
		[self setURL: URL_];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[URL release];
	[headers release];
	[POSTData release];
	[MIMEType release];
	[remoteAddress release];

	[super dealloc];
}

- (void)setURL: (OFURL*)URL_
{
	OF_SETTER(URL, URL_, YES, 1)
}

- (OFURL*)URL
{
	OF_GETTER(URL, YES)
}

- (void)setRequestType: (of_http_request_type_t)requestType_
{
	requestType = requestType_;
}

- (of_http_request_type_t)requestType
{
	return requestType;
}

- (void)setHeaders: (OFDictionary*)headers_
{
	OF_SETTER(headers, headers_, YES, 1)
}

- (OFDictionary*)headers
{
	OF_GETTER(headers, YES)
}

- (void)setPOSTData: (OFDataArray*)POSTData_
{
	OF_SETTER(POSTData, POSTData_, YES, 0)
}

- (OFDataArray*)POSTData
{
	OF_GETTER(POSTData, YES)
}

- (void)setMIMEType: (OFString*)MIMEType_
{
	OF_SETTER(MIMEType, MIMEType_, YES, 1)
}

- (OFString*)MIMEType
{
	OF_GETTER(MIMEType, YES)
}

- (void)setRemoteAddress: (OFString*)remoteAddress_
{
	OF_SETTER(remoteAddress, remoteAddress_, YES, 1)
}

- (OFString*)remoteAddress
{
	OF_GETTER(remoteAddress, YES)
}

- (OFString*)description
{
	void *pool = objc_autoreleasePoolPush();
	const char *requestTypeStr = NULL;
	OFString *indentedHeaders, *indentedPOSTData, *ret;

	switch (requestType) {
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

	indentedHeaders = [[headers description]
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	indentedPOSTData = [[POSTData description]
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
	    [self class], URL, requestTypeStr, indentedHeaders,
	    indentedPOSTData, MIMEType, remoteAddress];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end

@implementation OFHTTPRequestResult
+ resultWithStatusCode: (short)status
	       headers: (OFDictionary*)headers
		  data: (OFDataArray*)data
{
	return [[[self alloc] initWithStatusCode: status
					 headers: headers
					    data: data] autorelease];
}

- initWithStatusCode: (short)status
	     headers: (OFDictionary*)headers_
		data: (OFDataArray*)data_
{
	self = [super init];

	statusCode = status;
	headers = [headers_ copy];
	data = [data_ retain];

	return self;
}

- (void)dealloc
{
	[headers release];
	[data release];

	[super dealloc];
}

- (short)statusCode
{
	return statusCode;
}

- (OFDictionary*)headers
{
	OF_GETTER(headers, YES)
}

- (OFDataArray*)data
{
	OF_GETTER(data, YES)
}

- (OFString*)description
{
	void *pool = objc_autoreleasePoolPush();
	OFString *indentedHeaders, *indentedData, *ret;

	indentedHeaders = [[headers description]
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	indentedData = [[data description]
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];

	ret = [[OFString alloc] initWithFormat:
	    @"<%@:\n"
	    @"\tStatus code = %d\n"
	    @"\tHeaders = %@\n"
	    @"\tData = %@\n"
	    @">",
	    [self class], statusCode, indentedHeaders, indentedData];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
