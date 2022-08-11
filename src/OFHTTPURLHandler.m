/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFHTTPURLHandler.h"
#import "OFHTTPClient.h"
#import "OFHTTPRequest.h"
#import "OFHTTPResponse.h"

@implementation OFHTTPURLHandler
- (OFStream *)openItemAtURL: (OFURL *)URL mode: (OFString *)mode
{
	void *pool = objc_autoreleasePoolPush();
	OFHTTPClient *client = [OFHTTPClient client];
	OFHTTPRequest *request = [OFHTTPRequest requestWithURL: URL];
	OFHTTPResponse *response = [client performRequest: request];

	[response retain];

	objc_autoreleasePoolPop(pool);

	return [response autorelease];
}
@end
