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

#include <inttypes.h>

#import "OFDate.h"
#import "OFSet.h"
#import "OFApplication.h"
#import "OFFileManager.h"
#import "OFStdIOStream.h"
#import "OFLocalization.h"

#import "TarArchive.h"
#import "OFZIP.h"

static OFZIP *app;

static void
setPermissions(OFString *path, OFTarArchiveEntry *entry)
{
#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
	[[OFFileManager defaultManager]
	    changePermissionsOfItemAtPath: path
			      permissions: [entry mode]];
#endif
}

@implementation TarArchive
+ (void)initialize
{
	if (self == [TarArchive class])
		app = (OFZIP *)[[OFApplication sharedApplication] delegate];
}

+ (instancetype)archiveWithStream: (OF_KINDOF(OFStream *))stream
			     mode: (OFString *)mode
{
	return [[[self alloc] initWithStream: stream
					mode: mode] autorelease];
}

- initWithStream: (OF_KINDOF(OFStream *))stream
	    mode: (OFString *)mode
{
	self = [super init];

	@try {
		_archive = [[OFTarArchive alloc] initWithStream: stream
							   mode: mode];
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
			OFString *size = [OFString stringWithFormat:
			    @"%" PRIu64, [entry size]];
			OFString *mode = [OFString stringWithFormat:
			    @"%06o", [entry mode]];

			[of_stdout writeString: @"\t"];
			[of_stdout writeLine: OF_LOCALIZED(@"list_size",
			    @"Size: %[size] bytes",
			    @"size", size)];
			[of_stdout writeString: @"\t"];
			[of_stdout writeLine: OF_LOCALIZED(@"list_mode",
			    @"Mode: %[mode]",
			    @"mode", mode)];

			if ([entry owner] != nil) {
				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_owner",
				    @"Owner: %[owner]",
				    @"owner", [entry owner])];
			}
			if ([entry group] != nil) {
				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_group",
				    @"Group: %[group]",
				    @"group", [entry group])];
			}

			[of_stdout writeString: @"\t"];
			[of_stdout writeLine: OF_LOCALIZED(
			    @"list_modification_date",
			    @"Modification date: %[date]",
			    @"date", date)];
		}

		if (app->_outputLevel >= 2) {
			[of_stdout writeString: @"\t"];

			switch ([entry type]) {
			case OF_TAR_ARCHIVE_ENTRY_TYPE_FILE:
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_type_normal",
				    @"Type: Normal file")];
				break;
			case OF_TAR_ARCHIVE_ENTRY_TYPE_LINK:
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_type_hardlink",
				    @"Type: Hard link")];
				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_link_target",
				    @"Target file name: %[target]",
				    @"target", [entry targetFileName])];
				break;
			case OF_TAR_ARCHIVE_ENTRY_TYPE_SYMLINK:
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_type_symlink",
				    @"Type: Symbolic link")];
				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_link_target",
				    @"Target file name: %[target]",
				    @"target", [entry targetFileName])];
				break;
			case OF_TAR_ARCHIVE_ENTRY_TYPE_CHARACTER_DEVICE: {
				OFString *majorString = [OFString
				    stringWithFormat: @"%d",
						      [entry deviceMajor]];
				OFString *minorString = [OFString
				    stringWithFormat: @"%d",
						      [entry deviceMinor]];

				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_type_character_device",
				    @"Type: Character device")];
				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_device_major",
				    @"Device major: %[major]",
				    @"major", majorString)];
				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_device_minor",
				    @"Device minor: %[minor]",
				    @"minor", minorString)];
				break;
			}
			case OF_TAR_ARCHIVE_ENTRY_TYPE_BLOCK_DEVICE: {
				OFString *majorString = [OFString
				    stringWithFormat: @"%d",
						      [entry deviceMajor]];
				OFString *minorString = [OFString
				    stringWithFormat: @"%d",
						      [entry deviceMinor]];

				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_type_block_device",
				    @"Type: Block device")];
				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_device_major",
				    @"Device major: %[major]",
				    @"major", majorString)];
				[of_stdout writeString: @"\t"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_device_minor",
				    @"Device minor: %[minor]",
				    @"minor", minorString)];
				break;
			}
			case OF_TAR_ARCHIVE_ENTRY_TYPE_DIRECTORY:
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_type_directory",
				    @"Type: Directory")];
				break;
			case OF_TAR_ARCHIVE_ENTRY_TYPE_FIFO:
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_type_fifo",
				    @"Type: FIFO")];
				break;
			case OF_TAR_ARCHIVE_ENTRY_TYPE_CONTIGUOUS_FILE:
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_type_contiguous_file",
				    @"Type: Contiguous file")];
				break;
			default:
				[of_stdout writeLine: OF_LOCALIZED(
				    @"list_type_unknown",
				    @"Type: Unknown")];
				break;
			}
		}

		objc_autoreleasePoolPop(pool);
	}
}

- (void)extractFiles: (OFArray OF_GENERIC(OFString *) *)files
{
	OFFileManager *fileManager = [OFFileManager defaultManager];
	bool all = ([files count] == 0);
	OFMutableSet OF_GENERIC(OFString *) *missing =
	    [OFMutableSet setWithArray: files];
	OFTarArchiveEntry *entry;

	while ((entry = [_archive nextEntry]) != nil) {
		void *pool = objc_autoreleasePoolPush();
		OFString *fileName = [entry fileName];
		OFString *outFileName = [fileName stringByStandardizingPath];
		OFArray OF_GENERIC(OFString *) *pathComponents;
		OFString *directory;
		OFFile *output;
		OFStream *stream;
		uint64_t written = 0, size = [entry size];
		int8_t percent = -1, newPercent;

		if (!all && ![files containsObject: fileName])
			continue;

		if ([entry type] != OF_TAR_ARCHIVE_ENTRY_TYPE_FILE) {
			if (app->_outputLevel >= 0)
				[of_stdout writeLine: OF_LOCALIZED(
				    @"skipping_file",
				    @"Skipping %[file]...",
				    @"file", fileName)];
			continue;
		}

		[missing removeObject: fileName];

#if !defined(OF_WINDOWS) && !defined(OF_MSDOS)
		if ([outFileName hasPrefix: @"/"]) {
#else
		if ([outFileName hasPrefix: @"/"] ||
		    [outFileName containsString: @":"]) {
#endif
			[of_stderr writeLine: OF_LOCALIZED(
			    @"refusing_to_extract_file",
			    @"Refusing to extract %[file]!",
			    @"file", fileName)];

			app->_exitStatus = 1;
			goto outer_loop_end;
		}

		pathComponents = [outFileName pathComponents];
		for (OFString *component in pathComponents) {
			if ([component isEqual: OF_PATH_PARENT_DIRECTORY]) {
				[of_stderr writeLine: OF_LOCALIZED(
				    @"refusing_to_extract_file",
				    @"Refusing to extract %[file]!",
				    @"file", fileName)];

				app->_exitStatus = 1;
				goto outer_loop_end;
			}
		}
		outFileName = [OFString pathWithComponents: pathComponents];

		if (app->_outputLevel >= 0)
			[of_stdout writeString: OF_LOCALIZED(@"extracting_file",
			    @"Extracting %[file]...",
			    @"file", fileName)];

		if ([fileName hasSuffix: @"/"]) {
			[fileManager createDirectoryAtPath: outFileName
					     createParents: true];
			setPermissions(outFileName, entry);

			if (app->_outputLevel >= 0) {
				[of_stdout writeString: @"\r"];
				[of_stdout writeLine: OF_LOCALIZED(
				    @"extracting_file_done",
				    @"Extracting %[file]... done",
				    @"file", fileName)];
			}

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
					 mode: @"w"];
		setPermissions(outFileName, entry);

		stream = [_archive streamForReadingCurrentEntry];

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
				OFString *percentString;

				percent = newPercent;
				percentString = [OFString stringWithFormat:
				    @"%3u", percent];

				[of_stdout writeString: @"\r"];
				[of_stdout writeString: OF_LOCALIZED(
				    @"extracting_file_percent",
				    @"Extracting %[file]... %[percent]%",
				    @"file", fileName,
				    @"percent", percentString)];
			}
		}

		if (app->_outputLevel >= 0) {
			[of_stdout writeString: @"\r"];
			[of_stdout writeLine: OF_LOCALIZED(
			    @"extracting_file_done",
			    @"Extracting %[file]... done",
			    @"file", fileName)];
		}

outer_loop_end:
		objc_autoreleasePoolPop(pool);
	}

	if ([missing count] > 0) {
		for (OFString *file in missing)
			[of_stderr writeLine: OF_LOCALIZED(
			    @"file_not_in_archive",
			    @"File %[file] is not in the archive!",
			    @"file", file)];

		app->_exitStatus = 1;
	}
}

- (void)printFiles: (OFArray OF_GENERIC(OFString *) *)files_
{
	OFMutableSet *files;
	OFTarArchiveEntry *entry;

	if ([files_ count] < 1) {
		[of_stderr writeLine: OF_LOCALIZED(@"print_no_file_specified",
		    @"Need one or more files to print!")];
		app->_exitStatus = 1;
		return;
	}

	files = [OFMutableSet setWithArray: files_];

	while ((entry = [_archive nextEntry]) != nil) {
		OFString *fileName = [entry fileName];
		OFStream *stream;

		if (![files containsObject: fileName])
			continue;

		stream = [_archive streamForReadingCurrentEntry];

		while (![stream isAtEndOfStream]) {
			ssize_t length = [app copyBlockFromStream: stream
							 toStream: of_stdout
							 fileName: fileName];

			if (length < 0) {
				app->_exitStatus = 1;
				return;
			}
		}

		[files removeObject: fileName];
		[stream close];

		if ([files count] == 0)
			break;
	}

	for (OFString *file in files) {
		[of_stderr writeLine: OF_LOCALIZED(@"file_not_in_archive",
		    @"File %[file] is not in the archive!",
		    @"file", file)];
		app->_exitStatus = 1;
	}
}

- (void)addFiles: (OFArray OF_GENERIC(OFString *) *)files
{
	OFFileManager *fileManager = [OFFileManager defaultManager];

	if ([files count] < 1) {
		[of_stderr writeLine: OF_LOCALIZED(@"add_no_file_specified",
		    @"Need one or more files to add!")];
		app->_exitStatus = 1;
		return;
	}

	for (OFString *fileName in files) {
		void *pool = objc_autoreleasePoolPush();
		OFMutableTarArchiveEntry *entry;
		OFStream *output;

		if (app->_outputLevel >= 0)
			[of_stdout writeString: OF_LOCALIZED(@"adding_file",
			    @"Adding %[file]...",
			    @"file", fileName)];

		entry = [OFMutableTarArchiveEntry entryWithFileName: fileName];

#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
		[entry setMode:
		    [fileManager permissionsOfItemAtPath: fileName]];
#endif
		[entry setSize: [fileManager sizeOfFileAtPath: fileName]];
		[entry setModificationDate:
		    [fileManager modificationDateOfItemAtPath: fileName]];

#ifdef OF_FILE_MANAGER_SUPPORTS_OWNER
		OFString *owner, *group;
		[fileManager getOwner: &owner
				group: &group
			 ofItemAtPath: fileName];
		[entry setOwner: owner];
		[entry setGroup: group];
#endif

		if ([fileManager fileExistsAtPath: fileName])
			[entry setType: OF_TAR_ARCHIVE_ENTRY_TYPE_FILE];
		else if ([fileManager directoryExistsAtPath: fileName]) {
			[entry setType: OF_TAR_ARCHIVE_ENTRY_TYPE_DIRECTORY];
			[entry setSize: 0];
		} else if ([fileManager symbolicLinkExistsAtPath: fileName]) {
			[entry setType: OF_TAR_ARCHIVE_ENTRY_TYPE_SYMLINK];
			[entry setTargetFileName: [fileManager
			    destinationOfSymbolicLinkAtPath: fileName]];
			[entry setSize: 0];
		}

		[entry makeImmutable];

		output = [_archive streamForWritingEntry: entry];

		if ([entry type] == OF_TAR_ARCHIVE_ENTRY_TYPE_FILE) {
			uint64_t written = 0, size = [entry size];
			int8_t percent = -1, newPercent;

			OFFile *input = [OFFile fileWithPath: fileName
							mode: @"r"];

			while (![input isAtEndOfStream]) {
				ssize_t length = [app
				    copyBlockFromStream: input
					       toStream: output
					       fileName: fileName];

				if (length < 0) {
					app->_exitStatus = 1;
					goto outer_loop_end;
				}

				written += length;
				newPercent = (written == size
				    ? 100 : (int8_t)(written * 100 / size));

				if (app->_outputLevel >= 0 &&
				    percent != newPercent) {
					OFString *percentString;

					percent = newPercent;
					percentString = [OFString
					    stringWithFormat: @"%3u", percent];

					[of_stdout writeString: @"\r"];
					[of_stdout writeString: OF_LOCALIZED(
					    @"adding_file_percent",
					    @"Adding %[file]... %[percent]%",
					    @"file", fileName,
					    @"percent", percentString)];
				}
			}
		}

		if (app->_outputLevel >= 0) {
			[of_stdout writeString: @"\r"];
			[of_stdout writeLine: OF_LOCALIZED(
			    @"adding_file_done",
			    @"Adding %[file]... done",
			    @"file", fileName)];
		}

		[output close];

outer_loop_end:
		objc_autoreleasePoolPop(pool);
	}

	[_archive close];
}
@end
