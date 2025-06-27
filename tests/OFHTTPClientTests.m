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

#include <inttypes.h>
#include <string.h>

#import "ObjFW.h"
#import "ObjFWTest.h"

@interface OFHTTPClientTests: OTTestCase <OFHTTPClientDelegate>
{
	OFHTTPResponse *_response;
}
@end

@interface HTTPClientTestsServer: OFThread
{
	OFCondition *_condition;
	uint16_t _port;
}

@property (readonly, nonatomic) OFCondition *condition;
@property (readonly) uint16_t port;
@end

@implementation OFHTTPClientTests
- (void)dealloc
{
	objc_release(_response);

	[super dealloc];
}

-     (void)client: (OFHTTPClient *)client
  wantsRequestBody: (OFStream *)body
	   request: (OFHTTPRequest *)request
{
	[body writeString: @"Hello"];
}

-      (void)client: (OFHTTPClient *)client
  didPerformRequest: (OFHTTPRequest *)request
	   response: (OFHTTPResponse *)response_
	  exception: (id)exception
{
	OTAssertNil(exception);

	objc_release(_response);
	_response = objc_retain(response_);

	[[OFRunLoop mainRunLoop] stop];
}

- (void)testClient
{
	HTTPClientTestsServer *server;
	OFIRI *IRI;
	OFHTTPRequest *request;
	OFHTTPClient *client;
	OFData *data;

	server = objc_autorelease([[HTTPClientTestsServer alloc] init]);
	server.supportsSockets = true;

	[server.condition lock];

	[server start];

	[server.condition wait];
	[server.condition unlock];

	IRI = [OFIRI IRIWithString:
	    [OFString stringWithFormat: @"http://127.0.0.1:%" @PRIu16 "/foo",
					server.port]];

	request = [OFHTTPRequest requestWithIRI: IRI];
	request.headers = [OFDictionary
	    dictionaryWithObject: @"5"
			  forKey: @"Content-Length"];

	client = [OFHTTPClient client];
	client.delegate = self;
	[client asyncPerformRequest: request];

	[[OFRunLoop mainRunLoop] runUntilDate:
	    [OFDate dateWithTimeIntervalSinceNow: 2]];

	OTAssertNotNil(_response);
	OTAssertNotNil([_response.headers objectForKey: @"Content-Length"]);

	data = [_response readDataUntilEndOfStream];
	OTAssertEqual(data.count, 7);
	OTAssertEqual(data.itemSize, 1);
	OTAssertEqual(memcmp(data.items, "foo\nbar", 7), 0);

	OTAssertNil([server join]);
}
@end

@implementation HTTPClientTestsServer
@synthesize condition = _condition, port = _port;

- (instancetype)init
{
	self = [super init];

	@try {
		_condition = [[OFCondition alloc] init];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_condition);

	[super dealloc];
}

- (id)main
{
	OFTCPSocket *listener, *client;
	OFSocketAddress address;
	bool sawHost = false, sawContentLength = false, sawContentType = false;
	bool sawUserAgent = false;
	char buffer[5];

	[_condition lock];

	listener = [OFTCPSocket socket];
	listener.allowsMPTCP = true;
	address = [listener bindToHost: @"127.0.0.1" port: 0];
	_port = OFSocketAddressIPPort(&address);
	[listener listen];

	[_condition signal];
	[_condition unlock];
	client = [listener accept];

	if (![[client readLine] isEqual: @"GET /foo HTTP/1.1"])
		return @"Wrong request";

	for (size_t i = 0; i < 4; i++) {
		OFString *line = [client readLine];

		if ([line isEqual: [OFString stringWithFormat:
		    @"Host: 127.0.0.1:%" @PRIu16, _port]])
			sawHost = true;
		else if ([line isEqual: @"Content-Length: 5"])
			sawContentLength = true;
		if ([line isEqual: @"Content-Type: application/"
		    @"x-www-form-urlencoded; charset=UTF-8"])
			sawContentType = true;
		else if ([line hasPrefix: @"User-Agent:"])
			sawUserAgent = true;
	}

	if (!sawHost)
		return @"Missing host";
	if (!sawContentLength)
		return @"Missing content length";
	if (!sawContentType)
		return @"Missing content type";
	if (!sawUserAgent)
		return @"Missing user agent";

	if (![[client readLine] isEqual: @""])
		return @"Missing empty line";

	[client readIntoBuffer: buffer exactLength: 5];
	if (memcmp(buffer, "Hello", 5) != 0)
		return @"Missing body";

	[client writeString: @"HTTP/1.0 200 OK\r\n"
			     @"cONTeNT-lENgTH: 7\r\n"
			     @"\r\n"
			     @"foo\n"
			     @"bar"];
	[client close];

	return nil;
}
@end
