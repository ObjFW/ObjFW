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

#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <assert.h>

#import "OFHTTPClient.h"
#import "OFHTTPRequest.h"
#import "OFHTTPRequestReply.h"
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

@interface OFHTTPClientTestsServer: OFThread
{
@public
	uint16_t port;
}
@end

@implementation OFHTTPClientTestsServer
- main
{
	OFTCPSocket *listener, *client;

	[cond lock];

	listener = [OFTCPSocket socket];
	port = [listener bindToHost: @"127.0.0.1"
			       port: 0];
	[listener listen];

	[cond signal];
	[cond unlock];

	client = [listener accept];

	if (![[client readLine] isEqual: @"GET /foo HTTP/1.1"])
		assert(0);

	if (![[client readLine] isEqual:
	    [OFString stringWithFormat: @"Host: 127.0.0.1:%" @PRIu16, port]])
		assert(0);

	if (![[client readLine] isEqual: @"Connection: close"])
		assert(0);

	if (![[client readLine] hasPrefix: @"User-Agent:"])
		assert(0);

	if (![[client readLine] isEqual: @""])
		assert(0);

	[client writeString: @"HTTP/1.1 200 OK\r\n"
			     @"cONTeNT-lENgTH: 7\r\n"
			     @"\r\n"
			     @"foo\n"
			     @"bar"];
	[client close];

	return nil;
}
@end

@implementation TestsAppDelegate (OFHTTPClientests)
- (void)HTTPClientTests
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	OFHTTPClientTestsServer *server;
	OFURL *url;
	OFHTTPClient *client;
	OFHTTPRequest *request;
	OFHTTPRequestReply *reply = nil;
	OFDataArray *data;

	cond = [OFCondition condition];
	[cond lock];

	server = [[[OFHTTPClientTestsServer alloc] init] autorelease];
	[server start];

	[cond wait];
	[cond unlock];

	url = [OFURL URLWithString:
	    [OFString stringWithFormat: @"http://127.0.0.1:%" @PRIu16 "/foo",
					server->port]];

	TEST(@"-[performRequest:]",
	    (client = [OFHTTPClient client]) &&
	    R(request = [OFHTTPRequest requestWithURL: url]) &&
	    R(reply = [client performRequest: request]))

	TEST(@"Normalization of server header keys",
	    ([[reply headers] objectForKey: @"Content-Length"] != nil))

	TEST(@"Correct parsing of data",
	    (data = [reply readDataArrayTillEndOfStream]) &&
	    [data count] == 7 && !memcmp([data items], "foo\nbar", 7))

	[server join];

	[pool drain];
}
@end
