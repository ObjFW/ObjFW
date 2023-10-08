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

#import "OFApplication.h"
#import "OFFileManager.h"
#import "OFStdIOStream.h"
#import "OFLocale.h"

#import "GZIPArchive.h"
#import "OFArc.h"

static OFArc *app;

static void
setPermissions(OFString *destination, OFString *source)
{
#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
	OFFileManager *fileManager = [OFFileManager defaultManager];
	OFFileAttributes attributes = [fileManager
	    attributesOfItemAtPath: source];
	OFFileAttributeKey key = OFFilePOSIXPermissions;
	OFFileAttributes destinationAttributes = [OFDictionary
	    dictionaryWithObject: [attributes objectForKey: key]
			  forKey: key];

	[fileManager setAttributes: destinationAttributes
		      ofItemAtPath: destination];
#endif
}

static void
setModificationDate(OFString *path, OFGZIPStream *stream)
{
	OFDate *modificationDate = stream.modificationDate;
	OFFileAttributes attributes;

	if (modificationDate == nil)
		return;

	attributes = [OFDictionary
	    dictionaryWithObject: modificationDate
			  forKey: OFFileModificationDate];
	[[OFFileManager defaultManager] setAttributes: attributes
					 ofItemAtPath: path];
}

@implementation GZIPArchive
+ (void)initialize
{
	if (self == [GZIPArchive class])
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
		_stream = [[OFGZIPStream alloc] initWithStream: stream
							  mode: mode];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_stream release];

	[super dealloc];
}

- (void)listFiles
{
	[OFStdErr writeLine: OF_LOCALIZED(@"cannot_list_gz",
	    @"Cannot list files of a .gz archive!")];
	app->_exitStatus = 1;
}

- (void)extractFiles: (OFArray OF_GENERIC(OFString *) *)files
{
	OFString *fileName;
	OFFile *output;

	if (files.count != 0) {
		[OFStdErr writeLine: OF_LOCALIZED(
		    @"cannot_extract_specific_file_from_gz",
		    @"Cannot extract a specific file of a .gz archive!")];
		app->_exitStatus = 1;
		return;
	}

	fileName = app->_archivePath.lastPathComponent
	    .stringByDeletingPathExtension;

	if (app->_outputLevel >= 0)
		[OFStdOut writeString: OF_LOCALIZED(@"extracting_file",
		    @"Extracting %[file]...",
		    @"file", fileName)];

	if (![app shouldExtractFile: fileName outFileName: fileName])
		return;

	output = [OFFile fileWithPath: fileName mode: @"w"];
	setPermissions(fileName, app->_archivePath);

	while (!_stream.atEndOfStream) {
		ssize_t length = [app copyBlockFromStream: _stream
						 toStream: output
						 fileName: fileName];

		if (length < 0) {
			app->_exitStatus = 1;
			return;
		}
	}

	[output close];
	setModificationDate(fileName, _stream);

	if (app->_outputLevel >= 0) {
		[OFStdOut writeString: @"\r"];
		[OFStdOut writeLine: OF_LOCALIZED(@"extracting_file_done",
		    @"Extracting %[file]... done",
		    @"file", fileName)];
	}
}

- (void)printFiles: (OFArray OF_GENERIC(OFString *) *)files
{
	OFString *fileName = app->_archivePath.lastPathComponent
	    .stringByDeletingPathExtension;

	if (files.count > 0) {
		[OFStdErr writeLine: OF_LOCALIZED(
		    @"cannot_print_specific_file_from_gz",
		    @"Cannot print a specific file of a .gz archive!")];
		app->_exitStatus = 1;
		return;
	}

	while (!_stream.atEndOfStream) {
		ssize_t length = [app copyBlockFromStream: _stream
						 toStream: OFStdOut
						 fileName: fileName];

		if (length < 0) {
			app->_exitStatus = 1;
			return;
		}
	}
}
@end
