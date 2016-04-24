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

#include <string.h>

#import "OFApplication.h"
#import "OFArray.h"
#import "OFFile.h"
#import "OFFileManager.h"
#import "OFOptionsParser.h"
#import "OFStdIOStream.h"

#import "OFZIP.h"
#import "ZIPArchive.h"
#import "GZIPArchive.h"

#import "OFCreateDirectoryFailedException.h"
#import "OFInvalidFormatException.h"
#import "OFOpenItemFailedException.h"
#import "OFReadFailedException.h"
#import "OFWriteFailedException.h"

#define BUFFER_SIZE 4096

OF_APPLICATION_DELEGATE(OFZIP)

static void
help(OFStream *stream, bool full, int status)
{
	[stream writeFormat:
	    @"Usage: %@ -[fhlnqvx] archive.zip [file1 file2 ...]\n",
	    [OFApplication programName]];

	if (full)
		[stream writeString:
		    @"\nOptions:\n"
		    @"    -f  --force      Force / override files\n"
		    @"    -h  --help       Show this help\n"
		    @"    -l  --list       List all files in the archive\n"
		    @"    -n  --no-clober  Never override files\n"
		    @"    -q  --quiet      Quiet mode (no output, except "
		    @"errors)\n"
		    @"    -v  --verbose    Verbose output for file list\n"
		    @"    -x  --extract    Extract files\n"];

	[OFApplication terminateWithStatus: status];
}

static void
mutuallyExclusiveError(of_unichar_t shortOption1, OFString *longOption1,
    of_unichar_t shortOption2, OFString *longOption2)
{
	[of_stderr writeFormat:
	    @"Error: -%C / --%@ and -%C / --%@ are mutually exclusive!\n",
	    shortOption1, longOption1, shortOption2, longOption2];
	[OFApplication terminateWithStatus: 1];
}

@implementation OFZIP
- (void)applicationDidFinishLaunching
{
	const of_options_parser_option_t options[] = {
		{ 'f', @"force", 0, NULL, NULL },
		{ 'h', @"help", 0, NULL, NULL },
		{ 'l', @"list", 0, NULL, NULL },
		{ 'n', @"no-clobber", 0, NULL, NULL },
		{ 'q', @"quiet", 0, NULL, NULL },
		{ 'v', @"verbose", 0, NULL, NULL },
		{ 'x', @"extract", 0, NULL, NULL },
		{ '\0', nil, 0, NULL, NULL }
	};
	OFOptionsParser *optionsParser =
	    [OFOptionsParser parserWithOptions: options];
	of_unichar_t option, mode = '\0';
	OFArray OF_GENERIC(OFString*) *remainingArguments, *files;
	id <Archive> archive;

	while ((option = [optionsParser nextOption]) != '\0') {
		switch (option) {
		case 'f':
			if (_override < 0)
				mutuallyExclusiveError(
				    'f', @"force", 'n', @"no-clobber");

			_override = 1;
			break;
		case 'n':
			if (_override > 0)
				mutuallyExclusiveError(
				    'f', @"force", 'n', @"no-clobber");

			_override = -1;
			break;
		case 'v':
			if (_outputLevel < 0)
				mutuallyExclusiveError(
				    'q', @"quiet", 'v', @"verbose");

			_outputLevel++;
			break;
		case 'q':
			if (_outputLevel > 0)
				mutuallyExclusiveError(
				    'q', @"quiet", 'v', @"verbose");

			_outputLevel--;
			break;
		case 'l':
		case 'x':
			if (mode != '\0')
				mutuallyExclusiveError(
				    'l', @"list", 'x', @"extract");

			mode = option;
			break;
		case 'h':
			help(of_stdout, true, 0);
			break;
		case '=':
			[of_stderr writeFormat: @"%@: Option --%@ takes no "
						@"argument!\n",
						[OFApplication programName],
						[optionsParser lastLongOption]];

			[OFApplication terminateWithStatus: 1];
			break;
		default:
			if ([optionsParser lastLongOption] != nil)
				[of_stderr writeFormat:
				    @"%@: Unknown option: --%@\n",
				    [OFApplication programName],
				    [optionsParser lastLongOption]];
			else
				[of_stderr writeFormat:
				    @"%@: Unknown option: -%C\n",
				    [OFApplication programName],
				    [optionsParser lastOption]];

			[OFApplication terminateWithStatus: 1];
		}
	}

	remainingArguments = [optionsParser remainingArguments];
	archive = [self openArchiveWithPath: [remainingArguments firstObject]];

	switch (mode) {
	case 'l':
		if ([remainingArguments count] != 1)
			help(of_stderr, false, 1);

		[archive listFiles];
		break;
	case 'x':
		if ([remainingArguments count] < 1)
			help(of_stderr, false, 1);

		files = [remainingArguments objectsInRange:
		    of_range(1, [remainingArguments count] - 1)];

		@try {
			[archive extractFiles: files];
		} @catch (OFCreateDirectoryFailedException *e) {
			[of_stderr writeFormat:
			    @"\rFailed to create directory %@: %s\n",
			    [e path], strerror([e errNo])];
			_exitStatus = 1;
		} @catch (OFOpenItemFailedException *e) {
			[of_stderr writeFormat:
			    @"\rFailed to open file %@: %s\n",
			    [e path], strerror([e errNo])];
			_exitStatus = 1;
		}

		break;
	default:
		help(of_stderr, true, 1);
		break;
	}

	[OFApplication terminateWithStatus: _exitStatus];
}

- (id <Archive>)openArchiveWithPath: (OFString*)path
{
	OFFile *file = nil;
	id <Archive> archive = nil;

	[_archivePath release];
	_archivePath = [path copy];

	@try {
		file = [OFFile fileWithPath: path
				       mode: @"rb"];
	} @catch (OFOpenItemFailedException *e) {
		[of_stderr writeFormat: @"Failed to open file %@: %s\n",
					[e path], strerror([e errNo])];
		[OFApplication terminateWithStatus: 1];
	}

	@try {
		if ([path hasSuffix: @".gz"])
			archive = [GZIPArchive archiveWithFile: file];
		else
			archive = [ZIPArchive archiveWithFile: file];
	} @catch (OFReadFailedException *e) {
		[of_stderr writeFormat: @"Failed to read file %@: %s\n",
					path, strerror([e errNo])];
		[OFApplication terminateWithStatus: 1];
	} @catch (OFInvalidFormatException *e) {
		[of_stderr writeFormat: @"File %@ is not a valid archive!\n",
					path];
		[OFApplication terminateWithStatus: 1];
	}

	return archive;
}

- (bool)shouldExtractFile: (OFString*)fileName
	      outFileName: (OFString*)outFileName
{
	OFString *line;

	if (_override == 1 ||
	    ![[OFFileManager defaultManager] fileExistsAtPath: outFileName])
		return true;


	if (_override == -1) {
		if (_outputLevel >= 0)
			[of_stdout writeLine: @" skipped"];
		return false;
	}

	do {
		[of_stderr writeFormat: @"\rOverride %@? [ynAN?] ", fileName];

		line = [of_stdin readLine];

		if ([line isEqual: @"?"])
			[of_stderr writeString: @" y: yes\n"
						@" n: no\n"
						@" A: always\n"
						@" N: never\n"];
	} while (![line isEqual: @"y"] && ![line isEqual: @"n"] &&
	    ![line isEqual: @"N"] && ![line isEqual: @"A"]);

	if ([line isEqual: @"A"])
		_override = 1;
	else if ([line isEqual: @"N"])
		_override = -1;

	if ([line isEqual: @"n"] || [line isEqual: @"N"]) {
		if (_outputLevel >= 0)
			[of_stdout writeFormat: @"Skipping %@...\n", fileName];
			return false;
	}

	if (_outputLevel >= 0)
		[of_stdout writeFormat: @"Extracting %@...", fileName];

	return true;
}

- (ssize_t)copyBlockFromStream: (OFStream*)input
		      toStream: (OFStream*)output
		      fileName: (OFString*)fileName
{
	char buffer[BUFFER_SIZE];
	size_t length;

	@try {
		length = [input readIntoBuffer: buffer
					length: BUFFER_SIZE];
	} @catch (OFReadFailedException *e) {
		[of_stderr writeFormat: @"\rFailed to read file %@: %s\n",
					fileName, strerror([e errNo])];
		return -1;
	}

	@try {
		[output writeBuffer: buffer
			     length: length];
	} @catch (OFWriteFailedException *e) {
		[of_stderr writeFormat: @"\rFailed to write file %@: %s\n",
					fileName, strerror([e errNo])];
		return -1;
	}

	return length;
}
@end
