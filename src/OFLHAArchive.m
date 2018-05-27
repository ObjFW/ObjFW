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

#import "OFLHAArchive.h"
#import "OFLHAArchiveEntry.h"
#import "OFLHAArchiveEntry+Private.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
#endif
#import "OFStream.h"
#import "OFSeekableStream.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFNotOpenException.h"

@interface OFLHAArchive_FileReadStream: OFStream <OFReadyForReadingObserving>
{
	OFLHAArchiveEntry *_entry;
	OF_KINDOF(OFStream *) _stream;
	uint32_t _toRead;
	bool _atEndOfStream;
}

- (instancetype)of_initWithStream: (OFStream *)stream
			    entry: (OFLHAArchiveEntry *)entry;
- (void)of_skip;
@end

@implementation OFLHAArchive
@synthesize encoding = _encoding;

+ (instancetype)archiveWithStream: (OF_KINDOF(OFStream *))stream
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

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithStream: (OF_KINDOF(OFStream *))stream
			  mode: (OFString *)mode
{
	self = [super init];

	@try {
		if (![mode isEqual: @"r"])
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: self];

		_stream = [stream retain];
		_encoding = OF_STRING_ENCODING_ISO_8859_1;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

#ifdef OF_HAVE_FILES
- (instancetype)initWithPath: (OFString *)path
			mode: (OFString *)mode
{
	OFFile *file;

	if ([mode isEqual: @"a"])
		file = [[OFFile alloc] initWithPath: path
					       mode: @"r+"];
	else
		file = [[OFFile alloc] initWithPath: path
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
	[self close];

	[super dealloc];
}

- (OFLHAArchiveEntry *)nextEntry
{
	OFLHAArchiveEntry *entry;
	uint8_t headerSize;

	[_lastReturnedStream of_skip];
	[_lastReturnedStream close];
	[_lastReturnedStream release];
	_lastReturnedStream = nil;

	if ([_stream isAtEndOfStream])
		return nil;

	if ([_stream readIntoBuffer: &headerSize
			     length: 1] == 0)
		return nil;

	if (headerSize == 0)
		return nil;

	entry = [[[OFLHAArchiveEntry alloc]
	    of_initWithHeaderSize: headerSize
			   stream: _stream
			 encoding: _encoding] autorelease];

	_lastReturnedStream = [[OFLHAArchive_FileReadStream alloc]
	    of_initWithStream: _stream
			entry: entry];

	return entry;
}

- (OFStream <OFReadyForReadingObserving> *)streamForReadingCurrentEntry
{
	if (_lastReturnedStream == nil)
		@throw [OFInvalidArgumentException exception];

	return [[_lastReturnedStream retain] autorelease];
}

- (void)close
{
	if (_stream == nil)
		return;

	[_lastReturnedStream close];
	[_lastReturnedStream release];
	_lastReturnedStream = nil;

	[_stream release];
	_stream = nil;
}
@end

@implementation OFLHAArchive_FileReadStream
- (instancetype)of_initWithStream: (OFStream *)stream
			    entry: (OFLHAArchiveEntry *)entry
{
	self = [super init];

	@try {
		OFString *method = [entry method];

		if (![method isEqual: @"-lh0-"] && ![method isEqual: @"-lhd-"])
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: self];

		_entry = [entry copy];
		_stream = [stream retain];
		_toRead = [entry uncompressedSize];
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

	if (length > _toRead)
		length = _toRead;

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

- (int)fileDescriptorForReading
{
	return [_stream fileDescriptorForReading];
}

- (void)close
{
	[self of_skip];

	[_stream release];
	_stream = nil;

	[super close];
}

- (void)of_skip
{
	if (_stream == nil || _toRead == 0)
		return;

	if ([_stream isKindOfClass: [OFSeekableStream class]] &&
	    (sizeof(of_offset_t) > 4 || _toRead < INT32_MAX)) {
		[_stream seekToOffset: (of_offset_t)_toRead
			       whence: SEEK_CUR];

		_toRead = 0;
	} else {
		while (_toRead > 0) {
			char buffer[512];
			size_t min = _toRead;

			if (min > 512)
				min = 512;

			_toRead -= [_stream readIntoBuffer: buffer
						    length: min];
		}
	}
}
@end
