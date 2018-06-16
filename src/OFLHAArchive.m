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
#import "OFLHAArchive_LHStream.h"
#import "OFStream.h"
#import "OFSeekableStream.h"
#import "OFString.h"

#import "crc16.h"

#import "OFChecksumMismatchException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotImplementedException.h"
#import "OFNotOpenException.h"
#import "OFTruncatedDataException.h"

@interface OFLHAArchive_FileReadStream: OFStream <OFReadyForReadingObserving>
{
	OF_KINDOF(OFStream *) _stream;
	OF_KINDOF(OFStream *) _decompressedStream;
	OFLHAArchiveEntry *_entry;
	uint32_t _toRead, _bytesConsumed;
	uint16_t _CRC16;
	bool _atEndOfStream;
}

- (instancetype)of_initWithStream: (OF_KINDOF(OFStream *))stream
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
	char header[21];
	size_t headerLen;

	[_lastEntry release];
	_lastEntry = nil;

	[_lastReturnedStream of_skip];
	[_lastReturnedStream close];
	[_lastReturnedStream release];
	_lastReturnedStream = nil;

	for (headerLen = 0; headerLen < 21;) {
		if ([_stream isAtEndOfStream]) {
			if (headerLen == 0)
				return nil;

			if (headerLen == 1 && header[0] == 0)
				return nil;

			@throw [OFTruncatedDataException exception];
		}

		headerLen += [_stream readIntoBuffer: header + headerLen
					      length: 21 - headerLen];
	}

	_lastEntry = [[OFLHAArchiveEntry alloc]
	    of_initWithHeader: header
		       stream: _stream
		     encoding: _encoding];

	_lastReturnedStream = [[OFLHAArchive_FileReadStream alloc]
	    of_initWithStream: _stream
			entry: _lastEntry];

	return [[_lastEntry copy] autorelease];
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

	[_lastEntry release];
	_lastEntry = nil;

	[_lastReturnedStream close];
	[_lastReturnedStream release];
	_lastReturnedStream = nil;

	[_stream release];
	_stream = nil;
}
@end

@implementation OFLHAArchive_FileReadStream
- (instancetype)of_initWithStream: (OF_KINDOF(OFStream *))stream
			    entry: (OFLHAArchiveEntry *)entry
{
	self = [super init];

	@try {
		OFString *compressionMethod;

		_stream = [stream retain];

		compressionMethod = [entry compressionMethod];

		if ([compressionMethod isEqual: @"-lh4-"] ||
		    [compressionMethod isEqual: @"-lh5-"])
			_decompressedStream = [[OFLHAArchive_LHStream alloc]
			    of_initWithStream: stream
				 distanceBits: 4
			       dictionaryBits: 14];
		else if ([compressionMethod isEqual: @"-lh6-"])
			_decompressedStream = [[OFLHAArchive_LHStream alloc]
			    of_initWithStream: stream
				 distanceBits: 5
			       dictionaryBits: 16];
		else if ([compressionMethod isEqual: @"-lh7-"])
			_decompressedStream = [[OFLHAArchive_LHStream alloc]
			    of_initWithStream: stream
				 distanceBits: 5
			       dictionaryBits: 17];
		else
			_decompressedStream = [stream retain];

		_entry = [entry copy];
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

	[_stream release];
	[_decompressedStream release];
	[_entry release];

	[super dealloc];
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	return _atEndOfStream;
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer
			  length: (size_t)length
{
	size_t ret;

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_atEndOfStream)
		return 0;

	if ([_stream isAtEndOfStream] &&
	    ![_decompressedStream hasDataInReadBuffer])
		@throw [OFTruncatedDataException exception];

	if (length > _toRead)
		length = _toRead;

	ret = [_decompressedStream readIntoBuffer: buffer
					   length: length];

	_toRead -= ret;
	_CRC16 = of_crc16(_CRC16, buffer, ret);

	if (_toRead == 0) {
		_atEndOfStream = true;

		if (_CRC16 != [_entry CRC16]) {
			OFString *actualChecksum = [OFString stringWithFormat:
			    @"%04" PRIX16, _CRC16];
			OFString *expectedChecksum = [OFString stringWithFormat:
			    @"%04" PRIX16, [_entry CRC16]];

			@throw [OFChecksumMismatchException
			    exceptionWithActualChecksum: actualChecksum
				       expectedChecksum: expectedChecksum];
		}
	}

	return ret;
}

- (bool)hasDataInReadBuffer
{
	return ([super hasDataInReadBuffer] ||
	    [_decompressedStream hasDataInReadBuffer]);
}

- (int)fileDescriptorForReading
{
	return [_decompressedStream fileDescriptorForReading];
}

- (void)of_skip
{
	OF_KINDOF(OFStream *) stream;
	uint32_t toRead;

	if (_stream == nil || _toRead == 0)
		return;

	stream = _stream;
	toRead = _toRead;

	/*
	 * Get the number of consumed bytes and directly read from the
	 * compressed stream, to make skipping much faster.
	 */
	if ([_decompressedStream isKindOfClass:
	    [OFLHAArchive_LHStream class]]) {
		OFLHAArchive_LHStream *LHStream = _decompressedStream;

		[LHStream close];
		toRead = [_entry compressedSize] - LHStream->_bytesConsumed;

		stream = _stream;
	}

	if ([stream isKindOfClass: [OFSeekableStream class]] &&
	    (sizeof(of_offset_t) > 4 || toRead < INT32_MAX))
		[stream seekToOffset: (of_offset_t)toRead
			      whence: SEEK_CUR];
	else {
		while (toRead > 0) {
			char buffer[512];
			size_t min = toRead;

			if (min > 512)
				min = 512;

			toRead -= [stream readIntoBuffer: buffer
						  length: min];
		}
	}

	_toRead = 0;
}

- (void)close
{
	[self of_skip];

	[_stream release];
	_stream = nil;

	[_decompressedStream release];
	_decompressedStream = nil;

	[super close];
}
@end
