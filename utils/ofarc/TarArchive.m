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
		_archive = [[OFTarArchive alloc] initWithStream: stream
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
	OFTarArchiveEntry *entry;

	while ((entry = [_archive nextEntry]) != nil) {
		void *pool = objc_autoreleasePoolPush();

		[app checkForCancellation];

		[OFStdOut writeLine:
		    entry.fileName.stringByReplacingControlCharacters];

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

			switch (entry.fileType) {
			case OFArchiveEntryFileTypeRegular:
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_type_regular",
				    @"Type: Regular file")];
				break;
			case OFArchiveEntryFileTypeLink:
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_type_hardlink",
				    @"Type: Hard link")];
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_link_target",
				    @"Target file name: %[target]",
				    @"target", entry.targetFileName)];
				break;
			case OFArchiveEntryFileTypeSymbolicLink:
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_type_symlink",
				    @"Type: Symbolic link")];
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_link_target",
				    @"Target file name: %[target]",
				    @"target", entry.targetFileName)];
				break;
			case OFArchiveEntryFileTypeCharacterDevice: {
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
			case OFArchiveEntryFileTypeBlockDevice: {
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
			case OFArchiveEntryFileTypeDirectory:
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_type_directory",
				    @"Type: Directory")];
				break;
			case OFArchiveEntryFileTypeFIFO:
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_type_fifo",
				    @"Type: FIFO")];
				break;
			case OFArchiveEntryFileTypeContiguousFile:
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

			if (entry.extendedHeader != nil) {
				OFString *header =
				    [entry.extendedHeader.description
				    stringByReplacingOccurrencesOfString: @"\n"
				    withString: @"\n\t"];
				[OFStdOut writeString: @"\t"];
				[OFStdOut writeLine: OF_LOCALIZED(
				    @"list_extended_header",
				    @"Extended header: %[header]",
				    @"header", header)];
			}
		}

		objc_autoreleasePoolPop(pool);
	}
}

- (void)extractFiles: (OFArray OF_GENERIC(OFString *) *)files
{
	OFFileManager *fileManager = [OFFileManager defaultManager];
	bool all = (files.count == 0);
	OFMutableArray *delayed = [OFMutableArray array];
	OFMutableSet OF_GENERIC(OFString *) *missing =
	    [OFMutableSet setWithArray: files];
	OFTarArchiveEntry *entry;

	while ((entry = [_archive nextEntry]) != nil) {
		void *pool = objc_autoreleasePoolPush();
		OFString *fileName = entry.fileName;
		OFArchiveEntryFileType fileType = entry.fileType;
		OFString *outFileName, *directory;
		OFFile *output;
		OFStream *stream;
		unsigned long long written = 0, size = entry.uncompressedSize;
		int8_t percent = -1, newPercent;

		[app checkForCancellation];

		if (!all && ![files containsObject: fileName])
			continue;

		if (fileType != OFArchiveEntryFileTypeRegular &&
		    fileType != OFArchiveEntryFileTypeDirectory) {
			if (app->_outputLevel >= 0)
				[OFStdErr writeLine: OF_LOCALIZED(
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
			[OFStdErr writeString: OF_LOCALIZED(@"extracting_file",
			    @"Extracting %[file]...",
			    @"file", fileName)];

		if (fileType == OFArchiveEntryFileTypeDirectory ||
		    (fileType == OFArchiveEntryFileTypeRegular &&
		    [fileName hasSuffix: @"/"])) {
			[fileManager createDirectoryAtPath: outFileName
					     createParents: true];
			/*
			 * As creating a new file in a directory changes its
			 * modification date, we can only set it once all files
			 * have been created. Also, restricting permissions
			 * (e.g. removing write permissions) before all files
			 * in a directory have been written would also fail.
			 */
			[delayed addObject:
			    [OFPair pairWithFirstObject: outFileName
					   secondObject: entry]];

			if (app->_outputLevel >= 0) {
				[OFStdErr writeString: @"\r"];
				[OFStdErr writeLine: OF_LOCALIZED(
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
		/*
		 * Permissions on AmigaOS apply even to already opened files,
		 * so need to be set after the file is written and the
		 * modification date is set.
		 */
#ifndef OF_AMIGAOS
		setPermissions(outFileName, entry);
#endif

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
		/*
		 * Permissions on AmigaOS apply even to already opened files,
		 * so need to be set after the file is written and the
		 * modification date is set.
		 */
#ifdef OF_AMIGAOS
		setPermissions(outFileName, entry);
#endif

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

	for (OFPair *pair in delayed) {
		setModificationDate(pair.firstObject, pair.secondObject);
		setPermissions(pair.firstObject, pair.secondObject);
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

	for (OFString *fileName in files) {
		void *pool = objc_autoreleasePoolPush();
		OFFileAttributes attributes;
		OFFileAttributeType type;
		OFMutableTarArchiveEntry *entry;
		OFStream *output;

		[app checkForCancellation];

		if (app->_outputLevel >= 0)
			[OFStdErr writeString: OF_LOCALIZED(@"adding_file",
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
			entry.fileType = OFArchiveEntryFileTypeRegular;
		else if ([type isEqual: OFFileTypeDirectory]) {
			entry.fileType = OFArchiveEntryFileTypeDirectory;
			entry.uncompressedSize = 0;
		} else if ([type isEqual: OFFileTypeSymbolicLink]) {
			entry.fileType = OFArchiveEntryFileTypeSymbolicLink;
			entry.targetFileName =
			    attributes.fileSymbolicLinkDestination;
			entry.uncompressedSize = 0;
		}

		[entry makeImmutable];

		output = [_archive streamForWritingEntry: entry];

		if (entry.fileType == OFArchiveEntryFileTypeRegular) {
			unsigned long long written = 0;
			unsigned long long size = entry.uncompressedSize;
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
