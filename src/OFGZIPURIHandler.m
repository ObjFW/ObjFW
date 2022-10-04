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

#import "OFGZIPURIHandler.h"
#import "OFGZIPStream.h"
#import "OFStream.h"
#import "OFURI.h"

#import "OFInvalidArgumentException.h"

@implementation OFGZIPURIHandler
- (OFStream *)openItemAtURI: (OFURI *)URI mode: (OFString *)mode
{
	void *pool = objc_autoreleasePoolPush();
	OFStream *stream;

	if (![URI.scheme isEqual: @"of-gzip"] || URI.host != nil ||
	    URI.port != nil || URI.user != nil || URI.password != nil ||
	    URI.query != nil || URI.fragment != nil)
		@throw [OFInvalidArgumentException exception];

	if (![mode isEqual: @"r"])
		@throw [OFInvalidArgumentException exception];

	stream = [OFURIHandler openItemAtURI: [OFURI URIWithString: URI.path]
					mode: @"r"];
	stream = [OFGZIPStream streamWithStream: stream mode: @"r"];

	[stream retain];

	objc_autoreleasePoolPop(pool);

	return [stream autorelease];
}
@end
