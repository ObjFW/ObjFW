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

#import "OFApplication.h"
#import "OFArray.h"
#import "OFDate.h"
#import "OFDictionary.h"
#import "OFFile.h"
#import "OFOptionsParser.h"
#import "OFSet.h"
#import "OFStdIOStream.h"
#import "OFZIPArchive.h"
#import "OFZIPArchiveEntry.h"

#import "autorelease.h"
#import "macros.h"

#define BUFFER_SIZE 4096

@interface OFZIP: OFObject
- (void)listFilesInArchive: (OFZIPArchive*)archive
		   verbose: (bool)verbose;
- (void)extractFiles: (OFArray*)files
	 fromArchive: (OFZIPArchive*)archive
	    override: (int_fast8_t)override;
@end

OF_APPLICATION_DELEGATE(OFZIP)

static void
help(OFStream *stream, bool full, int status)
{
	[stream writeFormat:
	    @"Usage: %@ -[flnvx] archive.zip [file1 file2 ...]\n",
	    [OFApplication programName]];

	if (full) {
		[stream writeString: @"\nOptions:\n"
				     @"    -f  Force / override files\n"
				     @"    -h  Show this help\n"
				     @"    -l  List all files in the archive\n"
				     @"    -n  Never override files\n"
				     @"    -v  Verbose output for file list\n"
				     @"    -x  Extract files\n"];
	}

	[OFApplication terminateWithStatus: status];
}

@implementation OFZIP
- (void)applicationDidFinishLaunching
{
	OFOptionsParser *optionsParser =
	    [OFOptionsParser parserWithOptions: @"fhlnvx"];
	of_unichar_t option, mode = '\0';
	int_fast8_t override = 0;
	bool verbose = false;
	OFArray *remainingArguments;
	OFZIPArchive *archive;
	OFArray *files;

	while ((option = [optionsParser nextOption]) != '\0') {
		switch (option) {
		case 'f':
			override = 1;
			break;
		case 'n':
			override = -1;
			break;
		case 'v':
			verbose = true;
			break;
		case 'l':
		case 'x':
			if (mode != '\0')
				help(of_stdout, false, 1);

			mode = option;
			break;
		case 'h':
			help(of_stdout, true, 0);
			break;
		default:
			[of_stderr writeFormat: @"%@: Unknown option: -%c\n",
						[OFApplication programName],
						[optionsParser lastOption]];
			[OFApplication terminateWithStatus: 1];
		}
	}

	remainingArguments = [optionsParser remainingArguments];

	switch (mode) {
	case 'l':
		if ([remainingArguments count] != 1)
			help(of_stderr, false, 1);

		archive = [OFZIPArchive archiveWithPath:
		    [remainingArguments firstObject]];

		[self listFilesInArchive: archive
				 verbose: verbose];
		break;
	case 'x':
		if ([remainingArguments count] < 1)
			help(of_stderr, false, 1);

		files = [remainingArguments objectsInRange:
		    of_range(1, [remainingArguments count] - 1)];
		archive = [OFZIPArchive archiveWithPath:
		    [remainingArguments firstObject]];

		[self extractFiles: files
		       fromArchive: archive
			  override: override];
		break;
	default:
		help(of_stderr, true, 1);
		break;
	}

	[OFApplication terminate];
}

- (void)listFilesInArchive: (OFZIPArchive*)archive
		   verbose: (bool)verbose
{
	OFEnumerator *enumerator = [[archive entries] objectEnumerator];
	OFZIPArchiveEntry *entry;

	while ((entry = [enumerator nextObject]) != nil) {
		void *pool = objc_autoreleasePoolPush();

		if (verbose) {
			OFString *date = [[entry modificationDate]
			    localDateStringWithFormat: @"%Y-%m-%d %H:%M:%S"];

			[of_stdout writeFormat:
			    @"%@: %ju (%ju) bytes; %08X; %@; %@\n",
			    [entry fileName], [entry uncompressedSize],
			    [entry compressedSize], [entry CRC32], date,
			    [entry fileComment]];
		} else
			[of_stdout writeLine: [entry fileName]];

		objc_autoreleasePoolPop(pool);
	}
}

- (void)extractFiles: (OFArray*)files
	 fromArchive: (OFZIPArchive*)archive
	    override: (int_fast8_t)override
{
	OFEnumerator *enumerator = [[archive entries] objectEnumerator];
	OFZIPArchiveEntry *entry;
	bool all = ([files count] == 0);
	OFMutableSet *missing = [OFMutableSet setWithArray: files];

	while ((entry = [enumerator nextObject]) != nil) {
		void *pool = objc_autoreleasePoolPush();
		OFString *fileName = [entry fileName];
		OFString *outFileName = [fileName stringByStandardizingPath];
		OFEnumerator *componentEnumerator;
		OFString *component, *directory;
		OFStream *stream;
		OFFile *output;
		char buffer[BUFFER_SIZE];
		off_t written = 0, size = [entry uncompressedSize];
		int_fast8_t percent = -1, newPercent;

		if (!all && ![files containsObject: fileName])
			continue;

		[missing removeObject: fileName];

#ifndef _WIN32
		if ([outFileName hasPrefix: @"/"]) {
#else
		if ([outFileName hasPrefix: @"/"] ||
		    [outFileName containsString: @":"]) {
#endif
			[of_stdout writeFormat: @"Refusing to extract %@!\n",
						fileName];
			[OFApplication terminateWithStatus: 1];
		}

		componentEnumerator =
		    [[outFileName pathComponents] objectEnumerator];
		while ((component = [componentEnumerator nextObject]) != nil) {
			if ([component isEqual: OF_PATH_PARENT_DIRECTORY]) {
				[of_stdout writeFormat:
				    @"Refusing to extract %@!\n", fileName];
				[OFApplication terminateWithStatus: 1];
			}
		}

		[of_stdout writeFormat: @"Extracting %@...", fileName];

		if ([fileName hasSuffix: @"/"]) {
			[OFFile createDirectoryAtPath: outFileName
					createParents: true];
			[of_stdout writeLine: @" done"];
			continue;
		}

		directory = [outFileName stringByDeletingLastPathComponent];
		if (![OFFile directoryExistsAtPath: directory])
			[OFFile createDirectoryAtPath: directory
					createParents: true];

		if ([OFFile fileExistsAtPath: outFileName] && override != 1) {
			OFString *line;

			if (override == -1) {
				[of_stdout writeLine: @" skipped"];
				continue;
			}

			do {
				[of_stderr writeFormat:
				    @"\rOverride %@? [ynAN] ", fileName];

				line = [of_stdin readLine];
			} while (![line isEqual: @"y"] &&
			    ![line isEqual: @"n"] && ![line isEqual: @"N"] &&
			    ![line isEqual: @"A"]);

			if ([line isEqual: @"A"])
				override = 1;
			else if ([line isEqual: @"N"])
				override = -1;

			if ([line isEqual: @"n"] || [line isEqual: @"N"]) {
				[of_stdout writeFormat: @"Skipping %@...\n",
							fileName];
				continue;
			}

			[of_stdout writeFormat: @"Extracting %@...", fileName];
		}

		stream = [archive streamForReadingFile: fileName];
		output = [OFFile fileWithPath: outFileName
					 mode: @"w"];

		while (![stream isAtEndOfStream]) {
			size_t length = [stream readIntoBuffer: buffer
							length: BUFFER_SIZE];
			[output writeBuffer: buffer
				     length: length];

			written += length;
			newPercent = (written == size
			    ? 100 : (int_fast8_t)(written * 100 / size));

			if (percent != newPercent) {
				percent = newPercent;

				[of_stdout writeFormat:
				    @"\rExtracting %@... %3u%%",
				    fileName, percent];
			}
		}

		[of_stdout writeFormat: @"\rExtracting %@... done\n", fileName];

		objc_autoreleasePoolPop(pool);
	}

	if ([missing count] > 0) {
		OFString *file;

		enumerator = [missing objectEnumerator];
		while ((file = [enumerator nextObject]) != nil)
			[of_stderr writeFormat:
			    @"File %@ is not in the archive!\n", file];

		[OFApplication terminateWithStatus: 1];
	}
}
@end
