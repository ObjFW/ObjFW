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
#import "OFNotOpenException.h"

@interface OFTarArchive_FileReadStream: OFStream
{
	OFStream *_stream;
	OFTarArchiveEntry *_entry;
	size_t _toRead;
	bool _atEndOfStream;
}

- initWithEntry: (OFTarArchiveEntry *)entry
	 stream: (OFStream *)stream;
- (void)of_skip;
@end

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
	[_lastReturnedStream release];

	[super dealloc];
}

- (OFTarArchiveEntry *)nextEntry
{
	OFTarArchiveEntry *entry;
	union {
		char c[512];
		uint32_t u32[512 / sizeof(uint32_t)];
	} buffer;
	bool empty = true;

	if (_mode != OF_TAR_ARCHIVE_MODE_READ)
		@throw [OFInvalidArgumentException exception];

	[_lastReturnedStream of_skip];
	[_lastReturnedStream close];
	[_lastReturnedStream release];
	_lastReturnedStream = nil;

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

	entry = [[[OFTarArchiveEntry alloc]
	    of_initWithHeader: buffer.c] autorelease];

	_lastReturnedStream = [[OFTarArchive_FileReadStream alloc]
	    initWithEntry: entry
		   stream: _stream];

	return entry;
}

- (OFStream *)streamForReadingCurrentEntry
{
	return [[_lastReturnedStream retain] autorelease];
}
@end

@implementation OFTarArchive_FileReadStream
- initWithEntry: (OFTarArchiveEntry *)entry
	 stream: (OFStream *)stream
{
	self = [super init];

	@try {
		_entry = [entry copy];
		_stream = [stream retain];
		_toRead = [entry size];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[self close];

	[_entry release];

	[super dealloc];
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer
			  length: (size_t)length
{
	size_t ret;

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_atEndOfStream)
		return 0;

	if ((uint64_t)length > _toRead)
		length = (size_t)_toRead;

	ret = [_stream readIntoBuffer: buffer
			       length: length];

	if (ret == 0)
		_atEndOfStream = true;

	_toRead -= ret;

	return ret;
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	return _atEndOfStream;
}

- (bool)hasDataInReadBuffer
{
	return ([super hasDataInReadBuffer] || [_stream hasDataInReadBuffer]);
}

- (void)close
{
	[_stream release];
	_stream = nil;

	[super close];
}

- (void)of_skip
{
	char buffer[512];
	uint64_t size;

	while (_toRead >= 512) {
		[_stream readIntoBuffer: buffer
			    exactLength: 512];
		_toRead -= 512;
	}

	if (_toRead > 0) {
		[_stream readIntoBuffer: buffer
			    exactLength: (size_t)_toRead];
		_toRead = 0;
	}

	size = [_entry size];

	if (size % 512 != 0)
		[_stream readIntoBuffer: buffer
			    exactLength: 512 - ((size_t)size % 512)];
}
@end
