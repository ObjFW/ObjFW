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

#include <errno.h>

#import "OFArchiveURIHandler.h"
#import "OFCharacterSet.h"
#import "OFGZIPStream.h"
#import "OFLHAArchive.h"
#import "OFStream.h"
#import "OFTarArchive.h"
#import "OFURI.h"
#import "OFZIPArchive.h"

#import "OFInvalidArgumentException.h"
#import "OFOpenItemFailedException.h"

@interface OFArchiveURIHandlerPathAllowedCharacterSet: OFCharacterSet
{
	OFCharacterSet *_characterSet;
	bool (*_characterIsMember)(id, SEL, OFUnichar);
}
@end

static OFCharacterSet *pathAllowedCharacters;

static void
initPathAllowedCharacters(void)
{
	pathAllowedCharacters =
	    [[OFArchiveURIHandlerPathAllowedCharacterSet alloc] init];
}

@implementation OFArchiveURIHandler
- (OFStream *)openItemAtURI: (OFURI *)URI mode: (OFString *)mode
{
	void *pool = objc_autoreleasePoolPush();
	OFString *scheme = URI.scheme;
	OFString *percentEncodedPath, *path;
	size_t pos;
	OFURI *archiveURI;
	OFStream *stream;

	if (URI.host != nil || URI.port != nil || URI.user != nil ||
	    URI.password != nil || URI.query != nil || URI.fragment != nil)
		@throw [OFInvalidArgumentException exception];

	if (![mode isEqual: @"r"])
		/*
		 * Writing has some implications that are not decided yet: Will
		 * it always append to an archive? What happens if the file
		 * already exists?
		 */
		@throw [OFInvalidArgumentException exception];

	/*
	 * GZIP only compresses one file and thus has no path inside an
	 * archive.
	 */
	if ([scheme isEqual: @"gzip"]) {
		stream = [OFURIHandler openItemAtURI: [OFURI URIWithString:
							  URI.path]
						mode: @"r"];
		stream = [OFGZIPStream streamWithStream: stream mode: @"r"];
		goto end;
	}

	percentEncodedPath = URI.percentEncodedPath;
	pos = [percentEncodedPath rangeOfString: @"!"].location;

	if (pos == OFNotFound)
		@throw [OFInvalidArgumentException exception];

	archiveURI = [OFURI URIWithString:
	    [percentEncodedPath substringWithRange: OFMakeRange(0, pos)]
	    .stringByRemovingPercentEncoding];
	path = [percentEncodedPath substringWithRange:
	    OFMakeRange(pos + 1, percentEncodedPath.length - pos - 1)]
	    .stringByRemovingPercentEncoding;

	if ([scheme isEqual: @"lha"]) {
		OFLHAArchive *archive = [OFLHAArchive archiveWithURI: archiveURI
								mode: @"r"];
		OFLHAArchiveEntry *entry;

		while ((entry = [archive nextEntry]) != nil) {
			if ([entry.fileName isEqual: path]) {
				stream = [archive streamForReadingCurrentEntry];
				goto end;
			}
		}

		@throw [OFOpenItemFailedException exceptionWithURI: URI
							      mode: mode
							     errNo: ENOENT];
	} else if ([scheme isEqual: @"tar"]) {
		OFTarArchive *archive = [OFTarArchive archiveWithURI: archiveURI
								mode: @"r"];
		OFTarArchiveEntry *entry;

		while ((entry = [archive nextEntry]) != nil) {
			if ([entry.fileName isEqual: path]) {
				stream = [archive streamForReadingCurrentEntry];
				goto end;
			}
		}

		@throw [OFOpenItemFailedException exceptionWithURI: URI
							      mode: mode
							     errNo: ENOENT];
	} else if ([scheme isEqual: @"zip"]) {
		OFZIPArchive *archive = [OFZIPArchive archiveWithURI: archiveURI
								mode: @"r"];

		stream = [archive streamForReadingFile: path];
	} else
		@throw [OFInvalidArgumentException exception];

end:
	stream = [stream retain];

	objc_autoreleasePoolPop(pool);

	return [stream autorelease];
}
@end

@implementation OFArchiveURIHandlerPathAllowedCharacterSet
- (instancetype)init
{
	self = [super init];

	@try {
		_characterSet =
		    [[OFCharacterSet URIPathAllowedCharacterSet] retain];
		_characterIsMember = (bool (*)(id, SEL, OFUnichar))
		    [_characterSet methodForSelector:
		    @selector(characterIsMember:)];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_characterSet release];

	[super dealloc];
}

- (bool)characterIsMember: (OFUnichar)character
{
	return (character != '!' && _characterIsMember(_characterSet,
	    @selector(characterIsMember:), character));
}
@end

OFURI *
OFArchiveURIHandlerURIForFileInArchive(OFString *scheme,
    OFString *pathInArchive, OFURI *archiveURI)
{
	static OFOnceControl onceControl = OFOnceControlInitValue;
	OFMutableURI *ret = [OFMutableURI URI];
	void *pool = objc_autoreleasePoolPush();
	OFString *archiveURIString;

	OFOnce(&onceControl, initPathAllowedCharacters);

	pathInArchive = [pathInArchive
	    stringByAddingPercentEncodingWithAllowedCharacters:
	    pathAllowedCharacters];
	archiveURIString = [archiveURI.string
	    stringByAddingPercentEncodingWithAllowedCharacters:
	    pathAllowedCharacters];

	ret.scheme = scheme;
	ret.percentEncodedPath = [OFString
	    stringWithFormat: @"%@!%@", archiveURIString, pathInArchive];
	[ret makeImmutable];

	objc_autoreleasePoolPop(pool);

	return ret;
}
