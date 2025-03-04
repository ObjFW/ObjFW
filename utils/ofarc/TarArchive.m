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

#include <errno.h>

#import "OFApplication.h"
#import "OFArray.h"
#import "OFDate.h"
#import "OFFile.h"
#import "OFFileManager.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFPair.h"
#import "OFSet.h"
#import "OFStdIOStream.h"
#import "OFString.h"

#import "TarArchive.h"
#import "OFArc.h"

#import "OFSetItemAttributesFailedException.h"

static OFArc *app;

static void
setPermissions(OFString *path, OFTarArchiveEntry *entry)
{
	[app quarantineFile: path];

#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
	OFNumber *POSIXPermissions = [OFNumber numberWithUnsignedLongLong:
	    entry.POSIXPermissions.longLongValue & 0777];
	OFFileAttributes attributes = [OFDictionary
	    dictionaryWithObject: POSIXPermissions
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
	@try {
		[[OFFileManager defaultManager] setAttributes: attributes
						 ofItemAtPath: path];
	} @catch (OFSetItemAttributesFailedException *e) {
		if (e.errNo != EISDIR)
			@throw e;
	}
}

@implementation TarArchive
+ (void)initialize
{
	if (self == [TarArchive class])
		app = (OFArc *)[OFApplication sharedApplication].delegate;
}

+ (instancetype)archiveWithIRI: (OFIRI *)IRI
			stream: (OF_KINDOF(OFStream *))stream
			  mode: (OFString *)mode
		      encoding: (OFStringEncoding)encoding
{
	return [[[self alloc] initWithIRI: IRI
				   stream: stream
				     mode: mode
				 encoding: encoding] autorelease];
}

- (instancetype)initWithIRI: (OFIRI *)IRI
		     stream: (OF_KINDOF(OFStream *))stream
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
			OFString *permissionsString = [OFString
			    stringWithFormat:
			    @"%llo", entry.POSIXPermissions
			    .unsignedLongLongValue];

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
			[OFStdOut writeLine:
			    OF_LOCALIZED(@"list_posix_permissions",
			    @"POSIX permissions: %[perm]",
			    @"perm", permissionsString)];
			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(
			    @"list_owner_account_id",
			    @"Owner account ID: %[id]",
			    @"id", entry.ownerAccountID)];
			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(
			    @"list_group_owner_account_id",
			    @"Group owner account ID: %[id]",
			    @"id", entry.groupOwnerAccountID)];

			if (entry.ownerAccountName != nil) {
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_owner_account_name",
				    @"Owner account name: %[name]",
				    @"name", entry.ownerAccountName)];
			}
			if (entry.groupOwnerAccountName != nil) {
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_group_owner_account_name",
				    @"Group owner account name: %[name]",
				    @"name", entry.groupOwnerAccountName)];
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
	OFMutableArray *delayedModificationDates = [OFMutableArray array];
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
			/*
			 * As creating a new file in a directory changes its
			 * modification date, we can only set it once all files
			 * have been created.
			 */
			[delayedModificationDates addObject:
			    [OFPair pairWithFirstObject: outFileName
					   secondObject: entry]];

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

	for (OFPair *pair in delayedModificationDates)
		setModificationDate(pair.firstObject, pair.secondObject);

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
  archiveComment: (OFString *)archiveComment
{
	OFFileManager *fileManager = [OFFileManager defaultManager];

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
		entry.POSIXPermissions =
		    [attributes objectForKey: OFFilePOSIXPermissions];
#endif
		entry.uncompressedSize = attributes.fileSize;
		entry.modificationDate = attributes.fileModificationDate;

#ifdef OF_FILE_MANAGER_SUPPORTS_OWNER
		entry.ownerAccountID =
		    [attributes objectForKey: OFFileOwnerAccountID];
		entry.groupOwnerAccountID =
		    [attributes objectForKey: OFFileGroupOwnerAccountID];
		entry.ownerAccountName = attributes.fileOwnerAccountName;
		entry.groupOwnerAccountName =
		    attributes.fileGroupOwnerAccountName;
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
