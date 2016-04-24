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

#import "ZIPArchive.h"
#import "OFZIP.h"

#import "OFInvalidFormatException.h"

#ifndef S_IRWXG
# define S_IRWXG 0
#endif
#ifndef S_IRWXO
# define S_IRWXO 0
#endif

static OFZIP *app;

static void
setPermissions(OFString *path, OFZIPArchiveEntry *entry)
{
#ifdef OF_HAVE_CHMOD
	if (([entry versionMadeBy] >> 8) ==
	    OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_UNIX) {
		uint32_t mode = [entry versionSpecificAttributes] >> 16;

		/* Only allow modes that are safe */
		mode &= (S_IRWXU | S_IRWXG | S_IRWXO);

		[[OFFileManager defaultManager]
		    changePermissionsOfItemAtPath: path
				      permissions: mode];
	}
#endif
}

@implementation ZIPArchive
+ (void)initialize
{
	if (self == [ZIPArchive class])
		app = [[OFApplication sharedApplication] delegate];
}

+ (instancetype)archiveWithFile: (OFFile*)file
{
	return [[[self alloc] initWithFile: file] autorelease];
}

- initWithFile: (OFFile*)file
{
	self = [super init];

	@try {
		_archive = [OFZIPArchive archiveWithSeekableStream: file];
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
	for (OFZIPArchiveEntry *entry in [_archive entries]) {
		void *pool = objc_autoreleasePoolPush();

		[of_stdout writeLine: [entry fileName]];

		if (app->_outputLevel >= 1) {
			OFString *date = [[entry modificationDate]
			    localDateStringWithFormat: @"%Y-%m-%d %H:%M:%S"];

			[of_stdout writeFormat:
			    @"\tCompressed: %" PRIu64 @" bytes\n"
			    @"\tUncompressed: %" PRIu64 @" bytes\n"
			    @"\tCRC32: %08X\n"
			    @"\tModification date: %@\n",
			    [entry compressedSize], [entry uncompressedSize],
			    [entry CRC32], date];

			if (app->_outputLevel >= 2) {
				uint16_t versionMadeBy = [entry versionMadeBy];

				[of_stdout writeFormat:
				    @"\tVersion made by: %@\n"
				    @"\tMinimum version needed: %@\n",
				    of_zip_archive_entry_version_to_string(
				    versionMadeBy),
				    of_zip_archive_entry_version_to_string(
				    [entry minVersionNeeded])];

				if ((versionMadeBy >> 8) ==
				    OF_ZIP_ARCHIVE_ENTRY_ATTR_COMPAT_UNIX) {
					uint32_t mode = [entry
					    versionSpecificAttributes] >> 16;
					[of_stdout writeFormat:
					    @"\tMode: %06o\n", mode];
				}
			}

			if (app->_outputLevel >= 3)
				[of_stdout writeFormat: @"\tExtra field: %@\n",
							[entry extraField]];

			if ([[entry fileComment] length] > 0)
				[of_stdout writeFormat: @"\tComment: %@\n",
							[entry fileComment]];
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

	for (OFZIPArchiveEntry *entry in [_archive entries]) {
		void *pool = objc_autoreleasePoolPush();
		OFString *fileName = [entry fileName];
		OFString *outFileName = [fileName stringByStandardizingPath];
		OFArray OF_GENERIC(OFString*) *pathComponents;
		OFString *directory;
		OFStream *stream;
		OFFile *output;
		uint64_t written = 0, size = [entry uncompressedSize];
		int8_t percent = -1, newPercent;

		if (!all && ![files containsObject: fileName])
			continue;

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

		stream = [_archive streamForReadingFile: fileName];
		output = [OFFile fileWithPath: outFileName
					 mode: @"wb"];
		setPermissions(outFileName, entry);

		while (![stream isAtEndOfStream]) {
			ssize_t length = [app copyBlockFromStream: stream
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
@end
