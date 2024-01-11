/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
#import "OFData.h"
#import "OFDate.h"
#import "OFFileManager.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFSet.h"
#import "OFStdIOStream.h"
#import "OFString.h"

#import "ZIPArchive.h"
#import "OFArc.h"

#import "OFInvalidFormatException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFSetItemAttributesFailedException.h"

static OFArc *app;

static void
setPermissions(OFString *path, OFZIPArchiveEntry *entry)
{
#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
	if ((entry.versionMadeBy >> 8) ==
	    OFZIPArchiveEntryAttributeCompatibilityUNIX) {
		OFNumber *mode = [OFNumber numberWithUnsignedShort:
		    (entry.versionSpecificAttributes >> 16) & 0777];
		OFFileAttributes attributes = [OFDictionary
		    dictionaryWithObject: mode
				  forKey: OFFilePOSIXPermissions];

		[[OFFileManager defaultManager] setAttributes: attributes
						 ofItemAtPath: path];
	}
#endif
}

static void
setModificationDate(OFString *path, OFZIPArchiveEntry *entry)
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

@implementation ZIPArchive
+ (void)initialize
{
	if (self == [ZIPArchive class])
		app = (OFArc *)[OFApplication sharedApplication].delegate;
}

+ (instancetype)archiveWithPath: (OFString *)path
			 stream: (OF_KINDOF(OFStream *))stream
			   mode: (OFString *)mode
		       encoding: (OFStringEncoding)encoding
{
	return [[[self alloc] initWithPath: path
				    stream: stream
				      mode: mode
				  encoding: encoding] autorelease];
}

- (instancetype)initWithPath: (OFString *)path
		      stream: (OF_KINDOF(OFStream *))stream
			mode: (OFString *)mode
		    encoding: (OFStringEncoding)encoding
{
	self = [super init];

	@try {
		_path = [path copy];
		_archive = [[OFZIPArchive alloc] initWithStream: stream
							   mode: mode];
		_archive.delegate = self;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_path release];
	[_archive release];

	[super dealloc];
}

- (OFSeekableStream *)archive: (OFZIPArchive *)archive
	    wantsPartNumbered: (unsigned int)partNumber
	       lastPartNumber: (unsigned int)lastPartNumber
{
	OFString *path;

	if ([_path.pathExtension caseInsensitiveCompare: @"zip"] !=
	    OFOrderedSame)
		return nil;

	if (partNumber > 98)
		return nil;

	if (partNumber == lastPartNumber)
		path = _path;
	else
		path = [_path.stringByDeletingPathExtension
		    stringByAppendingFormat: @".z%02u", partNumber + 1];

	return [OFFile fileWithPath: path mode: @"r"];
}

- (void)listFiles
{
	for (OFZIPArchiveEntry *entry in _archive.entries) {
		void *pool = objc_autoreleasePoolPush();

		[OFStdOut writeLine: entry.fileName];

		if (app->_outputLevel >= 1) {
			OFString *compressedSize = [OFString
			    stringWithFormat: @"%" PRIu64,
					      entry.compressedSize];
			OFString *uncompressedSize = [OFString
			    stringWithFormat: @"%" PRIu64,
					      entry.uncompressedSize];
			OFString *compressionMethod =
			    OFZIPArchiveEntryCompressionMethodName(
			    entry.compressionMethod);
			OFString *CRC32 = [OFString
			    stringWithFormat: @"%08" PRIX32, entry.CRC32];
			OFString *modificationDate = [entry.modificationDate
			    localDateStringWithFormat: @"%Y-%m-%d %H:%M:%S"];

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
			[OFStdOut writeLine: OF_LOCALIZED(@"list_crc32",
			    @"CRC32: %[crc32]",
			    @"crc32", CRC32)];
			[OFStdOut writeString: @"\t"];
			[OFStdOut writeLine: OF_LOCALIZED(
			    @"list_modification_date",
			    @"Modification date: %[date]",
			    @"date", modificationDate)];

			if (app->_outputLevel >= 2) {
				uint16_t versionMadeBy = entry.versionMadeBy;
				OFZIPArchiveEntryAttributeCompatibility UNIX =
				    OFZIPArchiveEntryAttributeCompatibilityUNIX;

				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_version_made_by",
				    @"Version made by: %[version]",
				    @"version",
				    OFZIPArchiveEntryVersionToString(
				    versionMadeBy))];
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_min_version_needed",
				    @"Minimum version needed: %[version]",
				    @"version",
				    OFZIPArchiveEntryVersionToString(
				    entry.minVersionNeeded))];

				if ((versionMadeBy >> 8) == UNIX) {
					uint32_t mode = entry
					    .versionSpecificAttributes >> 16;
					OFString *modeString = [OFString
					    stringWithFormat: @"%06o", mode];
					[OFStdOut writeString: @"\t"];
					[OFStdOut writeLine: OF_LOCALIZED(
					    @"list_mode",
					    @"Mode: %[mode]",
					    @"mode", modeString)];
				}
			}

			if (app->_outputLevel >= 3) {
				OFString *GPBF = [OFString stringWithFormat:
				    @"%04" PRIx16, entry.generalPurposeBitFlag];

				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_general_purpose_bit_flag",
				    @"General purpose bit flag: %[gpbf]",
				    @"gpbf", GPBF)];

				if (entry.extraField != nil) {
					[OFStdOut writeString: @"\t"];
					[OFStdOut writeLine: OF_LOCALIZED(
					    @"list_extra_field",
					    @"Extra field: %[extra]",
					    @"extra",
					    entry.extraField.description)];
				}
			}

			if (entry.fileComment.length > 0) {
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_comment",
				    @"Comment: %[comment]",
				    @"comment", entry.fileComment)];
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

	for (OFZIPArchiveEntry *entry in _archive.entries) {
		void *pool = objc_autoreleasePoolPush();
		OFString *fileName = entry.fileName;
		OFString *outFileName, *directory;
		OFStream *stream;
		OFFile *output;
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

		stream = [_archive streamForReadingFile: fileName];
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

- (void)printFiles: (OFArray OF_GENERIC(OFString *) *)files
{
	OFStream *stream;

	if (files.count < 1) {
		[OFStdErr writeLine: OF_LOCALIZED(@"print_no_file_specified",
		    @"Need one or more files to print!")];
		app->_exitStatus = 1;
		return;
	}

	for (OFString *path in files) {
		@try {
			stream = [_archive streamForReadingFile: path];
		} @catch (OFOpenItemFailedException *e) {
			if (e.errNo == ENOENT) {
				[OFStdErr writeLine: OF_LOCALIZED(
				    @"file_not_in_archive",
				    @"File %[file] is not in the archive!",
				    @"file", e.path)];
				app->_exitStatus = 1;
				continue;
			}

			@throw e;
		}

		while (!stream.atEndOfStream) {
			ssize_t length = [app copyBlockFromStream: stream
							 toStream: OFStdOut
							 fileName: path];

			if (length < 0) {
				app->_exitStatus = 1;
				return;
			}
		}

		[stream close];
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

	for (OFString *localFileName in files) {
		void *pool = objc_autoreleasePoolPush();
		OFArray OF_GENERIC (OFString *) *components;
		OFString *fileName;
		OFFileAttributes attributes;
		bool isDirectory = false;
		OFMutableZIPArchiveEntry *entry;
		unsigned long long size;
		OFStream *output;

		components = localFileName.pathComponents;
		fileName = [components componentsJoinedByString: @"/"];

		attributes = [fileManager
		    attributesOfItemAtPath: localFileName];

		if ([attributes.fileType isEqual: OFFileTypeDirectory]) {
			isDirectory = true;
			fileName = [fileName stringByAppendingString: @"/"];
		}

		if (app->_outputLevel >= 0)
			[OFStdOut writeString: OF_LOCALIZED(@"adding_file",
			    @"Adding %[file]...",
			    @"file", fileName)];

		entry = [OFMutableZIPArchiveEntry entryWithFileName: fileName];

		size = (isDirectory ? 0 : attributes.fileSize);
		entry.compressedSize = size;
		entry.uncompressedSize = size;

		entry.compressionMethod =
		    OFZIPArchiveEntryCompressionMethodNone;
		entry.modificationDate = attributes.fileModificationDate;

		[entry makeImmutable];

		output = [_archive streamForWritingEntry: entry];

		if (!isDirectory) {
			unsigned long long written = 0;
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
