/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#import "OFGZIPStream.h"
#import "OFInflateStream.h"
#import "OFDate.h"

#import "crc32.h"

#import "OFChecksumMismatchException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"
#import "OFNotOpenException.h"
#import "OFTruncatedDataException.h"

@implementation OFGZIPStream
+ (instancetype)streamWithStream: (OFStream *)stream
			    mode: (OFString *)mode
{
	return [[[self alloc] initWithStream: stream
					mode: mode] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithStream: (OFStream *)stream
			  mode: (OFString *)mode
{
	self = [super init];

	@try {
		if (![mode isEqual: @"r"])
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: self];

		_stream = [stream retain];
		_CRC32 = ~0;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[self close];

	[_inflateStream release];
	[_modificationDate release];

	[super dealloc];
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer
			  length: (size_t)length
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	for (;;) {
		uint8_t byte;
		uint32_t CRC32, uncompressedSize;

		if ([_stream isAtEndOfStream]) {
			if (_state != OF_GZIP_STREAM_ID1)
				@throw [OFTruncatedDataException exception];

			return 0;
		}

		switch (_state) {
		case OF_GZIP_STREAM_ID1:
		case OF_GZIP_STREAM_ID2:
		case OF_GZIP_STREAM_COMPRESSION_METHOD:
			if ([_stream readIntoBuffer: &byte
					     length: 1] < 1)
				return 0;

			if ((_state == OF_GZIP_STREAM_ID1 && byte != 0x1F) ||
			    (_state == OF_GZIP_STREAM_ID2 && byte != 0x8B) ||
			    (_state == OF_GZIP_STREAM_COMPRESSION_METHOD &&
			    byte != 8))
				@throw [OFInvalidFormatException exception];

			_state++;
			break;
		case OF_GZIP_STREAM_FLAGS:
			if ([_stream readIntoBuffer: &byte
					     length: 1] < 1)
				return 0;

			_flags = byte;
			_state++;
			break;
		case OF_GZIP_STREAM_MODIFICATION_TIME:
			_bytesRead += [_stream
			    readIntoBuffer: _buffer + _bytesRead
				    length: 4 - _bytesRead];

			if (_bytesRead < 4)
				return 0;

			[_modificationDate release];
			_modificationDate = nil;

			_modificationDate = [[OFDate alloc]
			    initWithTimeIntervalSince1970:
			    (_buffer[3] << 24) | (_buffer[2] << 16) |
			    (_buffer[1] << 8) | _buffer[0]];

			_bytesRead = 0;
			_state++;
			break;
		case OF_GZIP_STREAM_EXTRA_FLAGS:
			if ([_stream readIntoBuffer: &byte
					     length: 1] < 1)
				return 0;

			_extraFlags = byte;
			_state++;
			break;
		case OF_GZIP_STREAM_OS:
			if ([_stream readIntoBuffer: &byte
					     length: 1] < 1)
				return 0;

			_OS = byte;
			_state++;
			break;
		case OF_GZIP_STREAM_EXTRA_LENGTH:
			if (!(_flags & OF_GZIP_STREAM_FLAG_EXTRA)) {
				_state += 2;
				break;
			}

			_bytesRead += [_stream
			    readIntoBuffer: _buffer + _bytesRead
				    length: 2 - _bytesRead];

			if (_bytesRead < 2)
				return 0;

			_extraLength = (_buffer[1] << 8) | _buffer[0];
			_bytesRead = 0;
			_state++;
			break;
		case OF_GZIP_STREAM_EXTRA:
			{
				char tmp[512];
				size_t toRead = _extraLength - _bytesRead;

				if (toRead > 512)
					toRead = 512;

				_bytesRead += [_stream readIntoBuffer: tmp
							       length: toRead];
			}

			if (_bytesRead < _extraLength)
				return 0;

			_bytesRead = 0;
			_state++;
			break;
		case OF_GZIP_STREAM_NAME:
			if (!(_flags & OF_GZIP_STREAM_FLAG_NAME)) {
				_state++;
				break;
			}

			do {
				if ([_stream readIntoBuffer: &byte
						     length: 1] < 1)
					return 0;
			} while (byte != 0);

			_state++;
			break;
		case OF_GZIP_STREAM_COMMENT:
			if (!(_flags & OF_GZIP_STREAM_FLAG_COMMENT)) {
				_state++;
				break;
			}

			do {
				if ([_stream readIntoBuffer: &byte
						     length: 1] < 1)
					return 0;
			} while (byte != 0);

			_state++;
			break;
		case OF_GZIP_STREAM_HEADER_CRC16:
			if (!(_flags & OF_GZIP_STREAM_FLAG_HEADER_CRC16)) {
				_state++;
				break;
			}

			_bytesRead += [_stream
			    readIntoBuffer: _buffer + _bytesRead
				    length: 2 - _bytesRead];

			if (_bytesRead < 2)
				return 0;

			/*
			 * Header CRC16 is not checked, as I could not find a
			 * single file in the wild that actually has a header
			 * CRC16 - and thus no file to test against.
			 */

			_bytesRead = 0;
			_state++;
			break;
		case OF_GZIP_STREAM_DATA:
			if (_inflateStream == nil)
				_inflateStream = [[OFInflateStream alloc]
				    initWithStream: _stream];

			if (![_inflateStream isAtEndOfStream]) {
				size_t bytesRead = [_inflateStream
				    readIntoBuffer: buffer
					    length: length];

				_CRC32 = of_crc32(_CRC32, buffer, bytesRead);
				_uncompressedSize += bytesRead;

				return bytesRead;
			}

			[_inflateStream release];
			_inflateStream = nil;

			_state++;
			break;
		case OF_GZIP_STREAM_CRC32:
			_bytesRead += [_stream readIntoBuffer: _buffer
						       length: 4 - _bytesRead];

			if (_bytesRead < 4)
				return 0;

			CRC32 = ((uint32_t)_buffer[3] << 24) |
			    (_buffer[2] << 16) | (_buffer[1] << 8) | _buffer[0];
			if (~_CRC32 != CRC32) {
				OFString *actual = [OFString stringWithFormat:
				    @"%08" PRIX32, ~_CRC32];
				OFString *expected = [OFString stringWithFormat:
				    @"%08" PRIX32, CRC32];

				@throw [OFChecksumMismatchException
				    exceptionWithActualChecksum: actual
					       expectedChecksum: expected];
			}

			_bytesRead = 0;
			_CRC32 = ~0;
			_state++;
			break;
		case OF_GZIP_STREAM_UNCOMPRESSED_SIZE:
			_bytesRead += [_stream readIntoBuffer: _buffer
						       length: 4 - _bytesRead];

			uncompressedSize = ((uint32_t)_buffer[3] << 24) |
			    (_buffer[2] << 16) | (_buffer[1] << 8) | _buffer[0];
			if (_uncompressedSize != uncompressedSize) {
				OFString *actual = [OFString stringWithFormat:
				    @"%" PRIu32, _uncompressedSize];
				OFString *expected = [OFString stringWithFormat:
				    @"%" PRIu32, uncompressedSize];

				@throw [OFChecksumMismatchException
				    exceptionWithActualChecksum: actual
					       expectedChecksum: expected];
			}

			_bytesRead = 0;
			_uncompressedSize = 0;
			_state = OF_GZIP_STREAM_ID1;
			break;
		}
	}
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	return [_stream isAtEndOfStream];
}

- (bool)hasDataInReadBuffer
{
	if (_state == OF_GZIP_STREAM_DATA)
		return ([super hasDataInReadBuffer] ||
		    [_inflateStream hasDataInReadBuffer]);

	return ([super hasDataInReadBuffer] || [_stream hasDataInReadBuffer]);
}

- (void)close
{
	[_stream release];
	_stream = nil;

	[super close];
}
@end
