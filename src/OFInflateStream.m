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

#include <stdlib.h>
#include <string.h>

#ifndef OF_INFLATE64_STREAM_M
# import "OFInflateStream.h"
#else
# import "OFInflate64Stream.h"
# define OFInflateStream OFInflate64Stream
#endif
#import "OFHuffmanTree.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidFormatException.h"
#import "OFNotOpenException.h"
#import "OFOutOfMemoryException.h"

#ifndef OF_INFLATE64_STREAM_M
# define bufferSize OFInflateStreamBufferSize
#else
# define bufferSize OFInflate64StreamBufferSize
#endif

enum State {
	stateBlockHeader,
	stateUncompressedBlockHeader,
	stateUncompressedBlock,
	stateHuffmanTree,
	stateHuffmanBlock
};

enum HuffmanState {
	huffmanStateWriteValue,
	huffmanStateAwaitCode,
	huffmanStateAwaitLengthExtraBits,
	huffmanStateAwaitDistance,
	huffmanStateAwaitDistanceExtraBits,
	huffmanStateProcessPair
};

#ifndef OF_INFLATE64_STREAM_M
static const uint8_t numDistanceCodes = 30;
static const uint8_t lengthCodes[29] = {
	/* indices are -257, values -3 */
	0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40, 48, 56,
	64, 80, 96, 112, 128, 160, 192, 224, 255
};
static const uint8_t lengthExtraBits[29] = {
	0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4,
	5, 5, 5, 5, 0
};
static const uint16_t distanceCodes[30] = {
	1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385,
	513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577
};
static const uint8_t distanceExtraBits[30] = {
	0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10,
	10, 11, 11, 12, 12, 13, 13
};
#else
static const uint8_t numDistanceCodes = 32;
static const uint8_t lengthCodes[29] = {
	/* indices are -257, values -3 */
	0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40, 48, 56,
	64, 80, 96, 112, 128, 160, 192, 224, 0
};
static const uint8_t lengthExtraBits[29] = {
	0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4,
	5, 5, 5, 5, 16
};
static const uint16_t distanceCodes[32] = {
	1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385,
	513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577,
	32769, 49153
};
static const uint8_t distanceExtraBits[32] = {
	0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10,
	10, 11, 11, 12, 12, 13, 13, 14, 14
};
#endif
static const uint8_t codeLengthsOrder[19] = {
	16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15
};
static OFHuffmanTree fixedLitLenTree, fixedDistTree;

@implementation OFInflateStream
@synthesize underlyingStream = _stream;

static OF_INLINE bool
tryReadBits(OFInflateStream *stream, uint16_t *bits, uint8_t count)
{
	uint16_t ret = stream->_savedBits;

	OFAssert(stream->_savedBitsLength < count);

	for (uint_fast8_t i = stream->_savedBitsLength; i < count; i++) {
		if OF_UNLIKELY (stream->_bitIndex == 8) {
			if OF_LIKELY (stream->_bufferIndex <
			    stream->_bufferLength)
				stream->_byte =
				    stream->_buffer[stream->_bufferIndex++];
			else {
				size_t length = [stream->_stream
				    readIntoBuffer: stream->_buffer
					    length: bufferSize];

				if OF_UNLIKELY (length < 1) {
					stream->_savedBits = ret;
					stream->_savedBitsLength = i;
					return false;
				}

				stream->_byte = stream->_buffer[0];
				stream->_bufferIndex = 1;
				stream->_bufferLength = (uint16_t)length;
			}

			stream->_bitIndex = 0;
		}

		ret |= ((stream->_byte >> stream->_bitIndex++) & 1) << i;
	}

	stream->_savedBits = 0;
	stream->_savedBitsLength = 0;
	*bits = ret;

	return true;
}

+ (void)initialize
{
	uint8_t lengths[288];

	if (self != [OFInflateStream class])
		return;

	for (uint16_t i = 0; i <= 143; i++)
		lengths[i] = 8;
	for (uint16_t i = 144; i <= 255; i++)
		lengths[i] = 9;
	for (uint16_t i = 256; i <= 279; i++)
		lengths[i] = 7;
	for (uint16_t i = 280; i <= 287; i++)
		lengths[i] = 8;

	fixedLitLenTree = OFHuffmanTreeNew(lengths, 288);

	for (uint16_t i = 0; i <= 31; i++)
		lengths[i] = 5;

	fixedDistTree = OFHuffmanTreeNew(lengths, 32);
}

+ (instancetype)streamWithStream: (OFStream *)stream
{
	return [[[self alloc] initWithStream: stream] autorelease];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithStream: (OFStream *)stream
{
	self = [super init];

	@try {
		_stream = [stream retain];

		/* 0-7 address the bit, 8 means fetch next byte */
		_bitIndex = 8;

#ifdef OF_INFLATE64_STREAM_M
		_slidingWindowMask = 0xFFFF;
#else
		_slidingWindowMask = 0x7FFF;
#endif
		_slidingWindow = OFAllocZeroedMemory(_slidingWindowMask + 1, 1);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_stream != nil)
		[self close];

	OFFreeMemory(_slidingWindow);

	if (_state == stateHuffmanTree) {
		OFFreeMemory(_context.huffmanTree.lengths);

		if (_context.huffmanTree.codeLenTree != NULL)
			OFHuffmanTreeFree(_context.huffmanTree.codeLenTree);
	}

	if (_state == stateHuffmanTree || _state == stateHuffmanBlock) {
		if (_context.huffman.litLenTree != fixedLitLenTree)
			OFHuffmanTreeFree(_context.huffman.litLenTree);
		if (_context.huffman.distTree != fixedDistTree)
			OFHuffmanTreeFree(_context.huffman.distTree);
	}

	[super dealloc];
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer_
			  length: (size_t)length
{
	unsigned char *buffer = buffer_;
	uint16_t bits = 0, tmp, value = 0;
	size_t bytesWritten = 0;
	unsigned char *slidingWindow;
	uint16_t slidingWindowIndex;

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_atEndOfStream)
		return 0;

start:
	switch ((enum State)_state) {
	case stateBlockHeader:
		if OF_UNLIKELY (_inLastBlock) {
			[_stream unreadFromBuffer: _buffer + _bufferIndex
					   length: _bufferLength -
						   _bufferIndex];
			_bufferIndex = _bufferLength = 0;

			_atEndOfStream = true;
			return bytesWritten;
		}

		if OF_UNLIKELY (!tryReadBits(self, &bits, 3))
			return bytesWritten;

		_inLastBlock = (bits & 1);

		switch (bits >> 1) {
		case 0: /* No compression */
			_state = stateUncompressedBlockHeader;
			_bitIndex = 8;
			_context.uncompressedHeader.position = 0;
			memset(_context.uncompressedHeader.length, 0, 4);
			break;
		case 1: /* Fixed Huffman */
			_state = stateHuffmanBlock;
			_context.huffman.state = huffmanStateAwaitCode;
			_context.huffman.litLenTree = fixedLitLenTree;
			_context.huffman.distTree = fixedDistTree;
			_context.huffman.treeIter = fixedLitLenTree;
			break;
		case 2: /* Dynamic Huffman */
			_state = stateHuffmanTree;
			_context.huffmanTree.lengths = NULL;
			_context.huffmanTree.receivedCount = 0;
			_context.huffmanTree.value = 0xFE;
			_context.huffmanTree.litLenCodesCount = 0xFF;
			_context.huffmanTree.distCodesCount = 0xFF;
			_context.huffmanTree.codeLenCodesCount = 0xFF;
			break;
		default:
			@throw [OFInvalidFormatException exception];
		}

		goto start;
	case stateUncompressedBlockHeader:
#define CTX _context.uncompressedHeader
		/* FIXME: This can be done more efficiently than unreading */
		[_stream unreadFromBuffer: _buffer + _bufferIndex
				   length: _bufferLength - _bufferIndex];
		_bufferIndex = _bufferLength = 0;

		CTX.position += [_stream
		    readIntoBuffer: CTX.length + CTX.position
			    length: 4 - CTX.position];

		if OF_UNLIKELY (CTX.position < 4)
			return bytesWritten;

		if OF_UNLIKELY ((CTX.length[0] | (CTX.length[1] << 8)) !=
		    (uint16_t)~(CTX.length[2] | (CTX.length[3] << 8)))
			@throw [OFInvalidFormatException exception];

		_state = stateUncompressedBlock;

		/*
		 * Do not reorder! _context.uncompressed.position and
		 * _context.uncompressedHeader.length overlap!
		 */
		_context.uncompressed.length =
		    CTX.length[0] | (CTX.length[1] << 8);
		_context.uncompressed.position = 0;

		goto start;
#undef CTX
	case stateUncompressedBlock:
#define CTX _context.uncompressed
		if OF_UNLIKELY (length == 0)
			return bytesWritten;

		tmp = (length < (size_t)CTX.length - CTX.position
		    ? (uint16_t)length : CTX.length - CTX.position);

		tmp = (uint16_t)[_stream readIntoBuffer: buffer + bytesWritten
						 length: tmp];

		if OF_UNLIKELY (tmp == 0)
			return bytesWritten;

		slidingWindow = _slidingWindow;
		slidingWindowIndex = _slidingWindowIndex;
		for (uint_fast16_t i = 0; i < tmp; i++) {
			slidingWindow[slidingWindowIndex] =
			    buffer[bytesWritten + i];
			slidingWindowIndex = (slidingWindowIndex + 1) &
			    _slidingWindowMask;
		}
		_slidingWindowIndex = slidingWindowIndex;

		length -= tmp;
		bytesWritten += tmp;

		CTX.position += tmp;
		if OF_UNLIKELY (CTX.position == CTX.length)
			_state = stateBlockHeader;

		goto start;
#undef CTX
	case stateHuffmanTree:
#define CTX _context.huffmanTree
		if OF_LIKELY (CTX.value == 0xFE) {
			if OF_LIKELY (CTX.litLenCodesCount == 0xFF) {
				if OF_UNLIKELY (!tryReadBits(self, &bits, 5))
					return bytesWritten;

				if OF_UNLIKELY (bits > 29)
					@throw [OFInvalidFormatException
					    exception];

				CTX.litLenCodesCount = bits;
			}

			if OF_LIKELY (CTX.distCodesCount == 0xFF) {
				if OF_UNLIKELY (!tryReadBits(self, &bits, 5))
					return bytesWritten;

				CTX.distCodesCount = bits;
			}

			if OF_LIKELY (CTX.codeLenCodesCount == 0xFF) {
				if OF_UNLIKELY (!tryReadBits(self, &bits, 4))
					return bytesWritten;

				CTX.codeLenCodesCount = bits;
			}

			if OF_LIKELY (CTX.lengths == NULL)
				CTX.lengths = OFAllocZeroedMemory(19, 1);

			for (uint16_t i = CTX.receivedCount;
			    i < CTX.codeLenCodesCount + 4; i++) {
				if OF_UNLIKELY (!tryReadBits(self, &bits, 3)) {
					CTX.receivedCount = i;
					return bytesWritten;
				}

				CTX.lengths[codeLengthsOrder[i]] = bits;
			}

			CTX.codeLenTree = OFHuffmanTreeNew(CTX.lengths, 19);
			CTX.treeIter = CTX.codeLenTree;

			OFFreeMemory(CTX.lengths);
			CTX.lengths = NULL;
			CTX.receivedCount = 0;
			CTX.value = 0xFF;
		}

		if OF_LIKELY (CTX.lengths == NULL)
			CTX.lengths = OFAllocMemory(
			    CTX.litLenCodesCount + CTX.distCodesCount + 258, 1);

		for (uint16_t i = CTX.receivedCount;
		    i < CTX.litLenCodesCount + CTX.distCodesCount + 258;) {
			uint8_t j, count;

			if OF_LIKELY (CTX.value == 0xFF) {
				if OF_UNLIKELY (!OFHuffmanTreeWalk(self,
				    tryReadBits, &CTX.treeIter, &value)) {
					CTX.receivedCount = i;
					return bytesWritten;
				}

				CTX.treeIter = CTX.codeLenTree;

				if (value < 16) {
					CTX.lengths[i++] = value;
					continue;
				}
			} else
				value = CTX.value;

			switch (value) {
			case 16:
				if OF_UNLIKELY (i < 1)
					@throw [OFInvalidFormatException
					    exception];

				if OF_UNLIKELY (!tryReadBits(self, &bits, 2)) {
					CTX.receivedCount = i;
					CTX.value = value;
					return bytesWritten;
				}

				value = CTX.lengths[i - 1];
				count = bits + 3;

				break;
			case 17:
				if OF_UNLIKELY (!tryReadBits(self, &bits, 3)) {
					CTX.receivedCount = i;
					CTX.value = value;
					return bytesWritten;
				}

				value = 0;
				count = bits + 3;

				break;
			case 18:
				if OF_UNLIKELY (!tryReadBits(self, &bits, 7)) {
					CTX.receivedCount = i;
					CTX.value = value;
					return bytesWritten;
				}

				value = 0;
				count = bits + 11;

				break;
			default:
				@throw [OFInvalidFormatException exception];
			}

			if OF_UNLIKELY (i + count >
			    CTX.litLenCodesCount + CTX.distCodesCount + 258)
				@throw [OFInvalidFormatException exception];

			for (j = 0; j < count; j++)
				CTX.lengths[i++] = value;

			CTX.value = 0xFF;
		}

		OFHuffmanTreeFree(CTX.codeLenTree);
		CTX.codeLenTree = NULL;

		CTX.litLenTree = OFHuffmanTreeNew(CTX.lengths,
		    CTX.litLenCodesCount + 257);
		CTX.distTree = OFHuffmanTreeNew(
		    CTX.lengths + CTX.litLenCodesCount + 257,
		    CTX.distCodesCount + 1);

		OFFreeMemory(CTX.lengths);

		/*
		 * litLenTree and distTree are at the same location in
		 * _context.huffman and _context.huffmanTree, thus no need to
		 * set them.
		 */
		_state = stateHuffmanBlock;
		_context.huffman.state = huffmanStateAwaitCode;
		_context.huffman.treeIter = CTX.litLenTree;

		goto start;
#undef CTX
	case stateHuffmanBlock:
#define CTX _context.huffman
		for (;;) {
			uint8_t extraBits, lengthCodeIndex;

			if OF_UNLIKELY (CTX.state == huffmanStateWriteValue) {
				if OF_UNLIKELY (length == 0)
					return bytesWritten;

				buffer[bytesWritten++] = CTX.value;
				length--;

				_slidingWindow[_slidingWindowIndex] = CTX.value;
				_slidingWindowIndex =
				    (_slidingWindowIndex + 1) &
				    _slidingWindowMask;

				CTX.state = huffmanStateAwaitCode;
				CTX.treeIter = CTX.litLenTree;
			}

			if OF_UNLIKELY (CTX.state ==
			    huffmanStateAwaitLengthExtraBits) {
				if OF_UNLIKELY (!tryReadBits(self, &bits,
				    CTX.extraBits))
					return bytesWritten;

				CTX.length += bits;

				CTX.state = huffmanStateAwaitDistance;
				CTX.treeIter = CTX.distTree;
			}

			/* Distance of length distance pair */
			if (CTX.state == huffmanStateAwaitDistance) {
				if OF_UNLIKELY (!OFHuffmanTreeWalk(self,
				    tryReadBits, &CTX.treeIter, &value))
					return bytesWritten;

				if OF_UNLIKELY (value >= numDistanceCodes)
					@throw [OFInvalidFormatException
					    exception];

				CTX.distance = distanceCodes[value];
				extraBits = distanceExtraBits[value];

				if (extraBits > 0) {
					if OF_UNLIKELY (!tryReadBits(self,
					    &bits, extraBits)) {
#define HSADEB huffmanStateAwaitDistanceExtraBits
						CTX.state = HSADEB;
#undef HSADEB
						CTX.extraBits = extraBits;
						return bytesWritten;
					}

					CTX.distance += bits;
				}

				CTX.state = huffmanStateProcessPair;
			} else if (CTX.state ==
			    huffmanStateAwaitDistanceExtraBits) {
				if OF_UNLIKELY (!tryReadBits(self, &bits,
				    CTX.extraBits))
					return bytesWritten;

				CTX.distance += bits;

				CTX.state = huffmanStateProcessPair;
			}

			/* Length distance pair */
			if (CTX.state == huffmanStateProcessPair) {
				for (uint_fast16_t j = 0; j < CTX.length; j++) {
					uint16_t idx;

					if OF_UNLIKELY (length == 0) {
						CTX.length -= j;
						return bytesWritten;
					}

					idx = (_slidingWindowIndex -
					    CTX.distance) & _slidingWindowMask;
					value = _slidingWindow[idx];

					buffer[bytesWritten++] = value;
					length--;

					_slidingWindow[_slidingWindowIndex] =
					    value;
					_slidingWindowIndex =
					    (_slidingWindowIndex + 1) &
					    _slidingWindowMask;
				}

				CTX.state = huffmanStateAwaitCode;
				CTX.treeIter = CTX.litLenTree;
			}

			if OF_UNLIKELY (!OFHuffmanTreeWalk(self, tryReadBits,
			    &CTX.treeIter, &value))
				return bytesWritten;

			/* End of block */
			if OF_UNLIKELY (value == 256) {
				if (CTX.litLenTree != fixedLitLenTree)
					OFHuffmanTreeFree(CTX.litLenTree);
				if (CTX.distTree != fixedDistTree)
					OFHuffmanTreeFree(CTX.distTree);

				_state = stateBlockHeader;
				goto start;
			}

			/* Literal byte */
			if OF_LIKELY (value < 256) {
				if OF_UNLIKELY (length == 0) {
					CTX.state = huffmanStateWriteValue;
					CTX.value = value;
					return bytesWritten;
				}

				buffer[bytesWritten++] = value;
				length--;

				_slidingWindow[_slidingWindowIndex] = value;
				_slidingWindowIndex =
				    (_slidingWindowIndex + 1) &
				    _slidingWindowMask;

				CTX.treeIter = CTX.litLenTree;
				continue;
			}

			if OF_UNLIKELY (value > 285)
				@throw [OFInvalidFormatException exception];

			/* Length of length distance pair */
			lengthCodeIndex = value - 257;
			CTX.length = lengthCodes[lengthCodeIndex] + 3;
			extraBits = lengthExtraBits[lengthCodeIndex];

			if (extraBits > 0) {
				if OF_UNLIKELY (!tryReadBits(self, &bits,
				    extraBits)) {
					CTX.extraBits = extraBits;
					CTX.state =
					    huffmanStateAwaitLengthExtraBits;
					return bytesWritten;
				}

				CTX.length += bits;
			}

			CTX.treeIter = CTX.distTree;
			CTX.state = huffmanStateAwaitDistance;
		}

		break;
#undef CTX
	}

	OF_UNREACHABLE
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	return _atEndOfStream;
}

- (int)fileDescriptorForReading
{
	return ((id <OFReadyForReadingObserving>)_stream)
	    .fileDescriptorForReading;
}

- (bool)lowlevelHasDataInReadBuffer
{
	return (_stream.hasDataInReadBuffer ||
	    _bufferLength - _bufferIndex > 0);
}

- (void)close
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	/* Give back our buffer to the stream, in case it's shared */
	[_stream unreadFromBuffer: _buffer + _bufferIndex
			   length: _bufferLength - _bufferIndex];
	_bufferIndex = _bufferLength = 0;

	[_stream release];
	_stream = nil;

	[super close];
}
@end
