/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#import "OFHTTPClient.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"
#import "OFString.h"
#import "OFTCPSocket.h"
#import "OFThread.h"
#import "OFCondition.h"
#import "OFURL.h"
#import "OFDictionary.h"
#import "OFDataArray.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

static OFString *module = @"OFHTTPClient";
static OFCondition *cond;

@interface HTTPClientTestsServer: OFThread
{
@public
	uint16_t _port;
}
@end

@implementation HTTPClientTestsServer
- main
{
	OFTCPSocket *listener, *client;

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

	if (![[client readLine] isEqual:
	    [OFString stringWithFormat: @"Host: 127.0.0.1:%" @PRIu16, _port]])
		OF_ENSURE(0);

	if (![[client readLine] isEqual: @""])
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
- (void)HTTPClientTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	HTTPClientTestsServer *server;
	OFURL *URL;
	OFHTTPClient *client;
	OFHTTPRequest *request;
	OFHTTPResponse *response = nil;
	OFDataArray *data;

	cond = [OFCondition condition];
	[cond lock];

	server = [[[HTTPClientTestsServer alloc] init] autorelease];
	[server start];

	[cond wait];
	[cond unlock];

	URL = [OFURL URLWithString:
	    [OFString stringWithFormat: @"http://127.0.0.1:%" @PRIu16 "/foo",
					server->_port]];

	TEST(@"-[performRequest:]",
	    (client = [OFHTTPClient client]) &&
	    R(request = [OFHTTPRequest requestWithURL: URL]) &&
	    R(response = [client performRequest: request]))

	TEST(@"Normalization of server header keys",
	    [[response headers] objectForKey: @"Content-Length"] != nil)

	TEST(@"Correct parsing of data",
	    (data = [response readDataArrayTillEndOfStream]) &&
	    [data count] == 7 && !memcmp([data items], "foo\nbar", 7))

	[server join];

	[pool drain];
}
@end
