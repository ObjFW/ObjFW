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

#import "OFApplication.h"
#import "OFArray.h"
#import "OFFile.h"
#import "OFMD5Hash.h"
#import "OFRIPEMD160Hash.h"
#import "OFSHA1Hash.h"
#import "OFSHA224Hash.h"
#import "OFSHA256Hash.h"
#import "OFSHA384Hash.h"
#import "OFSHA512Hash.h"
#import "OFStdIOStream.h"

#import "OFOpenItemFailedException.h"
#import "OFReadFailedException.h"

@interface OFHash: OFObject
@end

OF_APPLICATION_DELEGATE(OFHash)

static void
help(void)
{
	[of_stderr writeFormat:
	    @"Usage: %@ [md5|rmd160|sha1|sha224|sha256|sha384|sha512] "
	    @"file1 [file2 ...]\n",
	    [OFApplication programName]];

	[OFApplication terminateWithStatus: 1];
}

static id <OFHash>
hashForName(OFString *name)
{
	if ([name isEqual: @"md5"])
		return [OFMD5Hash hash];
	else if ([name isEqual: @"rmd160"] || [name isEqual: @"ripemd160"])
		return [OFRIPEMD160Hash hash];
	else if ([name isEqual: @"sha1"])
		return [OFSHA1Hash hash];
	else if ([name isEqual: @"sha224"])
		return [OFSHA224Hash hash];
	else if ([name isEqual: @"sha256"])
		return [OFSHA256Hash hash];
	else if ([name isEqual: @"sha384"])
		return [OFSHA384Hash hash];
	else if ([name isEqual: @"sha512"])
		return [OFSHA512Hash hash];

	return nil;
}

@implementation OFHash
- (void)applicationDidFinishLaunching
{
	OFArray OF_GENERIC(OFString*) *arguments = [OFApplication arguments];
	id <OFHash> hash;
	bool first = true;
	int exitStatus = 0;

	if ([arguments count] < 2)
		help();

	if ((hash = hashForName([arguments firstObject])) == nil)
		help();

	for (OFString *path in arguments) {
		void *pool;
		OFStream *file;
		const uint8_t *digest;
		size_t i, digestSize;

		if (first) {
			first = false;
			continue;
		}

		pool = objc_autoreleasePoolPush();

		if ([path isEqual: @"-"])
			file = of_stdin;
		else {
			@try {
				file = [OFFile fileWithPath: path
						       mode: @"rb"];
			} @catch (OFOpenItemFailedException *e) {
				[of_stderr writeFormat:
				    @"Failed to open file %@: %s\n",
				    [e path], strerror([e errNo])];

				exitStatus = 1;
				goto outer_loop_end;
			}
		}

		[hash reset];

		while (![file isAtEndOfStream]) {
			uint8_t buffer[1024];
			size_t length;

			@try {
				length = [file readIntoBuffer: buffer
						       length: 1024];
			} @catch (OFReadFailedException *e) {
				[of_stderr writeFormat:
				    @"Failed to read %@: %s\n",
				    path, strerror([e errNo])];

				exitStatus = 1;
				goto outer_loop_end;
			}

			[hash updateWithBuffer: buffer
					length: length];
		}

		[file close];

		digest = [hash digest];
		digestSize = [[hash class] digestSize];

		for (i = 0; i < digestSize; i++)
			[of_stdout writeFormat: @"%02x", digest[i]];

		[of_stdout writeFormat: @"  %@\n", path];

outer_loop_end:
		objc_autoreleasePoolPop(pool);
	}

	[OFApplication terminateWithStatus: exitStatus];
}
@end
