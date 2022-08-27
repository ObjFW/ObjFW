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

#import "OFApplication.h"
#import "OFDate.h"
#import "OFFileManager.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFSet.h"
#import "OFStdIOStream.h"
#import "OFString.h"

#import "TarArchive.h"
#import "OFArc.h"

static OFArc *app;

static void
setPermissions(OFString *path, OFTarArchiveEntry *entry)
{
#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
	OFNumber *mode = [OFNumber numberWithUnsignedShort: entry.mode & 0777];
	OFFileAttributes attributes = [OFDictionary
	    dictionaryWithObject: mode
			  forKey: OFFilePOSIXPermissions];

	[[OFFileManager defaultManager] setAttributes: attributes
					 ofItemAtPath: path];
#endif
}

static void
setModificationDate(OFString *path, OFTarArchiveEntry *entry)
{
	OFDate *modificationDate = entry.modificationDate;
	OFFileAttributes attributes;

	if (modificationDate == nil)
		return;

	attributes = [OFDictionary
	    dictionaryWithObject: modificationDate
			  forKey: OFFileModificationDate];
	[[OFFileManager defaultManager] setAttributes: attributes
					 ofItemAtPath: path];
}

@implementation TarArchive
+ (void)initialize
{
	if (self == [TarArchive class])
		app = (OFArc *)[OFApplication sharedApplication].delegate;
}

+ (instancetype)archiveWithStream: (OF_KINDOF(OFStream *))stream
			     mode: (OFString *)mode
			 encoding: (OFStringEncoding)encoding
{
	return [[[self alloc] initWithStream: stream
					mode: mode
				    encoding: encoding] autorelease];
}

- (instancetype)initWithStream: (OF_KINDOF(OFStream *))stream
			  mode: (OFString *)mode
		      encoding: (OFStringEncoding)encoding
{
	self = [super init];

	@try {
		_archive = [[OFTarArchive alloc] initWithStream: stream
							   mode: mode];

		if (encoding != OFStringEncodingAutodetect)
			_archive.encoding = encoding;
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

		[OFStdOut writeLine: entry.fileName];

		if (app->_outputLevel >= 1) {
			OFString *date = [entry.modificationDate
			    localDateStringWithFormat: @"%Y-%m-%d %H:%M:%S"];
			OFString *size = [OFString stringWithFormat:
			    @"%llu", entry.uncompressedSize];
			OFString *mode = [OFString stringWithFormat:
			    @"%06o", entry.mode];
			OFString *UID = [OFString stringWithFormat:
			    @"%u", entry.UID];
			OFString *GID = [OFString stringWithFormat:
			    @"%u", entry.GID];

			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(@"list_size",
			    @"["
			    @"    'Size: ',"
			    @"    ["
			    @"        {'size == 1': '1 byte'},"
			    @"        {'': '%[size] bytes'}"
			    @"    ]"
			    @"]".objectByParsingJSON,
			    @"size", size)];
			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(@"list_mode",
			    @"Mode: %[mode]",
			    @"mode", mode)];
			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(@"list_uid",
			    @"UID: %[uid]",
			    @"uid", UID)];
			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(@"list_gid",
			    @"GID: %[gid]",
			    @"gid", GID)];

			if (entry.owner != nil) {
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_owner",
				    @"Owner: %[owner]",
				    @"owner", entry.owner)];
			}
			if (entry.group != nil) {
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_group",
				    @"Group: %[group]",
				    @"group", entry.group)];
			}

			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(
			    @"list_modification_date",
			    @"Modification date: %[date]",
			    @"date", date)];
		}

		if (app->_outputLevel >= 2) {
			[OFStdOut writeString: @"\t"];

			switch (entry.type) {
			case OFTarArchiveEntryTypeFile:
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_type_normal",
				    @"Type: Normal file")];
				break;
			case OFTarArchiveEntryTypeLink:
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_type_hardlink",
				    @"Type: Hard link")];
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_link_target",
				    @"Target file name: %[target]",
				    @"target", entry.targetFileName)];
				break;
			case OFTarArchiveEntryTypeSymlink:
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_type_symlink",
				    @"Type: Symbolic link")];
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_link_target",
				    @"Target file name: %[target]",
				    @"target", entry.targetFileName)];
				break;
			case OFTarArchiveEntryTypeCharacterDevice: {
				OFString *majorString = [OFString
				    stringWithFormat: @"%d", entry.deviceMajor];
				OFString *minorString = [OFString
				    stringWithFormat: @"%d", entry.deviceMinor];

				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_type_character_device",
				    @"Type: Character device")];
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_device_major",
				    @"Device major: %[major]",
				    @"major", majorString)];
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_device_minor",
				    @"Device minor: %[minor]",
				    @"minor", minorString)];
				break;
			}
			case OFTarArchiveEntryTypeBlockDevice: {
				OFString *majorString = [OFString
				    stringWithFormat: @"%d", entry.deviceMajor];
				OFString *minorString = [OFString
				    stringWithFormat: @"%d", entry.deviceMinor];

				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_type_block_device",
				    @"Type: Block device")];
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_device_major",
				    @"Device major: %[major]",
				    @"major", majorString)];
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_device_minor",
				    @"Device minor: %[minor]",
				    @"minor", minorString)];
				break;
			}
			case OFTarArchiveEntryTypeDirectory:
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_type_directory",
				    @"Type: Directory")];
				break;
			case OFTarArchiveEntryTypeFIFO:
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_type_fifo",
				    @"Type: FIFO")];
				break;
			case OFTarArchiveEntryTypeContiguousFile:
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_type_contiguous_file",
				    @"Type: Contiguous file")];
				break;
			default:
				[OFStdOut writeLine: OF_LOCALIZED(
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
	bool all = (files.count == 0);
	OFMutableSet OF_GENERIC(OFString *) *missing =
	    [OFMutableSet setWithArray: files];
	OFTarArchiveEntry *entry;

	while ((entry = [_archive nextEntry]) != nil) {
		void *pool = objc_autoreleasePoolPush();
		OFString *fileName = entry.fileName;
		OFTarArchiveEntryType type = entry.type;
		OFString *outFileName, *directory;
		OFFile *output;
		OFStream *stream;
		unsigned long long written = 0, size = entry.uncompressedSize;
		int8_t percent = -1, newPercent;

		if (!all && ![files containsObject: fileName])
			continue;

		if (type != OFTarArchiveEntryTypeFile &&
		    type != OFTarArchiveEntryTypeDirectory) {
			if (app->_outputLevel >= 0)
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"skipping_file",
				    @"Skipping %[file]...",
				    @"file", fileName)];
			continue;
		}

		[missing removeObject: fileName];

		outFileName = [app safeLocalPathForPath: fileName];
		if (outFileName == nil) {
			[OFStdErr writeLine: OF_LOCALIZED(
			    @"refusing_to_extract_file",
			    @"Refusing to extract %[file]!",
			    @"file", fileName)];

			app->_exitStatus = 1;
			goto outer_loop_end;
		}

		if (app->_outputLevel >= 0)
			[OFStdOut writeString: OF_LOCALIZED(@"extracting_file",
			    @"Extracting %[file]...",
			    @"file", fileName)];

		if (type == OFTarArchiveEntryTypeDirectory ||
		    (type == OFTarArchiveEntryTypeFile &&
		    [fileName hasSuffix: @"/"])) {
			[fileManager createDirectoryAtPath: outFileName
					     createParents: true];
			setPermissions(outFileName, entry);
			setModificationDate(outFileName, entry);

			if (app->_outputLevel >= 0) {
				[OFStdOut writeString: @"\r"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"extracting_file_done",
				    @"Extracting %[file]... done",
				    @"file", fileName)];
			}

			goto outer_loop_end;
		}

		directory = outFileName.stringByDeletingLastPathComponent;
		if (![fileManager directoryExistsAtPath: directory])
			[fileManager createDirectoryAtPath: directory
					     createParents: true];

		if (![app shouldExtractFile: fileName outFileName: outFileName])
			goto outer_loop_end;

		stream = [_archive streamForReadingCurrentEntry];
		output = [OFFile fileWithPath: outFileName mode: @"w"];
		setPermissions(outFileName, entry);

		while (!stream.atEndOfStream) {
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

				[OFStdOut writeString: @"\r"];
				[OFStdOut writeString: OF_LOCALIZED(
				    @"extracting_file_percent",
				    @"Extracting %[file]... %[percent]%",
				    @"file", fileName,
				    @"percent", percentString)];
			}
		}

		[output close];
		setModificationDate(outFileName, entry);

		if (app->_outputLevel >= 0) {
			[OFStdOut writeString: @"\r"];
			[OFStdOut writeLine: OF_LOCALIZED(
			    @"extracting_file_done",
			    @"Extracting %[file]... done",
			    @"file", fileName)];
		}

outer_loop_end:
		objc_autoreleasePoolPop(pool);
	}

	if (missing.count > 0) {
		for (OFString *file in missing)
			[OFStdErr writeLine: OF_LOCALIZED(
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

	if (files_.count < 1) {
		[OFStdErr writeLine: OF_LOCALIZED(@"print_no_file_specified",
		    @"Need one or more files to print!")];
		app->_exitStatus = 1;
		return;
	}

	files = [OFMutableSet setWithArray: files_];

	while ((entry = [_archive nextEntry]) != nil) {
		OFString *fileName = entry.fileName;
		OFStream *stream;

		if (![files containsObject: fileName])
			continue;

		stream = [_archive streamForReadingCurrentEntry];

		while (!stream.atEndOfStream) {
			ssize_t length = [app copyBlockFromStream: stream
							 toStream: OFStdOut
							 fileName: fileName];

			if (length < 0) {
				app->_exitStatus = 1;
				return;
			}
		}

		[files removeObject: fileName];
		[stream close];

		if (files.count == 0)
			break;
	}

	for (OFString *file in files) {
		[OFStdErr writeLine: OF_LOCALIZED(@"file_not_in_archive",
		    @"File %[file] is not in the archive!",
		    @"file", file)];
		app->_exitStatus = 1;
	}
}

- (void)addFiles: (OFArray OF_GENERIC(OFString *) *)files
{
	OFFileManager *fileManager = [OFFileManager defaultManager];

	if (files.count < 1) {
		[OFStdErr writeLine: OF_LOCALIZED(@"add_no_file_specified",
		    @"Need one or more files to add!")];
		app->_exitStatus = 1;
		return;
	}

	for (OFString *fileName in files) {
		void *pool = objc_autoreleasePoolPush();
		OFFileAttributes attributes;
		OFFileAttributeType type;
		OFMutableTarArchiveEntry *entry;
		OFStream *output;

		if (app->_outputLevel >= 0)
			[OFStdOut writeString: OF_LOCALIZED(@"adding_file",
			    @"Adding %[file]...",
			    @"file", fileName)];

		attributes = [fileManager attributesOfItemAtPath: fileName];
		type = attributes.fileType;
		entry = [OFMutableTarArchiveEntry entryWithFileName: fileName];

#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
		entry.mode = attributes.filePOSIXPermissions;
#endif
		entry.uncompressedSize = attributes.fileSize;
		entry.modificationDate = attributes.fileModificationDate;

#ifdef OF_FILE_MANAGER_SUPPORTS_OWNER
		entry.UID = attributes.fileOwnerAccountID;
		entry.GID = attributes.fileGroupOwnerAccountID;
		entry.owner = attributes.fileOwnerAccountName;
		entry.group = attributes.fileGroupOwnerAccountName;
#endif

		if ([type isEqual: OFFileTypeRegular])
			entry.type = OFTarArchiveEntryTypeFile;
		else if ([type isEqual: OFFileTypeDirectory]) {
			entry.type = OFTarArchiveEntryTypeDirectory;
			entry.uncompressedSize = 0;
		} else if ([type isEqual: OFFileTypeSymbolicLink]) {
			entry.type = OFTarArchiveEntryTypeSymlink;
			entry.targetFileName =
			    attributes.fileSymbolicLinkDestination;
			entry.uncompressedSize = 0;
		}

		[entry makeImmutable];

		output = [_archive streamForWritingEntry: entry];

		if (entry.type == OFTarArchiveEntryTypeFile) {
			unsigned long long written = 0;
			unsigned long long size = entry.uncompressedSize;
			int8_t percent = -1, newPercent;

			OFFile *input = [OFFile fileWithPath: fileName
							mode: @"r"];

			while (!input.atEndOfStream) {
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

					[OFStdOut writeString: @"\r"];
					[OFStdOut writeString: OF_LOCALIZED(
					    @"adding_file_percent",
					    @"Adding %[file]... %[percent]%",
					    @"file", fileName,
					    @"percent", percentString)];
				}
			}
		}

		if (app->_outputLevel >= 0) {
			[OFStdOut writeString: @"\r"];
			[OFStdOut writeLine: OF_LOCALIZED(
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
