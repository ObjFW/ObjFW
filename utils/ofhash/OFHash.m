/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#import "OFApplication.h"
#import "OFArray.h"
#import "OFFile.h"
#import "OFIRI.h"
#import "OFIRIHandler.h"
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

#ifdef HAVE_TLS_SUPPORT
# import "ObjFWTLS.h"
#endif

#import "OFOpenItemFailedException.h"
#import "OFReadFailedException.h"

#ifdef OF_AMIGAOS
const char *version =
    "$VER: ofhash " OF_PREPROCESSOR_STRINGIFY(OBJFW_VERSION_MAJOR) "."
    OF_PREPROCESSOR_STRINGIFY(OBJFW_VERSION_MINOR) " (" BUILD_DATE ") "
    "\xA9 2008-2025 Jonathan Schleifer";
#endif

@interface OFHash: OFObject <OFApplicationDelegate>
@end

#ifdef HAVE_TLS_SUPPORT
void
_reference_to_ObjFWTLS(void)
{
	_ObjFWTLS_reference = 1;
}
#endif

OF_APPLICATION_DELEGATE(OFHash)

static void
help(void)
{
	[OFStdErr writeLine: OF_LOCALIZED(@"usage",
	    @"Usage: %[prog] [--md5] [--ripemd160] [--sha1] [--sha224] "
	    @"[--sha256] [--sha384] [--sha512] [--iri] file1 [file2 ...]",
	    @"prog", [OFApplication programName])];

	[OFApplication terminateWithStatus: 1];
}

static void
printHash(OFString *algo, OFString *path, id <OFCryptographicHash> hash)
{
	size_t digestSize = hash.digestSize;
	const unsigned char *digest;

	[hash calculate];
	digest = hash.digest;

	[OFStdOut writeFormat: @"%@ ", algo];

	for (size_t i = 0; i < digestSize; i++)
		[OFStdOut writeFormat: @"%02x", digest[i]];

	[OFStdOut writeFormat: @"  %@\n", path];
}

@implementation OFHash
- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	int exitStatus = 0;
	bool calculateMD5, calculateRIPEMD160, calculateSHA1, calculateSHA224;
	bool calculateSHA256, calculateSHA384, calculateSHA512, isIRI;
	const OFOptionsParserOption options[] = {
		{ '\0', @"md5", 0, &calculateMD5, NULL },
		{ '\0', @"ripemd160", 0, &calculateRIPEMD160, NULL },
		{ '\0', @"rmd160", 0, &calculateRIPEMD160, NULL },
		{ '\0', @"sha1", 0, &calculateSHA1, NULL },
		{ '\0', @"sha224", 0, &calculateSHA224, NULL },
		{ '\0', @"sha256", 0, &calculateSHA256, NULL },
		{ '\0', @"sha384", 0, &calculateSHA384, NULL },
		{ '\0', @"sha512", 0, &calculateSHA512, NULL },
		{ '\0', @"iri", 0, &isIRI, NULL },
		{ '\0', nil, 0, NULL, NULL }
	};
	OFOptionsParser *optionsParser =
	    [OFOptionsParser parserWithOptions: options];
	OFUnichar option;
	OFMD5Hash *MD5Hash = nil;
	OFRIPEMD160Hash *RIPEMD160Hash = nil;
	OFSHA1Hash *SHA1Hash = nil;
	OFSHA224Hash *SHA224Hash = nil;
	OFSHA256Hash *SHA256Hash = nil;
	OFSHA384Hash *SHA384Hash = nil;
	OFSHA512Hash *SHA512Hash = nil;

#ifndef OF_AMIGAOS
	[OFLocale addLocalizationDirectoryIRI:
	    [OFIRI fileIRIWithPath: @LOCALIZATION_DIR]];
#else
	[OFLocale addLocalizationDirectoryIRI:
	    [OFIRI fileIRIWithPath: @"PROGDIR:/share/ofhash/localization"]];
#endif

	while ((option = [optionsParser nextOption]) != '\0') {
		switch (option) {
		case '?':
			if (optionsParser.lastLongOption != nil)
				[OFStdErr writeLine: OF_LOCALIZED(
				    @"unknown_long_option",
				    @"%[prog]: Unknown option: --%[opt]",
				    @"prog", [OFApplication programName],
				    @"opt", optionsParser.lastLongOption)];
			else {
				OFString *optStr = [OFString stringWithFormat:
				    @"%C", optionsParser.lastOption];
				[OFStdErr writeLine: OF_LOCALIZED(
				    @"unknown_option",
				    @"%[prog]: Unknown option: -%[opt]",
				    @"prog", [OFApplication programName],
				    @"opt", optStr)];
			}

			[OFApplication terminateWithStatus: 1];
			break;
		}
	}

#ifdef OF_HAVE_SANDBOX
	OFSandbox *sandbox = [OFSandbox sandbox];
	@try {
		sandbox.allowsStdIO = true;
		sandbox.allowsReadingFiles = true;
		sandbox.allowsUserDatabaseReading = true;

		if (!isIRI)
			for (OFString *path in optionsParser.remainingArguments)
				[sandbox unveilPath: path permissions: @"r"];

		[sandbox unveilPath: @LOCALIZATION_DIR permissions: @"r"];

		[OFApplication of_activateSandbox: sandbox];
	} @finally {
		objc_release(sandbox);
	}
#endif

	if (!calculateMD5 && !calculateRIPEMD160 && !calculateSHA1 &&
	    !calculateSHA224 && !calculateSHA256 && !calculateSHA384 &&
	    !calculateSHA512)
		help();

	if (optionsParser.remainingArguments.count < 1)
		help();

	if (calculateMD5)
		MD5Hash = [OFMD5Hash hashWithAllowsSwappableMemory: true];
	if (calculateRIPEMD160)
		RIPEMD160Hash =
		    [OFRIPEMD160Hash hashWithAllowsSwappableMemory: true];
	if (calculateSHA1)
		SHA1Hash = [OFSHA1Hash hashWithAllowsSwappableMemory: true];
	if (calculateSHA224)
		SHA224Hash = [OFSHA224Hash hashWithAllowsSwappableMemory: true];
	if (calculateSHA256)
		SHA256Hash = [OFSHA256Hash hashWithAllowsSwappableMemory: true];
	if (calculateSHA384)
		SHA384Hash = [OFSHA384Hash hashWithAllowsSwappableMemory: true];
	if (calculateSHA512)
		SHA512Hash = [OFSHA512Hash hashWithAllowsSwappableMemory: true];

	for (OFString *path in optionsParser.remainingArguments) {
		void *pool = objc_autoreleasePoolPush();
		OFStream *file;

		if (!isIRI && [path isEqual: @"-"])
			file = OFStdIn;
		else {
			@try {
				if (isIRI) {
					OFIRI *IRI =
					    [OFIRI IRIWithString: path];

					file = [OFIRIHandler
					    openItemAtIRI: IRI
						     mode: @"r"];
				} else
					file = [OFFile fileWithPath: path
							       mode: @"r"];
			} @catch (OFOpenItemFailedException *e) {
				OFString *error = [OFString
				    stringWithCString: strerror(e.errNo)
					     encoding: [OFLocale encoding]];
				OFString *filePath =
				    (e.IRI != nil ? e.IRI.string : e.path);

				[OFStdErr writeLine: OF_LOCALIZED(
				    @"failed_to_open_file",
				    @"Failed to open file %[file]: %[error]",
				    @"file", filePath,
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

				[OFStdErr writeLine: OF_LOCALIZED(
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
