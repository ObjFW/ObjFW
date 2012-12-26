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

#import "OFHTTPRequestReply.h"
#import "OFString.h"
#import "OFDataArray.h"
#import "OFDictionary.h"

#import "autorelease.h"
#import "macros.h"

@implementation OFHTTPRequestReply
+ replyWithStatusCode: (short)status
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

	@try {
		statusCode = status;
		headers = [headers_ copy];
		data = [data_ retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

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
