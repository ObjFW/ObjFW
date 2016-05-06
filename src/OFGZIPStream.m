/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
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

#import "OFChecksumFailedException.h"
#import "OFInvalidFormatException.h"

@implementation OFGZIPStream
+ (instancetype)streamWithStream: (OFStream*)stream
{
	return [[[self alloc] initWithStream: stream] autorelease];
}

- initWithStream: (OFStream*)stream
{
	self = [super init];

	@try {
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
	[_stream release];
	[_inflateStream release];
	[_modificationDate release];

	[super dealloc];
}

- (size_t)lowlevelReadIntoBuffer: (void*)buffer
			  length: (size_t)length
{
	uint8_t byte;

	for (;;) {
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

			if ((((uint32_t)_buffer[3] << 24) | (_buffer[2] << 16) |
			    (_buffer[1] << 8) | _buffer[0]) != ~_CRC32)
				@throw [OFChecksumFailedException exception];

			_bytesRead = 0;
			_CRC32 = ~0;
			_state++;
			break;
		case OF_GZIP_STREAM_UNCOMPRESSED_SIZE:
			_bytesRead += [_stream readIntoBuffer: _buffer
						       length: 4 - _bytesRead];

			if ((((uint32_t)_buffer[3] << 24) | (_buffer[2] << 16) |
			    (_buffer[1] << 8) | _buffer[0]) !=
			    _uncompressedSize)
				@throw [OFChecksumFailedException exception];

			_bytesRead = 0;
			_uncompressedSize = 0;
			_state = OF_GZIP_STREAM_ID1;
			break;
		}
	}
}

- (bool)lowlevelIsAtEndOfStream
{
	return [_stream isAtEndOfStream];
}

- (bool)hasDataInReadBuffer
{
	if (_state == OF_GZIP_STREAM_DATA)
		return ([super hasDataInReadBuffer] ||
		    [_inflateStream hasDataInReadBuffer]);

	return ([super hasDataInReadBuffer] || [_stream hasDataInReadBuffer]);
}
@end
