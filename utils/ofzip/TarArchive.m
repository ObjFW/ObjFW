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

#import "OFDate.h"
#import "OFSet.h"
#import "OFApplication.h"
#import "OFFileManager.h"
#import "OFStdIOStream.h"

#import "TarArchive.h"
#import "OFZIP.h"

#ifndef S_IRWXG
# define S_IRWXG 0
#endif
#ifndef S_IRWXO
# define S_IRWXO 0
#endif

static OFZIP *app;

static void
setPermissions(OFString *path, OFTarArchiveEntry *entry)
{
#ifdef OF_HAVE_CHMOD
	uint32_t mode = [entry mode];

	/* Only allow modes that are safe */
	mode &= (S_IRWXU | S_IRWXG | S_IRWXO);

	[[OFFileManager defaultManager]
	    changePermissionsOfItemAtPath: path
			      permissions: mode];
#endif
}

@implementation TarArchive
+ (void)initialize
{
	if (self == [TarArchive class])
		app = [[OFApplication sharedApplication] delegate];
}

+ (instancetype)archiveWithStream: (OF_KINDOF(OFStream*))stream
{
	return [[[self alloc] initWithStream: stream] autorelease];
}

- initWithStream: (OF_KINDOF(OFStream*))stream
{
	self = [super init];

	@try {
		_archive = [[OFTarArchive alloc] initWithStream: stream];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_archive release];

	[super dealloc];
}

- (void)listFiles
{
	OFTarArchiveEntry *entry;

	while ((entry = [_archive nextEntry]) != nil) {
		void *pool = objc_autoreleasePoolPush();

		[of_stdout writeLine: [entry fileName]];

		if (app->_outputLevel >= 1) {
			OFString *date = [[entry modificationDate]
			    localDateStringWithFormat: @"%Y-%m-%d %H:%M:%S"];

			[of_stdout writeFormat:
			    @"\tSize: %" PRIu64 @" bytes\n"
			    @"\tModification date: %@\n",
			    [entry size], date];

			if ([entry owner] != nil)
				[of_stdout writeFormat: @"\tOwner: %@\n",
							[entry owner]];
			if ([entry group] != nil)
				[of_stdout writeFormat: @"\tGroup: %@\n",
							[entry group]];
		}

		if (app->_outputLevel >= 2) {
			switch ([entry type]) {
			case OF_TAR_ARCHIVE_ENTRY_TYPE_FILE:
				[of_stdout writeLine: @"\tType: Normal file"];
				break;
			case OF_TAR_ARCHIVE_ENTRY_TYPE_LINK:
				[of_stdout writeLine: @"\tType: Hard link"];
				[of_stdout writeFormat:
				    @"\tTarget file name: %@\n",
				    [entry targetFileName]];
				break;
			case OF_TAR_ARCHIVE_ENTRY_TYPE_SYMLINK:
				[of_stdout writeLine: @"\tType: Symbolic link"];
				[of_stdout writeFormat:
				    @"\tTarget file name: %@\n",
				    [entry targetFileName]];
				break;
			case OF_TAR_ARCHIVE_ENTRY_TYPE_CHARACTER_DEVICE:
				[of_stdout writeLine:
				    @"\tType: Character device"];
				[of_stdout writeFormat: @"\tDevice major: %d\n"
							@"\tDevice minor: %d\n",
							[entry deviceMajor],
							[entry deviceMinor]];
				break;
			case OF_TAR_ARCHIVE_ENTRY_TYPE_BLOCK_DEVICE:
				[of_stdout writeLine:
				    @"\tType: Block device"];
				[of_stdout writeFormat: @"\tDevice major: %d\n"
							@"\tDevice minor: %d\n",
							[entry deviceMajor],
							[entry deviceMinor]];
				break;
			case OF_TAR_ARCHIVE_ENTRY_TYPE_DIRECTORY:
				[of_stdout writeLine: @"\tType: Directory"];
				break;
			case OF_TAR_ARCHIVE_ENTRY_TYPE_FIFO:
				[of_stdout writeLine: @"\tType: FIFO"];
				break;
			case OF_TAR_ARCHIVE_ENTRY_TYPE_CONTIGUOUS_FILE:
				[of_stdout writeLine:
				    @"\tType: Contiguous file"];
				break;
			default:
				[of_stdout writeLine: @"\tType: Unknown"];
				break;
			}
		}

		objc_autoreleasePoolPop(pool);
	}
}

- (void)extractFiles: (OFArray OF_GENERIC(OFString*)*)files
{
	OFFileManager *fileManager = [OFFileManager defaultManager];
	bool all = ([files count] == 0);
	OFMutableSet OF_GENERIC(OFString*) *missing =
	    [OFMutableSet setWithArray: files];
	OFTarArchiveEntry *entry;

	while ((entry = [_archive nextEntry]) != nil) {
		void *pool = objc_autoreleasePoolPush();
		OFString *fileName = [entry fileName];
		OFString *outFileName = [fileName stringByStandardizingPath];
		OFArray OF_GENERIC(OFString*) *pathComponents;
		OFString *directory;
		OFFile *output;
		uint64_t written = 0, size = [entry size];
		int8_t percent = -1, newPercent;

		if (!all && ![files containsObject: fileName])
			continue;

		if ([entry type] != OF_TAR_ARCHIVE_ENTRY_TYPE_FILE) {
			if (app->_outputLevel >= 0)
				[of_stdout writeFormat: @"Skipping %@...\n",
							fileName];
			continue;
		}

		[missing removeObject: fileName];

#if !defined(OF_WINDOWS) && !defined(OF_MSDOS)
		if ([outFileName hasPrefix: @"/"]) {
#else
		if ([outFileName hasPrefix: @"/"] ||
		    [outFileName containsString: @":"]) {
#endif
			[of_stderr writeFormat: @"Refusing to extract %@!\n",
						fileName];

			app->_exitStatus = 1;
			goto outer_loop_end;
		}

		pathComponents = [outFileName pathComponents];
		for (OFString *component in pathComponents) {
			if ([component isEqual: OF_PATH_PARENT_DIRECTORY]) {
				[of_stderr writeFormat:
				    @"Refusing to extract %@!\n", fileName];

				app->_exitStatus = 1;
				goto outer_loop_end;
			}
		}
		outFileName = [OFString pathWithComponents: pathComponents];

		if (app->_outputLevel >= 0)
			[of_stdout writeFormat: @"Extracting %@...", fileName];

		if ([fileName hasSuffix: @"/"]) {
			[fileManager createDirectoryAtPath: outFileName
					     createParents: true];
			setPermissions(outFileName, entry);

			if (app->_outputLevel >= 0)
				[of_stdout writeLine: @" done"];

			goto outer_loop_end;
		}

		directory = [outFileName stringByDeletingLastPathComponent];
		if (![fileManager directoryExistsAtPath: directory])
			[fileManager createDirectoryAtPath: directory
					     createParents: true];

		if (![app shouldExtractFile: fileName
				outFileName: outFileName])
			goto outer_loop_end;

		output = [OFFile fileWithPath: outFileName
					 mode: @"wb"];
		setPermissions(outFileName, entry);

		while (![entry isAtEndOfStream]) {
			ssize_t length = [app copyBlockFromStream: entry
							 toStream: output
							 fileName: fileName];

			if (length < 0) {
				app->_exitStatus = 1;
				goto outer_loop_end;
			}

			written += length;
			newPercent = (written == size
			    ? 100 : (int8_t)(written * 100 / size));

			if (app->_outputLevel >= 0 && percent != newPercent) {
				percent = newPercent;

				[of_stdout writeFormat:
				    @"\rExtracting %@... %3u%%",
				    fileName, percent];
			}
		}

		if (app->_outputLevel >= 0)
			[of_stdout writeFormat: @"\rExtracting %@... done\n",
						fileName];

outer_loop_end:
		objc_autoreleasePoolPop(pool);
	}

	if ([missing count] > 0) {
		for (OFString *file in missing)
			[of_stderr writeFormat:
			    @"File %@ is not in the archive!\n", file];

		app->_exitStatus = 1;
	}
}

- (void)printFiles: (OFArray OF_GENERIC(OFString*)*)files_
{
	OFMutableSet *files;
	OFTarArchiveEntry *entry;

	if ([files_ count] < 1) {
		[of_stderr writeLine: @"Need one or more files to print!"];
		app->_exitStatus = 1;
		return;
	}

	files = [OFMutableSet setWithArray: files_];

	while ((entry = [_archive nextEntry]) != nil) {
		OFString *fileName = [entry fileName];

		if (![files containsObject: fileName])
			continue;

		while (![entry isAtEndOfStream]) {
			ssize_t length = [app copyBlockFromStream: entry
							 toStream: of_stdout
							 fileName: fileName];

			if (length < 0) {
				app->_exitStatus = 1;
				return;
			}
		}

		[files removeObject: fileName];
		[entry close];
	}

	for (OFString *path in files) {
		[of_stderr writeFormat: @"File %@ is not in the archive!\n",
					path];
		app->_exitStatus = 1;
	}
}
@end
