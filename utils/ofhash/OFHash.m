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

#import "OFApplication.h"
#import "OFArray.h"
#import "OFFile.h"
#import "OFLocale.h"
#import "OFMD5Hash.h"
#import "OFOptionsParser.h"
#import "OFRIPEMD160Hash.h"
#import "OFSHA1Hash.h"
#import "OFSHA224Hash.h"
#import "OFSHA256Hash.h"
#import "OFSHA384Hash.h"
#import "OFSHA512Hash.h"
#import "OFSandbox.h"
#import "OFSecureData.h"
#import "OFStdIOStream.h"

#import "OFOpenItemFailedException.h"
#import "OFReadFailedException.h"

@interface OFHash: OFObject <OFApplicationDelegate>
@end

OF_APPLICATION_DELEGATE(OFHash)

static void
help(void)
{
	[of_stderr writeLine: OF_LOCALIZED(@"usage",
	    @"Usage: %[prog] [--md5|--ripemd160|--sha1|--sha224|--sha256|"
	    @"--sha384|--sha512] file1 [file2 ...]",
	    @"prog", [OFApplication programName])];

	[OFApplication terminateWithStatus: 1];
}

static void
printHash(OFString *algo, OFString *path, id <OFCryptoHash> hash)
{
	const unsigned char *digest = hash.digest;
	size_t digestSize = hash.digestSize;

	[of_stdout writeFormat: @"%@ ", algo];

	for (size_t i = 0; i < digestSize; i++)
		[of_stdout writeFormat: @"%02x", digest[i]];

	[of_stdout writeFormat: @"  %@\n", path];
}

@implementation OFHash
- (void)applicationDidFinishLaunching
{
	int exitStatus = 0;
	bool calculateMD5, calculateRIPEMD160, calculateSHA1, calculateSHA224;
	bool calculateSHA256, calculateSHA384, calculateSHA512;
	const of_options_parser_option_t options[] = {
		{ '\0', @"md5", 0, &calculateMD5, NULL },
		{ '\0', @"ripemd160", 0, &calculateRIPEMD160, NULL },
		{ '\0', @"sha1", 0, &calculateSHA1, NULL },
		{ '\0', @"sha224", 0, &calculateSHA224, NULL },
		{ '\0', @"sha256", 0, &calculateSHA256, NULL },
		{ '\0', @"sha384", 0, &calculateSHA384, NULL },
		{ '\0', @"sha512", 0, &calculateSHA512, NULL },
		{ '\0', nil, 0, NULL, NULL }
	};
	OFOptionsParser *optionsParser =
	    [OFOptionsParser parserWithOptions: options];
	of_unichar_t option;
	OFMD5Hash *MD5Hash = nil;
	OFRIPEMD160Hash *RIPEMD160Hash = nil;
	OFSHA1Hash *SHA1Hash = nil;
	OFSHA224Hash *SHA224Hash = nil;
	OFSHA256Hash *SHA256Hash = nil;
	OFSHA384Hash *SHA384Hash = nil;
	OFSHA512Hash *SHA512Hash = nil;

	while ((option = [optionsParser nextOption]) != '\0') {
		switch (option) {
		case '?':
			if (optionsParser.lastLongOption != nil)
				[of_stderr writeLine:
				    OF_LOCALIZED(@"unknown_long_option",
				    @"%[prog]: Unknown option: --%[opt]",
				    @"prog", [OFApplication programName],
				    @"opt", optionsParser.lastLongOption)];
			else {
				OFString *optStr = [OFString stringWithFormat:
				    @"%c", optionsParser.lastOption];
				[of_stderr writeLine:
				    OF_LOCALIZED(@"unkown_option",
				    @"%[prog]: Unknown option: -%[opt]",
				    @"prog", [OFApplication programName],
				    @"opt", optStr)];
			}

			[OFApplication terminateWithStatus: 1];
			break;
		}
	}

	if (calculateMD5)
		MD5Hash = [OFMD5Hash cryptoHash];
	if (calculateRIPEMD160)
		RIPEMD160Hash = [OFRIPEMD160Hash cryptoHash];
	if (calculateSHA1)
		SHA1Hash = [OFSHA1Hash cryptoHash];
	if (calculateSHA224)
		SHA224Hash = [OFSHA224Hash cryptoHash];
	if (calculateSHA256)
		SHA256Hash = [OFSHA256Hash cryptoHash];
	if (calculateSHA384)
		SHA384Hash = [OFSHA384Hash cryptoHash];
	if (calculateSHA512)
		SHA512Hash = [OFSHA512Hash cryptoHash];

#ifdef OF_HAVE_SANDBOX
	OFSandbox *sandbox = [OFSandbox sandbox];
	@try {
		sandbox.allowsStdIO = true;
		sandbox.allowsReadingFiles = true;
		sandbox.allowsUserDatabaseReading = true;

		for (OFString *path in optionsParser.remainingArguments)
			[sandbox unveilPath: path
				permissions: @"r"];

		[sandbox unveilPath: @LANGUAGE_DIR
			permissions: @"r"];

		[OFApplication activateSandbox: sandbox];
	} @finally {
		[sandbox release];
	}
#endif

#ifndef OF_AMIGAOS
	[OFLocale addLanguageDirectory: @LANGUAGE_DIR];
#else
	[OFLocale addLanguageDirectory: @"PROGDIR:/share/ofhash/lang"];
#endif

	if (!calculateMD5 && !calculateRIPEMD160 && !calculateSHA1 &&
	    !calculateSHA224 && !calculateSHA256 && !calculateSHA384 &&
	    !calculateSHA512)
		help();

	if (optionsParser.remainingArguments.count < 1)
		help();

	for (OFString *path in optionsParser.remainingArguments) {
		void *pool = objc_autoreleasePoolPush();
		OFStream *file;

		if ([path isEqual: @"-"])
			file = of_stdin;
		else {
			@try {
				file = [OFFile fileWithPath: path
						       mode: @"r"];
			} @catch (OFOpenItemFailedException *e) {
				OFString *error = [OFString
				    stringWithCString: strerror(e.errNo)
					     encoding: [OFLocale encoding]];

				[of_stderr writeLine: OF_LOCALIZED(
				    @"failed_to_open_file",
				    @"Failed to open file %[file]: %[error]",
				    @"file", e.path,
				    @"error", error)];

				exitStatus = 1;
				goto outer_loop_end;
			}
		}

		[MD5Hash reset];
		[RIPEMD160Hash reset];
		[SHA1Hash reset];
		[SHA224Hash reset];
		[SHA256Hash reset];
		[SHA384Hash reset];
		[SHA512Hash reset];

		while (!file.atEndOfStream) {
			uint8_t buffer[1024];
			size_t length;

			@try {
				length = [file readIntoBuffer: buffer
						       length: 1024];
			} @catch (OFReadFailedException *e) {
				OFString *error = [OFString
				    stringWithCString: strerror(e.errNo)
					     encoding: [OFLocale encoding]];

				[of_stderr writeLine: OF_LOCALIZED(
				    @"failed_to_read_file",
				    @"Failed to read %[file]: %[error]",
				    @"file", path,
				    @"error", error)];

				exitStatus = 1;
				goto outer_loop_end;
			}

			if (calculateMD5)
				[MD5Hash updateWithBuffer: buffer
						   length: length];
			if (calculateRIPEMD160)
				[RIPEMD160Hash updateWithBuffer: buffer
							 length: length];
			if (calculateSHA1)
				[SHA1Hash updateWithBuffer: buffer
						    length: length];
			if (calculateSHA224)
				[SHA224Hash updateWithBuffer: buffer
						      length: length];
			if (calculateSHA256)
				[SHA256Hash updateWithBuffer: buffer
						      length: length];
			if (calculateSHA384)
				[SHA384Hash updateWithBuffer: buffer
						      length: length];
			if (calculateSHA512)
				[SHA512Hash updateWithBuffer: buffer
						      length: length];
		}

		[file close];

		if (calculateMD5)
			printHash(@"MD5", path, MD5Hash);
		if (calculateRIPEMD160)
			printHash(@"RIPEMD160", path, RIPEMD160Hash);
		if (calculateSHA1)
			printHash(@"SHA1", path, SHA1Hash);
		if (calculateSHA224)
			printHash(@"SHA224", path, SHA224Hash);
		if (calculateSHA256)
			printHash(@"SHA256", path, SHA256Hash);
		if (calculateSHA384)
			printHash(@"SHA384", path, SHA384Hash);
		if (calculateSHA512)
			printHash(@"SHA512", path, SHA512Hash);

outer_loop_end:
		objc_autoreleasePoolPop(pool);
	}

	[OFApplication terminateWithStatus: exitStatus];
}
@end
