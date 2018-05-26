/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFApplication.h"
#import "OFFileManager.h"
#import "OFStdIOStream.h"
#import "OFLocalization.h"

#import "GZIPArchive.h"
#import "OFZIP.h"

static OFZIP *app;

static void
setPermissions(OFString *destination, OFString *source)
{
#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
	OFFileManager *fileManager = [OFFileManager defaultManager];
	of_file_attributes_t attributes =
	    [fileManager attributesOfItemAtPath: source];
	of_file_attribute_key_t key = of_file_attribute_key_size;
	of_file_attributes_t destinationAttributes = [OFDictionary
	    dictionaryWithObject: [attributes objectForKey: key]
			  forKey: key];

	[fileManager setAttributes: destinationAttributes
		      ofItemAtPath: destination];
#endif
}

@implementation GZIPArchive
+ (void)initialize
{
	if (self == [GZIPArchive class])
		app = (OFZIP *)[[OFApplication sharedApplication] delegate];
}

+ (instancetype)archiveWithStream: (OF_KINDOF(OFStream *))stream
			     mode: (OFString *)mode
			 encoding: (of_string_encoding_t)encoding
{
	return [[[self alloc] initWithStream: stream
					mode: mode
				    encoding: encoding] autorelease];
}

- (instancetype)initWithStream: (OF_KINDOF(OFStream *))stream
			  mode: (OFString *)mode
		      encoding: (of_string_encoding_t)encoding
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
	[of_stderr writeLine: OF_LOCALIZED(@"cannot_list_gz",
	    @"Cannot list files of a .gz archive!")];
	app->_exitStatus = 1;
}

- (void)extractFiles: (OFArray OF_GENERIC(OFString *) *)files
{
	OFString *fileName;
	OFFile *output;

	if ([files count] != 0) {
		[of_stderr writeLine:
		    OF_LOCALIZED(@"cannot_extract_specific_file_from_gz",
		    @"Cannot extract a specific file of a .gz archive!")];
		app->_exitStatus = 1;
		return;
	}

	fileName = [[app->_archivePath lastPathComponent]
	    stringByDeletingPathExtension];

	if (app->_outputLevel >= 0)
		[of_stdout writeString: OF_LOCALIZED(@"extracting_file",
		    @"Extracting %[file]...",
		    @"file", fileName)];

	if (![app shouldExtractFile: fileName
			outFileName: fileName])
		return;

	output = [OFFile fileWithPath: fileName
				 mode: @"w"];
	setPermissions(fileName, app->_archivePath);

	while (![_stream isAtEndOfStream]) {
		ssize_t length = [app copyBlockFromStream: _stream
						 toStream: output
						 fileName: fileName];

		if (length < 0) {
			app->_exitStatus = 1;
			return;
		}
	}

	if (app->_outputLevel >= 0) {
		[of_stdout writeString: @"\r"];
		[of_stdout writeLine: OF_LOCALIZED(@"extracting_file_done",
		    @"Extracting %[file]... done",
		    @"file", fileName)];
	}
}

- (void)printFiles: (OFArray OF_GENERIC(OFString *) *)files
{
	OFString *fileName = [[app->_archivePath lastPathComponent]
	    stringByDeletingPathExtension];

	if ([files count] > 0) {
		[of_stderr writeLine: OF_LOCALIZED(
		    @"cannot_print_specific_file_from_gz",
		    @"Cannot print a specific file of a .gz archive!")];
		app->_exitStatus = 1;
		return;
	}

	while (![_stream isAtEndOfStream]) {
		ssize_t length = [app copyBlockFromStream: _stream
						 toStream: of_stdout
						 fileName: fileName];

		if (length < 0) {
			app->_exitStatus = 1;
			return;
		}
	}
}
@end
