/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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
#import "OFSet.h"
#import "OFStdIOStream.h"
#import "OFString.h"

#import "ZooArchive.h"
#import "OFArc.h"

#import "OFSetItemAttributesFailedException.h"

static OFArc *app;

static void
setPermissions(OFString *path, OFZooArchiveEntry *entry)
{
	[app quarantineFile: path];

#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
	OFNumber *POSIXPermissions = entry.POSIXPermissions;

	if (POSIXPermissions != nil) {
		OFFileAttributes attributes;

		POSIXPermissions = [OFNumber numberWithUnsignedShort:
		    POSIXPermissions.unsignedShortValue & 0777];
		attributes = [OFDictionary
		    dictionaryWithObject: POSIXPermissions
				  forKey: OFFilePOSIXPermissions];

		[[OFFileManager defaultManager] setAttributes: attributes
						 ofItemAtPath: path];
	}
#endif
}

static void
setModificationDate(OFString *path, OFZooArchiveEntry *entry)
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

@implementation ZooArchive
+ (void)initialize
{
	if (self == [ZooArchive class])
		app = (OFArc *)[OFApplication sharedApplication].delegate;
}

+ (instancetype)archiveWithIRI: (OFIRI *)IRI
			stream: (OF_KINDOF(OFStream *))stream
			  mode: (OFString *)mode
		      encoding: (OFStringEncoding)encoding
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithIRI: IRI
			       stream: stream
				 mode: mode
			     encoding: encoding]);
}

- (instancetype)initWithIRI: (OFIRI *)IRI
		     stream: (OF_KINDOF(OFStream *))stream
		       mode: (OFString *)mode
		   encoding: (OFStringEncoding)encoding
{
	self = [super init];

	@try {
		_archive = [[OFZooArchive alloc] initWithStream: stream
							   mode: mode];

		if (encoding != OFStringEncodingAutodetect)
			_archive.encoding = encoding;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_archive);

	[super dealloc];
}

- (void)listFiles
{
	OFZooArchiveEntry *entry;

	if (app->_outputLevel >= 1 && _archive.archiveComment != nil) {
		[OFStdOut writeLine: OF_LOCALIZED(
		    @"list_archive_comment",
		    @"Archive comment:")];
		[OFStdOut writeString: @"\t"];
		[OFStdOut writeLine: [_archive.archiveComment
		    stringByReplacingOccurrencesOfString: @"\n"
					      withString: @"\n\t"]];
		[OFStdOut writeLine: @""];
	}

	while ((entry = [_archive nextEntry]) != nil) {
		void *pool = objc_autoreleasePoolPush();

		[app checkForCancellation];

		if (app->_outputLevel < 1 && entry.deleted) {
			objc_autoreleasePoolPop(pool);
			continue;
		}

		[OFStdOut writeLine: entry.fileName];

		if (app->_outputLevel >= 1) {
			OFString *modificationDate = [entry.modificationDate
			    localDateStringWithFormat: @"%Y-%m-%d %H:%M:%S"];
			OFString *compressedSize = [OFString stringWithFormat:
			    @"%llu", entry.compressedSize];
			OFString *uncompressedSize = [OFString stringWithFormat:
			    @"%llu", entry.uncompressedSize];
			OFString *compressionMethod = [OFString
			    stringWithFormat: @"%" PRIu8,
			    entry.compressionMethod];
			OFString *CRC16 = [OFString stringWithFormat:
			    @"%04" PRIX16, entry.CRC16];
			OFString *deleted = [OFString stringWithFormat:
			    @"%" PRIu8, entry.deleted];

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
			    @"method", compressionMethod)];
			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(@"list_crc16",
			    @"CRC16: %[crc16]",
			    @"crc16", CRC16)];
			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(
			    @"list_modification_date",
			    @"Modification date: %[date]",
			    @"date", modificationDate)];

			if (entry.timeZone != nil) {
				float timeZone = entry.timeZone.floatValue;
				int hours = (int)timeZone;
				unsigned char minutes = (timeZone - hours) * 60;
				OFString *timeZoneString;

				if (hours > 0)
					timeZoneString = [OFString
					    stringWithFormat: @"UTC+%02d:%02u",
							      hours, minutes];
				else
					timeZoneString = [OFString
					    stringWithFormat: @"UTC-%02d:%02u",
							      -hours, minutes];

				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_timezone",
				    @"Time zone: %[timezone]",
				    @"timezone", timeZoneString)];
			}

			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(
			    @"list_deleted",
			    @"["
			    @"    'Deleted: ',"
			    @"    ["
			    @"        {'deleted == 0': 'No'},"
			    @"        {'': 'Yes'}"
			    @"    ]"
			    @"]".objectByParsingJSON,
			    @"deleted", deleted)];

			if (entry.fileComment.length > 0) {
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_comment",
				    @"Comment: %[comment]",
				    @"comment", entry.fileComment)];
			}
		}

		if (app->_outputLevel >= 2) {
			uint16_t minVersionNeeded = entry.minVersionNeeded;
			OFString *minVersionNeededString = [OFString
			    stringWithFormat: @"%" PRIu8 @".%" PRIu8,
					      minVersionNeeded >> 8,
					      minVersionNeeded & 0xFF];
			OFString *headerType = [OFString
			    stringWithFormat: @"%" PRIu8,
					      entry.headerType];

			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(
			    @"list_min_version_needed",
			    @"Minimum version needed: %[version]",
			    @"version", minVersionNeededString)];

			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(
			    @"list_header_type",
			    @"Header type: %[type]",
			    @"type", headerType)];

			if (entry.headerType >= 2) {
				OFString *OSID =
				    [OFString stringWithFormat: @"%u",
				    entry.operatingSystemIdentifier];

				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_osid",
				    @"Operating system identifier: "
				    @"%[osid]",
				    @"osid", OSID)];
			}

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
	OFZooArchiveEntry *entry;

	while ((entry = [_archive nextEntry]) != nil) {
		void *pool = objc_autoreleasePoolPush();
		OFString *fileName = entry.fileName;
		OFString *outFileName, *directory;
		OFFile *output;
		OFStream *stream;
		unsigned long long written = 0, size = entry.uncompressedSize;
		int8_t percent = -1, newPercent;

		[app checkForCancellation];

		if (!all && ![files containsObject: fileName])
			continue;

		if (all && entry.deleted)
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
			[OFStdErr writeString: OF_LOCALIZED(@"extracting_file",
			    @"Extracting %[file]...",
			    @"file", fileName)];

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
			ssize_t length;

			[app checkForCancellation];

			length = [app copyBlockFromStream: stream
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

				[OFStdErr writeString: @"\r"];
				[OFStdErr writeString: OF_LOCALIZED(
				    @"extracting_file_percent",
				    @"Extracting %[file]... %[percent]%",
				    @"file", fileName,
				    @"percent", percentString)];
			}
		}

		[output close];
		setModificationDate(outFileName, entry);

		if (app->_outputLevel >= 0) {
			[OFStdErr writeString: @"\r"];
			[OFStdErr writeLine: OF_LOCALIZED(
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
	OFZooArchiveEntry *entry;

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

		[app checkForCancellation];

		if (![files containsObject: fileName])
			continue;

		stream = [_archive streamForReadingCurrentEntry];

		while (!stream.atEndOfStream) {
			ssize_t length;

			[app checkForCancellation];

			length = [app copyBlockFromStream: stream
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

	_archive.archiveComment = archiveComment;

	for (OFString *fileName in files) {
		void *pool = objc_autoreleasePoolPush();
		OFFileAttributes attributes;
		OFFileAttributeType type;
		OFMutableZooArchiveEntry *entry;
		OFStream *output;

		[app checkForCancellation];

		if (app->_outputLevel >= 0)
			[OFStdErr writeString: OF_LOCALIZED(@"adding_file",
			    @"Adding %[file]...",
			    @"file", fileName)];

		attributes = [fileManager attributesOfItemAtPath: fileName];
		type = attributes.fileType;

		if ([type isEqual: OFFileTypeDirectory]) {
			if (app->_outputLevel >= 0) {
				[OFStdErr writeString: @"\r"];
				[OFStdErr writeLine: OF_LOCALIZED(
				    @"adding_file_skipped",
				    @"Adding %[file]... skipped",
				    @"file", fileName)];
			}

			continue;
		}

		entry = [OFMutableZooArchiveEntry entryWithFileName: fileName];
		entry.timeZone = [OFNumber numberWithFloat: 0];
		entry.modificationDate = attributes.fileModificationDate;
#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
		entry.POSIXPermissions =
		    [attributes objectForKey: OFFilePOSIXPermissions];
#endif

		output = [_archive streamForWritingEntry: entry];

		if ([type isEqual: OFFileTypeRegular]) {
			unsigned long long written = 0;
			unsigned long long size = attributes.fileSize;
			int8_t percent = -1, newPercent;

			OFFile *input = [OFFile fileWithPath: fileName
							mode: @"r"];

			while (!input.atEndOfStream) {
				ssize_t length;

				[app checkForCancellation];

				length = [app copyBlockFromStream: input
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

					[OFStdErr writeString: @"\r"];
					[OFStdErr writeString: OF_LOCALIZED(
					    @"adding_file_percent",
					    @"Adding %[file]... %[percent]%",
					    @"file", fileName,
					    @"percent", percentString)];
				}
			}
		}

		if (app->_outputLevel >= 0) {
			[OFStdErr writeString: @"\r"];
			[OFStdErr writeLine: OF_LOCALIZED(
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
