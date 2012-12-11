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
	[postData release];
	[MIMEType release];

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

- (void)setPostData: (OFDataArray*)postData_
{
	OF_SETTER(postData, postData_, YES, 0)
}

- (OFDataArray*)postData
{
	OF_GETTER(postData, YES)
}

- (void)setMIMEType: (OFString*)MIMEType_
{
	OF_SETTER(MIMEType, MIMEType_, YES, 1)
}

- (OFString*)MIMEType
{
	OF_GETTER(MIMEType, YES)
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
	data = [data_ retain];
	headers = [headers_ copy];

	return self;
}

- (void)dealloc
{
	[data release];
	[headers release];

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
@end
