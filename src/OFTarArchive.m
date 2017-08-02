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

#import "OFTarArchive.h"
#import "OFTarArchiveEntry.h"
#import "OFTarArchiveEntry+Private.h"
#import "OFStream.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
#endif

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"

@implementation OFTarArchive: OFObject
+ (instancetype)archiveWithStream: (OFStream *)stream
			     mode: (OFString *)mode
{
	return [[[self alloc] initWithStream: stream
					mode: mode] autorelease];
}

#ifdef OF_HAVE_FILES
+ (instancetype)archiveWithPath: (OFString *)path
			   mode: (OFString *)mode
{
	return [[[self alloc] initWithPath: path
				      mode: mode] autorelease];
}
#endif

- initWithStream: (OFStream *)stream
	    mode: (OFString *)mode
{
	self = [super init];

	@try {
		_stream = [stream retain];

		if ([mode isEqual: @"r"])
			_mode = OF_TAR_ARCHIVE_MODE_READ;
		else
			@throw [OFInvalidArgumentException exception];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

#ifdef OF_HAVE_FILES
- initWithPath: (OFString *)path
	  mode: (OFString *)mode
{
	OFFile *file = [[OFFile alloc] initWithPath: path
					       mode: mode];
	@try {
		self = [self initWithStream: file
				       mode: mode];
	} @finally {
		[file release];
	}

	return self;
}
#endif

- (void)dealloc
{
	[_stream release];
	[_lastReturnedEntry release];

	[super dealloc];
}

- (OFTarArchiveEntry *)nextEntry
{
	union {
		char c[512];
		uint32_t u32[512 / sizeof(uint32_t)];
	} buffer;
	bool empty = true;

	if (_mode != OF_TAR_ARCHIVE_MODE_READ)
		@throw [OFInvalidArgumentException exception];

	[_lastReturnedEntry of_skip];
	[_lastReturnedEntry close];
	[_lastReturnedEntry release];
	_lastReturnedEntry = nil;

	if ([_stream isAtEndOfStream])
		return nil;

	[_stream readIntoBuffer: buffer.c
		    exactLength: 512];

	for (size_t i = 0; i < 512 / sizeof(uint32_t); i++)
		if (buffer.u32[i] != 0)
			empty = false;

	if (empty) {
		[_stream readIntoBuffer: buffer.c
			    exactLength: 512];

		for (size_t i = 0; i < 512 / sizeof(uint32_t); i++)
			if (buffer.u32[i] != 0)
				@throw [OFInvalidFormatException exception];

		return nil;
	}

	_lastReturnedEntry = [[OFTarArchiveEntry alloc]
	    of_initWithHeader: buffer.c
		       stream: _stream];

	return _lastReturnedEntry;
}
@end
