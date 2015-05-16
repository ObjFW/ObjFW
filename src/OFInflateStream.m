/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
 *   Jonathan Schleifer <js@webkeks.org>
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

#define OF_INFLATE_STREAM_M

#include "config.h"

#include <stdlib.h>
#include <string.h>

#include <assert.h>

#ifndef DEFLATE64
# import "OFInflateStream.h"
#else
# import "OFInflate64Stream.h"
# define OFInflateStream OFInflate64Stream
#endif
#import "OFDataArray.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"
#import "OFReadFailedException.h"

#define BLOCK_HEADER		  OF_INFLATE_STREAM_BLOCK_HEADER
#define UNCOMPRESSED_BLOCK_HEADER OF_INFLATE_STREAM_UNCOMPRESSED_BLOCK_HEADER
#define UNCOMPRESSED_BLOCK	  OF_INFLATE_STREAM_UNCOMPRESSED_BLOCK
#define HUFFMAN_BLOCK		  OF_INFLATE_STREAM_HUFFMAN_BLOCK
#define HUFFMAN_TREE		  OF_INFLATE_STREAM_HUFFMAN_TREE
#define CONSTRUCT_CODELEN_TREE	  OF_INFLATE_STREAM_CONSTRUCT_CODELEN_TREE
#define CONSTRUCT_LITLEN_TREE	  OF_INFLATE_STREAM_CONSTRUCT_LITLEN_TREE
#define CONSTRUCT_DIST_TREE	  OF_INFLATE_STREAM_CONSTRUCT_DIST_TREE
#define AWAIT_CODE		  OF_INFLATE_STREAM_AWAIT_CODE
#define WRITE_VALUE		  OF_INFLATE_STREAM_WRITE_VALUE
#define AWAIT_LENGTH_EXTRA_BITS   OF_INFLATE_STREAM_AWAIT_LENGTH_EXTRA_BITS
#define AWAIT_DISTANCE		  OF_INFLATE_STREAM_AWAIT_DISTANCE
#define AWAIT_DISTANCE_EXTRA_BITS OF_INFLATE_STREAM_AWAIT_DISTANCE_EXTRA_BITS
#define PROCESS_PAIR		  OF_INFLATE_STREAM_PROCESS_PAIR
#define BUFFER_SIZE		  OF_INFLATE_STREAM_BUFFER_SIZE

#define MAX_BITS 15

struct huffman_tree {
	struct huffman_tree *leafs[2];
	uint16_t value;
};

#ifndef DEFLATE64
static const uint_fast8_t numDistanceCodes = 30;
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
static const uint_fast8_t numDistanceCodes = 32;
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
static struct huffman_tree *fixedLitLenTree, *fixedDistTree;

static bool
tryReadBits(OFInflateStream *stream, uint_fast16_t *bits, uint_fast8_t count)
{
	uint_fast16_t ret = stream->_savedBits;
	uint_fast8_t i;

	assert(stream->_savedBitsLength < count);

	for (i = stream->_savedBitsLength; i < count; i++) {
		if OF_UNLIKELY (stream->_bitIndex == 8) {
			if (stream->_bufferIndex < stream->_bufferLength)
				stream->_byte =
				    stream->_buffer[stream->_bufferIndex++];
			else {
				size_t length = [stream->_stream
				    readIntoBuffer: stream->_buffer
					    length: BUFFER_SIZE];

				if OF_UNLIKELY (length < 1) {
					stream->_savedBits = ret;
					stream->_savedBitsLength = i;
					return false;
				}

				stream->_byte = stream->_buffer[0];
				stream->_bufferIndex = 1;
				stream->_bufferLength = (uint_fast16_t)length;
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

static struct huffman_tree*
newTree(void)
{
	struct huffman_tree *tree;

	if ((tree = malloc(sizeof(*tree))) == NULL)
		@throw [OFOutOfMemoryException
		    exceptionWithRequestedSize: sizeof(*tree)];

	tree->leafs[0] = tree->leafs[1] = NULL;
	tree->value = 0xFFFF;

	return tree;
}

static void
treeInsert(struct huffman_tree *tree, uint_fast16_t code, uint_fast8_t length,
    uint16_t value)
{
	while (length > 0) {
		uint_fast8_t bit;

		length--;
		bit = (code & (1 << length)) >> length;

		if (tree->leafs[bit] == NULL)
			tree->leafs[bit] = newTree();

		tree = tree->leafs[bit];
	}

	tree->value = value;
}

static struct huffman_tree*
constructTree(uint8_t lengths[], uint_fast16_t count)
{
	struct huffman_tree *tree;
	uint16_t lengthCount[MAX_BITS + 1] = { 0 };
	uint16_t code, maxCode = 0, nextCode[MAX_BITS + 1];
	uint_fast16_t i;

	for (i = 0; i < count; i++) {
		uint8_t length = lengths[i];

		if OF_UNLIKELY (length > MAX_BITS)
			@throw [OFInvalidFormatException exception];

		if (length > 0) {
			lengthCount[length]++;
			maxCode = i;
		}
	}

	code = 0;
	for (i = 1; i <= MAX_BITS; i++) {
		code = (code + lengthCount[i - 1]) << 1;
		nextCode[i] = code;
	}

	tree = newTree();

	for (i = 0; i <= maxCode; i++) {
		uint8_t length = lengths[i];

		if (length > 0)
			treeInsert(tree, nextCode[length]++, length, i);
	}

	return tree;
}

static bool
walkTree(OFInflateStream *stream, struct huffman_tree **tree, uint16_t *value)
{
	struct huffman_tree *iter = *tree;
	uint_fast16_t bits;

	while (iter->value == 0xFFFF) {
		if OF_UNLIKELY (!tryReadBits(stream, &bits, 1)) {
			*tree = iter;
			return false;
		}

		if OF_UNLIKELY (iter->leafs[bits] == NULL)
			@throw [OFInvalidFormatException exception];

		iter = iter->leafs[bits];
	}

	*value = iter->value;
	return true;
}

static void
releaseTree(struct huffman_tree *tree)
{
	uint_fast8_t i;

	for (i = 0; i < 2; i++)
		if OF_LIKELY (tree->leafs[i] != NULL)
			releaseTree(tree->leafs[i]);

	free(tree);
}

@implementation OFInflateStream
+ (void)initialize
{
	uint_fast16_t i;
	uint8_t lengths[288];

	if (self != [OFInflateStream class])
		return;

	for (i = 0; i <= 143; i++)
		lengths[i] = 8;
	for (i = 144; i <= 255; i++)
		lengths[i] = 9;
	for (i = 256; i <= 279; i++)
		lengths[i] = 7;
	for (i = 280; i <= 287; i++)
		lengths[i] = 8;

	fixedLitLenTree = constructTree(lengths, 288);

	for (i = 0; i <= 31; i++)
		lengths[i] = 5;

	fixedDistTree = constructTree(lengths, 32);
}

#ifndef DEFLATE64
+ (instancetype)streamWithStream: (OFStream*)stream
{
	return [[[self alloc] initWithStream: stream] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithStream: (OFStream*)stream
{
	self = [super init];

	_stream = [stream retain];
	_bitIndex = 8;	/* 0-7 address the bit, 8 means fetch next byte */
	_slidingWindowMask = 0x7FFF;

	return self;
}

- (void)dealloc
{
	[_stream release];

	[super dealloc];
}
#endif

- (size_t)lowlevelReadIntoBuffer: (void*)buffer_
			  length: (size_t)length
{
	uint8_t *buffer = buffer_;
	uint_fast16_t bits, i, tmp;
	uint16_t value;
	size_t bytesWritten = 0;
	uint8_t *slidingWindow;
	uint_fast16_t slidingWindowIndex;

	if (_atEndOfStream)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length];

start:
	switch (_state) {
	case BLOCK_HEADER:
		if OF_UNLIKELY (_inLastBlock) {
			[_stream unreadFromBuffer: _buffer + _bufferIndex
					   length: _bufferLength -
						   _bufferIndex];

			_atEndOfStream = true;
			return bytesWritten;
		}

		if OF_UNLIKELY (!tryReadBits(self, &bits, 3))
			return bytesWritten;

		_inLastBlock = (bits & 1);

		switch (bits >> 1) {
		case 0: /* No compression */
			_state = UNCOMPRESSED_BLOCK_HEADER;
			_bitIndex = 8;
			_context.uncompressedHeader.position = 0;
			memset(_context.uncompressedHeader.length, 0, 4);
			break;
		case 1: /* Fixed Huffman */
			_state = HUFFMAN_BLOCK;
			_context.huffman.state = AWAIT_CODE;
			_context.huffman.litLenTree = fixedLitLenTree;
			_context.huffman.distTree = fixedDistTree;
			_context.huffman.treeIter = fixedLitLenTree;
			break;
		case 2: /* Dynamic Huffman */
			_state = HUFFMAN_TREE;
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
	case UNCOMPRESSED_BLOCK_HEADER:
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

		_state = UNCOMPRESSED_BLOCK;

		/*
		 * Do not reorder! _context.uncompressed.position and
		 * _context.uncompressedHeader.length overlap!
		 */
		_context.uncompressed.length =
		    CTX.length[0] | (CTX.length[1] << 8);
		_context.uncompressed.position = 0;

		goto start;
#undef CTX
	case UNCOMPRESSED_BLOCK:
#define CTX _context.uncompressed
		if OF_UNLIKELY (length == 0)
			return bytesWritten;

		tmp = (length < CTX.length - CTX.position
		    ? (uint_fast16_t)length : CTX.length - CTX.position);

		tmp = (uint_fast16_t)[_stream
		    readIntoBuffer: buffer + bytesWritten
			    length: tmp];

		if OF_UNLIKELY (_slidingWindow == NULL) {
			_slidingWindow =
			    [self allocMemoryWithSize: _slidingWindowMask + 1];
			/* Avoid leaking data */
			memset(_slidingWindow, 0, _slidingWindowMask + 1);
		}

		slidingWindow = _slidingWindow;
		slidingWindowIndex = _slidingWindowIndex;
		for (i = 0; i < tmp; i++) {
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
			_state = BLOCK_HEADER;

		goto start;
#undef CTX
	case HUFFMAN_TREE:
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

			if OF_LIKELY (CTX.lengths == NULL) {
				CTX.lengths = [self allocMemoryWithSize: 19];
				memset(CTX.lengths, 0, 19);
			}

			for (i = CTX.receivedCount;
			    i < CTX.codeLenCodesCount + 4; i++) {
				if OF_UNLIKELY (!tryReadBits(self, &bits, 3)) {
					CTX.receivedCount = i;
					return bytesWritten;
				}

				CTX.lengths[codeLengthsOrder[i]] = bits;
			}

			CTX.codeLenTree = constructTree(CTX.lengths, 19);
			CTX.treeIter = CTX.codeLenTree;

			[self freeMemory: CTX.lengths];
			CTX.lengths = NULL;
			CTX.receivedCount = 0;
			CTX.value = 0xFF;
		}

		if OF_LIKELY (CTX.lengths == NULL)
			CTX.lengths = [self allocMemoryWithSize:
			    CTX.litLenCodesCount + CTX.distCodesCount + 258];

		for (i = CTX.receivedCount;
		    i < CTX.litLenCodesCount + CTX.distCodesCount + 258;) {
			uint_fast8_t j, count;

			if OF_LIKELY (CTX.value == 0xFF) {
				if OF_UNLIKELY (!walkTree(self, &CTX.treeIter,
				    &value)) {
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

		releaseTree(CTX.codeLenTree);

		CTX.litLenTree = constructTree(CTX.lengths,
		    CTX.litLenCodesCount + 257);
		CTX.distTree = constructTree(
		    CTX.lengths + CTX.litLenCodesCount + 257,
		    CTX.distCodesCount + 1);

		[self freeMemory: CTX.lengths];

		/*
		 * litLenTree and distTree are at the same location in
		 * _context.huffman and _context.huffmanTree, thus no need to
		 * set them.
		 */
		_state = HUFFMAN_BLOCK;
		_context.huffman.state = AWAIT_CODE;
		_context.huffman.treeIter = CTX.litLenTree;

		goto start;
#undef CTX
	case HUFFMAN_BLOCK:
#define CTX _context.huffman
		for (;;) {
			uint_fast8_t extraBits, lengthCodeIndex;

			if OF_UNLIKELY (CTX.state == WRITE_VALUE) {
				if OF_UNLIKELY (length == 0)
					return bytesWritten;

				buffer[bytesWritten++] = CTX.value;
				length--;

				if (_slidingWindow == NULL) {
					_slidingWindow = [self
					    allocMemoryWithSize:
					    _slidingWindowMask + 1];
					/* Avoid leaking data */
					memset(_slidingWindow, 0,
					    _slidingWindowMask + 1);
				}

				_slidingWindow[_slidingWindowIndex] = CTX.value;
				_slidingWindowIndex =
				    (_slidingWindowIndex + 1) &
				    _slidingWindowMask;

				CTX.state = AWAIT_CODE;
				CTX.treeIter = CTX.litLenTree;
			}

			if OF_UNLIKELY (CTX.state == AWAIT_LENGTH_EXTRA_BITS) {
				if OF_UNLIKELY (!tryReadBits(self, &bits,
				    CTX.extraBits))
					return bytesWritten;

				CTX.length += bits;

				CTX.state = AWAIT_DISTANCE;
				CTX.treeIter = CTX.distTree;
			}

			/* Distance of length distance pair */
			if (CTX.state == AWAIT_DISTANCE) {
				if OF_UNLIKELY (!walkTree(self, &CTX.treeIter,
				    &value))
					return bytesWritten;

				if OF_UNLIKELY (value >= numDistanceCodes)
					@throw [OFInvalidFormatException
					    exception];

				CTX.distance = distanceCodes[value];
				extraBits = distanceExtraBits[value];

				if (extraBits > 0) {
					if OF_UNLIKELY (!tryReadBits(self,
					    &bits, extraBits)) {
						CTX.state =
						    AWAIT_DISTANCE_EXTRA_BITS;
						CTX.extraBits = extraBits;
						return bytesWritten;
					}

					CTX.distance += bits;
				}

				CTX.state = PROCESS_PAIR;
			} else if (CTX.state == AWAIT_DISTANCE_EXTRA_BITS) {
				if OF_UNLIKELY (!tryReadBits(self, &bits,
				    CTX.extraBits))
					return bytesWritten;

				CTX.distance += bits;

				CTX.state = PROCESS_PAIR;
			}

			/* Length distance pair */
			if (CTX.state == PROCESS_PAIR) {
				uint_fast16_t j;

				if OF_UNLIKELY (_slidingWindow == NULL)
					@throw [OFInvalidFormatException
					    exception];

				for (j = 0; j < CTX.length; j++) {
					uint_fast16_t index;

					if OF_UNLIKELY (length == 0) {
						CTX.length -= j;
						return bytesWritten;
					}

					index = (_slidingWindowIndex -
					    CTX.distance) & _slidingWindowMask;
					value = _slidingWindow[index];

					buffer[bytesWritten++] = value;
					length--;

					_slidingWindow[_slidingWindowIndex] =
					    value;
					_slidingWindowIndex =
					    (_slidingWindowIndex + 1) &
					    _slidingWindowMask;
				}

				CTX.state = AWAIT_CODE;
				CTX.treeIter = CTX.litLenTree;
			}

			if OF_UNLIKELY (!walkTree(self, &CTX.treeIter, &value))
				return bytesWritten;

			/* End of block */
			if OF_UNLIKELY (value == 256) {
				if (CTX.litLenTree != fixedLitLenTree)
					releaseTree(CTX.litLenTree);
				if (CTX.distTree != fixedDistTree)
					releaseTree(CTX.distTree);

				_state = BLOCK_HEADER;
				goto start;
			}

			/* Literal byte */
			if (value < 256) {
				if OF_UNLIKELY (length == 0) {
					CTX.state = WRITE_VALUE;
					CTX.value = value;
					return bytesWritten;
				}

				buffer[bytesWritten++] = value;
				length--;

				if (_slidingWindow == NULL) {
					_slidingWindow = [self
					    allocMemoryWithSize:
					    _slidingWindowMask + 1];
					/* Avoid leaking data */
					memset(_slidingWindow, 0,
					    _slidingWindowMask + 1);
				}

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
					CTX.state = AWAIT_LENGTH_EXTRA_BITS;
					return bytesWritten;
				}

				CTX.length += bits;
			}

			CTX.treeIter = CTX.distTree;
			CTX.state = AWAIT_DISTANCE;
		}

		break;
#undef CTX
	}

	OF_UNREACHABLE
}

#ifndef DEFLATE64
- (bool)lowlevelIsAtEndOfStream
{
	return _atEndOfStream;
}

- (int)fileDescriptorForReading
{
	return [_stream fileDescriptorForReading];
}

- (bool)hasDataInReadBuffer
{
	return ([super hasDataInReadBuffer] || [_stream hasDataInReadBuffer]);
}
#endif
@end
