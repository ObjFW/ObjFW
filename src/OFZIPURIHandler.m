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

#import "OFZIPURIHandler.h"
#import "OFStream.h"
#import "OFURI.h"
#import "OFZIPArchive.h"

#import "OFInvalidArgumentException.h"

@implementation OFZIPURIHandler
- (OFStream *)openItemAtURI: (OFURI *)URI mode: (OFString *)mode
{
	void *pool = objc_autoreleasePoolPush();
	OFString *percentEncodedPath, *archiveURI, *path;
	size_t pos;
	OFZIPArchive *archive;
	OFStream *stream;

	if (![URI.scheme isEqual: @"of-zip"] || URI.host != nil ||
	    URI.port != nil || URI.user != nil || URI.password != nil ||
	    URI.query != nil || URI.fragment != nil)
		@throw [OFInvalidArgumentException exception];

	if (![mode isEqual: @"r"])
		/*
		 * Writing has some implications that are not decided yet: Will
		 * it always append to an archive? What happens if the file
		 * already exists?
		 */
		@throw [OFInvalidArgumentException exception];

	percentEncodedPath = URI.percentEncodedPath;
	pos = [percentEncodedPath rangeOfString: @"!"].location;

	if (pos == OFNotFound)
		@throw [OFInvalidArgumentException exception];

	archiveURI = [percentEncodedPath substringWithRange:
	    OFMakeRange(0, pos)].stringByRemovingPercentEncoding;
	path = [percentEncodedPath substringWithRange:
	    OFMakeRange(pos + 1, percentEncodedPath.length - pos - 1)]
	    .stringByRemovingPercentEncoding;

	archive = [OFZIPArchive
	    archiveWithURI: [OFURI URIWithString: archiveURI]
		      mode: @"r"];
	stream = [archive streamForReadingFile: path];

	[stream retain];

	objc_autoreleasePoolPop(pool);

	return [stream autorelease];
}
@end
