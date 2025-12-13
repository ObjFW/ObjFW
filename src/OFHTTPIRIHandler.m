/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#import "OFHTTPIRIHandler.h"
#import "OFHTTPClient.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFIRI.h"

@interface OFHTTPIRIHandlerAsyncOpener: OFObject <OFHTTPClientDelegate>
{
	OFIRIHandler *_IRIHandler;
	OFIRI *_IRI;
	id <OFIRIHandlerDelegate> _delegate;
	OFHTTPClient *_client;
}

- (instancetype)initWithIRIHandler: (OFIRIHandler *)IRIHandler
			       IRI: (OFIRI *)IRI
			  delegate: (id <OFIRIHandlerDelegate>)delegate;
- (void)start;
@end

@implementation OFHTTPIRIHandlerAsyncOpener
- (instancetype)initWithIRIHandler: (OFIRIHandler *)IRIHandler
			       IRI: (OFIRI *)IRI
			  delegate: (id <OFIRIHandlerDelegate>)delegate
{
	self = [super init];

	@try {
		_IRIHandler = objc_retain(IRIHandler);
		_IRI = [IRI copy];
		_delegate = objc_retain(delegate);

		_client = [[OFHTTPClient alloc] init];
		_client.delegate = self;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_IRIHandler);
	objc_release(_IRI);
	objc_release(_delegate);
	objc_release(_client);

	[super dealloc];
}

- (void)start
{
	void *pool = objc_autoreleasePoolPush();
	OFHTTPRequest *request = [OFHTTPRequest requestWithIRI: _IRI];

	[_client asyncPerformRequest: request];
	objc_retain(self);

	objc_autoreleasePoolPop(pool);
}

-      (void)client: (OFHTTPClient *)client
  didPerformRequest: (OFHTTPRequest *)request
	   response: (OFHTTPResponse *)response
	  exception: (id)exception
{
	@try {
		[_delegate IRIHandler: _IRIHandler
		     didOpenItemAtIRI: _IRI
			       stream: response
			    exception: exception];
	} @finally {
		objc_release(self);
	}
}
@end

@implementation OFHTTPIRIHandler
- (OF_KINDOF(OFStream *))openItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode
{
	void *pool = objc_autoreleasePoolPush();
	OFHTTPClient *client = [OFHTTPClient client];
	OFHTTPRequest *request = [OFHTTPRequest requestWithIRI: IRI];
	OFHTTPResponse *response = [client performRequest: request];

	objc_retain(response);

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(response);
}

- (void)asyncOpenItemAtIRI: (OFIRI *)IRI
		      mode: (OFString *)mode
		  delegate: (id <OFIRIHandlerDelegate>)delegate
{
	void *pool = objc_autoreleasePoolPush();
	OFHTTPIRIHandlerAsyncOpener *opener = objc_autorelease(
	    [[OFHTTPIRIHandlerAsyncOpener alloc] initWithIRIHandler: self
								IRI: IRI
							   delegate: delegate]);

	[opener start];

	objc_autoreleasePoolPop(pool);
}
@end
