/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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
#import "OFLocalization.h"
#import "OFSandbox.h"

#import "OFOpenItemFailedException.h"
#import "OFReadFailedException.h"

@interface OFHash: OFObject <OFApplicationDelegate>
@end

OF_APPLICATION_DELEGATE(OFHash)

static void
help(void)
{
	[of_stderr writeLine: OF_LOCALIZED(@"usage",
	    @"Usage: %[prog] [md5|rmd160|sha1|sha224|sha256|sha384|sha512] "
	    @"file1 [file2 ...]",
	    @"prog", [OFApplication programName])];

	[OFApplication terminateWithStatus: 1];
}

static id <OFCryptoHash>
hashForName(OFString *name)
{
	if ([name isEqual: @"md5"])
		return [OFMD5Hash cryptoHash];
	else if ([name isEqual: @"rmd160"] || [name isEqual: @"ripemd160"])
		return [OFRIPEMD160Hash cryptoHash];
	else if ([name isEqual: @"sha1"])
		return [OFSHA1Hash cryptoHash];
	else if ([name isEqual: @"sha224"])
		return [OFSHA224Hash cryptoHash];
	else if ([name isEqual: @"sha256"])
		return [OFSHA256Hash cryptoHash];
	else if ([name isEqual: @"sha384"])
		return [OFSHA384Hash cryptoHash];
	else if ([name isEqual: @"sha512"])
		return [OFSHA512Hash cryptoHash];

	return nil;
}

@implementation OFHash
- (void)applicationDidFinishLaunching
{
	OFArray OF_GENERIC(OFString *) *arguments = [OFApplication arguments];
	id <OFCryptoHash> hash;
	bool first = true;
	int exitStatus = 0;

#ifdef OF_HAVE_SANDBOX
	OFSandbox *sandbox = [[OFSandbox alloc] init];
	@try {
		[sandbox setAllowsStdIO: true];
		[sandbox setAllowsReadingFiles: true];

		[OFApplication activateSandbox: sandbox];
	} @finally {
		[sandbox release];
	}
#endif

#ifndef OF_MORPHOS
	[OFLocalization addLanguageDirectory: @LANGUAGE_DIR];
#else
	[OFLocalization addLanguageDirectory: @"PROGDIR:/share/ofhash/lang"];
#endif

	if ([arguments count] < 2)
		help();

	if ((hash = hashForName([arguments firstObject])) == nil)
		help();

	for (OFString *path in arguments) {
		void *pool;
		OFStream *file;
		const uint8_t *digest;
		size_t digestSize;

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
						       mode: @"r"];
			} @catch (OFOpenItemFailedException *e) {
				OFString *error = [OFString
				    stringWithCString: strerror([e errNo])
					     encoding: [OFLocalization
							   encoding]];

				[of_stderr writeLine: OF_LOCALIZED(
				    @"failed_to_open_file",
				    @"Failed to open file %[file]: %[error]",
				    @"file", [e path],
				    @"error", error)];

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
				OFString *error = [OFString
				    stringWithCString: strerror([e errNo])
					     encoding: [OFLocalization
							   encoding]];

				[of_stderr writeLine: OF_LOCALIZED(
				    @"failed_to_read_file",
				    @"Failed to read %[file]: %[error]",
				    @"file", path,
				    @"error", error)];

				exitStatus = 1;
				goto outer_loop_end;
			}

			[hash updateWithBuffer: buffer
					length: length];
		}

		[file close];

		digest = [hash digest];
		digestSize = [[hash class] digestSize];

		for (size_t i = 0; i < digestSize; i++)
			[of_stdout writeFormat: @"%02x", digest[i]];

		[of_stdout writeFormat: @"  %@\n", path];

outer_loop_end:
		objc_autoreleasePoolPop(pool);
	}

	[OFApplication terminateWithStatus: exitStatus];
}
@end
