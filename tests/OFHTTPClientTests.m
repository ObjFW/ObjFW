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

#include <inttypes.h>
#include <string.h>

#import "TestsAppDelegate.h"

static OFString *module = @"OFHTTPClient";
static OFCondition *cond;
static OFHTTPResponse *response = nil;

@interface TestsAppDelegate (HTTPClientTests) <OFHTTPClientDelegate>
@end

@interface HTTPClientTestsServer: OFThread
{
@public
	uint16_t _port;
}
@end

@implementation HTTPClientTestsServer
- (id)main
{
	OFTCPSocket *listener, *client;
	char buffer[5];

	[cond lock];

	listener = [OFTCPSocket socket];
	_port = [listener bindToHost: @"127.0.0.1"
				port: 0];
	[listener listen];

	[cond signal];
	[cond unlock];

	client = [listener accept];

	if (![[client readLine] isEqual: @"GET /foo HTTP/1.1"])
		OF_ENSURE(0);

	if (![[client readLine] hasPrefix: @"User-Agent:"])
		OF_ENSURE(0);

	if (![[client readLine] isEqual: @"Content-Length: 5"])
		OF_ENSURE(0);

	if (![[client readLine] isEqual:
	    @"Content-Type: application/x-www-form-urlencoded; charset=UTF-8"])
		OF_ENSURE(0);

	if (![[client readLine] isEqual:
	    [OFString stringWithFormat: @"Host: 127.0.0.1:%" @PRIu16, _port]])
		OF_ENSURE(0);

	if (![[client readLine] isEqual: @""])
		OF_ENSURE(0);

	[client readIntoBuffer: buffer
		   exactLength: 5];
	if (memcmp(buffer, "Hello", 5) != 0)
		OF_ENSURE(0);

	[client writeString: @"HTTP/1.0 200 OK\r\n"
			     @"cONTeNT-lENgTH: 7\r\n"
			     @"\r\n"
			     @"foo\n"
			     @"bar"];
	[client close];

	return nil;
}
@end

@implementation TestsAppDelegate (OFHTTPClientTests)
-     (void)client: (OFHTTPClient *)client
  wantsRequestBody: (OFStream *)body
	   request: (OFHTTPRequest *)request
{
	[body writeString: @"Hello"];
}

-      (void)client: (OFHTTPClient *)client
  didPerformRequest: (OFHTTPRequest *)request
	   response: (OFHTTPResponse *)response_
{
	response = [response_ retain];

	[[OFRunLoop mainRunLoop] stop];
}

- (void)HTTPClientTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	HTTPClientTestsServer *server;
	OFURL *URL;
	OFHTTPClient *client;
	OFHTTPRequest *request;
	OFData *data;

	cond = [OFCondition condition];
	[cond lock];

	server = [[[HTTPClientTestsServer alloc] init] autorelease];
	server.supportsSockets = true;
	[server start];

	[cond wait];
	[cond unlock];

	URL = [OFURL URLWithString:
	    [OFString stringWithFormat: @"http://127.0.0.1:%" @PRIu16 "/foo",
					server->_port]];

	TEST(@"-[asyncPerformRequest:]",
	    (client = [OFHTTPClient client]) && (client.delegate = self) &&
	    (request = [OFHTTPRequest requestWithURL: URL]) &&
	    (request.headers =
	    [OFDictionary dictionaryWithObject: @"5"
					forKey: @"Content-Length"]) &&
	    R([client asyncPerformRequest: request]))

	[[OFRunLoop mainRunLoop] runUntilDate:
	    [OFDate dateWithTimeIntervalSinceNow: 2]];
	[response autorelease];

	TEST(@"Asynchronous handling of requests", response != nil)

	TEST(@"Normalization of server header keys",
	    [response.headers objectForKey: @"Content-Length"] != nil)

	TEST(@"Correct parsing of data",
	    (data = [response readDataUntilEndOfStream]) &&
	    data.count == 7 && memcmp(data.items, "foo\nbar", 7) == 0)

	[server join];

	[pool drain];
}
@end
