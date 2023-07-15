/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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

#include <errno.h>

#import "OFApplication.h"
#import "OFDate.h"
#import "OFFileManager.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFSet.h"
#import "OFStdIOStream.h"
#import "OFString.h"

#import "LHAArchive.h"
#import "OFArc.h"

#import "OFSetItemAttributesFailedException.h"

static OFArc *app;

static OFString *
indent(OFString *string)
{
	return [string stringByReplacingOccurrencesOfString: @"\n"
						 withString: @"\n\t"];
}

static void
setPermissions(OFString *path, OFLHAArchiveEntry *entry)
{
#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
	OFNumber *POSIXPermissions = entry.POSIXPermissions;

	if (POSIXPermissions == nil)
		return;

	POSIXPermissions = [OFNumber numberWithUnsignedShort:
	    POSIXPermissions.unsignedShortValue & 0777];

	OFFileAttributes attributes = [OFDictionary
	    dictionaryWithObject: POSIXPermissions
			  forKey: OFFilePOSIXPermissions];

	[[OFFileManager defaultManager] setAttributes: attributes
					 ofItemAtPath: path];
#endif
}

static void
setModificationDate(OFString *path, OFLHAArchiveEntry *entry)
{
	OFFileAttributes attributes = [OFDictionary
	    dictionaryWithObject: entry.modificationDate
			  forKey: OFFileModificationDate];
	@try {
		[[OFFileManager defaultManager] setAttributes: attributes
						 ofItemAtPath: path];
	} @catch (OFSetItemAttributesFailedException *e) {
		if (e.errNo != EISDIR)
			@throw e;
	}
}

@implementation LHAArchive
+ (void)initialize
{
	if (self == [LHAArchive class])
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
		_archive = [[OFLHAArchive alloc] initWithStream: stream
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
	OFLHAArchiveEntry *entry;

	while ((entry = [_archive nextEntry]) != nil) {
		void *pool = objc_autoreleasePoolPush();

		[OFStdOut writeLine: entry.fileName];

		if (app->_outputLevel >= 1) {
			OFString *modificationDate = [entry.modificationDate
			    localDateStringWithFormat: @"%Y-%m-%d %H:%M:%S"];
			OFString *compressedSize = [OFString stringWithFormat:
			    @"%llu", entry.compressedSize];
			OFString *uncompressedSize = [OFString stringWithFormat:
			    @"%llu", entry.uncompressedSize];
			OFString *CRC16 = [OFString stringWithFormat:
			    @"%04" PRIX16, entry.CRC16];

			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(
			    @"list_compressed_size",
			    @"["
			    @"    'Compressed: ',"
			    @"    ["
			    @"        {'size == 1': '1 byte'},"
			    @"        {'': '%[size] bytes'}"
			    @"    ]"
			    @"]".objectByParsingJSON,
			    @"size", compressedSize)];
			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(
			    @"list_uncompressed_size",
			    @"["
			    @"    'Uncompressed: ',"
			    @"    ["
			    @"        {'size == 1': '1 byte'},"
			    @"        {'': '%[size] bytes'}"
			    @"    ]"
			    @"]".objectByParsingJSON,
			    @"size", uncompressedSize)];
			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(
			    @"list_compression_method",
			    @"Compression method: %[method]",
			    @"method", entry.compressionMethod)];
			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(@"list_crc16",
			    @"CRC16: %[crc16]",
			    @"crc16", CRC16)];
			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(
			    @"list_modification_date",
			    @"Modification date: %[date]",
			    @"date", modificationDate)];

			if (entry.POSIXPermissions != nil) {
				OFString *permissionsString = [OFString
				    stringWithFormat: @"%llo",
				    entry.POSIXPermissions
				    .unsignedLongLongValue];

				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_posix_permissions",
				    @"POSIX permissions: %[perm]",
				    @"perm", permissionsString)];
			}
			if (entry.ownerAccountID != nil) {
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_owner_account_id",
				    @"Owner account ID: %[id]",
				    @"id", entry.ownerAccountID)];
			}
			if (entry.groupOwnerAccountID != nil) {
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(@"list_gid",
				    @"Group owner account ID: %[id]",
				    @"id", entry.groupOwnerAccountID)];
			}
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
				    @"Group: %[name]",
				    @"name", entry.groupOwnerAccountName)];
			}

			if (app->_outputLevel >= 2) {
				OFString *headerLevel = [OFString
				    stringWithFormat: @"%" PRIu8,
						      entry.headerLevel];

				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_header_level",
				    @"Header level: %[level]",
				    @"level", headerLevel)];

				if (entry.operatingSystemIdentifier != '\0') {
					OFString *OSID =
					    [OFString stringWithFormat: @"%c",
					    entry.operatingSystemIdentifier];

					[OFStdOut writeString: @"\t"];
					[OFStdOut writeLine: OF_LOCALIZED(
					    @"list_osid",
					    @"Operating system identifier: "
					    "%[osid]",
					    @"osid", OSID)];
				}
			}

			if (app->_outputLevel >= 3) {
				OFString *extensions =
				    indent(entry.extensions.description);

				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_extensions",
				    @"Extensions: %[extensions]",
				    @"extensions", extensions)];
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
	OFLHAArchiveEntry *entry;

	while ((entry = [_archive nextEntry]) != nil) {
		void *pool = objc_autoreleasePoolPush();
		OFString *fileName = entry.fileName;
		OFString *outFileName, *directory;
		OFFile *output;
		OFStream *stream;
		unsigned long long written = 0, size = entry.uncompressedSize;
		int8_t percent = -1, newPercent;

		if (!all && ![files containsObject: fileName])
			continue;

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

		if ([fileName hasSuffix: @"/"]) {
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
	OFLHAArchiveEntry *entry;

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
		OFMutableLHAArchiveEntry *entry;
		OFStream *output;

		if (app->_outputLevel >= 0)
			[OFStdOut writeString: OF_LOCALIZED(@"adding_file",
			    @"Adding %[file]...",
			    @"file", fileName)];

		attributes = [fileManager attributesOfItemAtPath: fileName];
		type = attributes.fileType;
		entry = [OFMutableLHAArchiveEntry entryWithFileName: fileName];

#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
		entry.POSIXPermissions =
		    [attributes objectForKey: OFFilePOSIXPermissions];
#endif
		entry.modificationDate = attributes.fileModificationDate;

#ifdef OF_FILE_MANAGER_SUPPORTS_OWNER
		entry.ownerAccountID =
		    [attributes objectForKey: OFFileOwnerAccountID];
		entry.groupOwnerAccountID =
		    [attributes objectForKey: OFFileGroupOwnerAccountID];
		entry.ownerAccountName =
		    [attributes objectForKey: OFFileOwnerAccountName];
		entry.groupOwnerAccountName =
		    [attributes objectForKey: OFFileGroupOwnerAccountName];
#endif

		if ([type isEqual: OFFileTypeDirectory]) {
			entry.compressionMethod = @"-lhd-";

			if (![entry.fileName hasSuffix: @"/"])
				entry.fileName = [entry.fileName
				    stringByAppendingString: @"/"];
		}

		output = [_archive streamForWritingEntry: entry];

		if ([type isEqual: OFFileTypeRegular]) {
			unsigned long long written = 0;
			unsigned long long size = attributes.fileSize;
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
