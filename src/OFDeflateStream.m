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

#define OF_INFLATE_STREAM_M

#include "config.h"

#include <stdlib.h>
#include <string.h>

#include <assert.h>

#ifndef DEFLATE64
# import "OFDeflateStream.h"
#else
# import "OFDeflate64Stream.h"
# define OFDeflateStream OFDeflate64Stream
#endif
#import "OFDataArray.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"
#import "OFReadFailedException.h"

#define BUFFER_SIZE		  OF_INFLATE_STREAM_BUFFER_SIZE

#define MAX_BITS 15

enum state {
	BLOCK_HEADER,
	UNCOMPRESSED_BLOCK_HEADER,
	UNCOMPRESSED_BLOCK,
	HUFFMAN_TREE,
	HUFFMAN_BLOCK
};

enum huffman_state {
	WRITE_VALUE,
	AWAIT_CODE,
	AWAIT_LENGTH_EXTRA_BITS,
	AWAIT_DISTANCE,
	AWAIT_DISTANCE_EXTRA_BITS,
	PROCESS_PAIR
};

struct huffman_tree {
	struct huffman_tree *leafs[2];
	uint16_t value;
};

@interface OFDeflateStream ()
- (void)OF_initDecompression;
@end

#ifndef DEFLATE64
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
static struct huffman_tree *fixedLitLenTree, *fixedDistTree;

static bool
tryReadBits(OFDeflateStream *stream,
    struct of_deflate_stream_decompression_ivars *ivars,
    uint16_t *bits, uint8_t count)
{
	uint16_t ret = ivars->savedBits;

	assert(ivars->savedBitsLength < count);

	for (uint8_t i = ivars->savedBitsLength; i < count; i++) {
		if OF_UNLIKELY (ivars->bitIndex == 8) {
			if (ivars->bufferIndex < ivars->bufferLength)
				ivars->byte =
				    ivars->buffer[ivars->bufferIndex++];
			else {
				size_t length = [stream->_stream
				    readIntoBuffer: ivars->buffer
					    length: BUFFER_SIZE];

				if OF_UNLIKELY (length < 1) {
					ivars->savedBits = ret;
					ivars->savedBitsLength = i;
					return false;
				}

				ivars->byte = ivars->buffer[0];
				ivars->bufferIndex = 1;
				ivars->bufferLength = (uint16_t)length;
			}

			ivars->bitIndex = 0;
		}

		ret |= ((ivars->byte >> ivars->bitIndex++) & 1) << i;
	}

	ivars->savedBits = 0;
	ivars->savedBitsLength = 0;
	*bits = ret;

	return true;
}

static struct huffman_tree *
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
treeInsert(struct huffman_tree *tree, uint16_t code, uint8_t length,
    uint16_t value)
{
	while (length > 0) {
		uint8_t bit;

		length--;
		bit = (code & (1 << length)) >> length;

		if (tree->leafs[bit] == NULL)
			tree->leafs[bit] = newTree();

		tree = tree->leafs[bit];
	}

	tree->value = value;
}

static struct huffman_tree *
constructTree(uint8_t lengths[], uint16_t count)
{
	struct huffman_tree *tree;
	uint16_t lengthCount[MAX_BITS + 1] = { 0 };
	uint16_t code, maxCode = 0, nextCode[MAX_BITS + 1];

	for (uint16_t i = 0; i < count; i++) {
		uint8_t length = lengths[i];

		if OF_UNLIKELY (length > MAX_BITS)
			@throw [OFInvalidFormatException exception];

		if (length > 0) {
			lengthCount[length]++;
			maxCode = i;
		}
	}

	code = 0;
	for (size_t i = 1; i <= MAX_BITS; i++) {
		code = (code + lengthCount[i - 1]) << 1;
		nextCode[i] = code;
	}

	tree = newTree();

	for (uint16_t i = 0; i <= maxCode; i++) {
		uint8_t length = lengths[i];

		if (length > 0)
			treeInsert(tree, nextCode[length]++, length, i);
	}

	return tree;
}

static bool
walkTree(OFDeflateStream *stream,
    struct of_deflate_stream_decompression_ivars *ivars,
    struct huffman_tree **tree, uint16_t *value)
{
	struct huffman_tree *iter = *tree;
	uint16_t bits;

	while (iter->value == 0xFFFF) {
		if OF_UNLIKELY (!tryReadBits(stream, ivars, &bits, 1)) {
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
	for (uint8_t i = 0; i < 2; i++)
		if OF_LIKELY (tree->leafs[i] != NULL)
			releaseTree(tree->leafs[i]);

	free(tree);
}

@implementation OFDeflateStream
+ (void)initialize
{
	uint8_t lengths[288];

	if (self != [OFDeflateStream class])
		return;

	for (uint16_t i = 0; i <= 143; i++)
		lengths[i] = 8;
	for (uint16_t i = 144; i <= 255; i++)
		lengths[i] = 9;
	for (uint16_t i = 256; i <= 279; i++)
		lengths[i] = 7;
	for (uint16_t i = 280; i <= 287; i++)
		lengths[i] = 8;

	fixedLitLenTree = constructTree(lengths, 288);

	for (uint16_t i = 0; i <= 31; i++)
		lengths[i] = 5;

	fixedDistTree = constructTree(lengths, 32);
}

#ifndef DEFLATE64
+ (instancetype)streamWithStream: (OFStream *)stream
{
	return [[[self alloc] initWithStream: stream] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithStream: (OFStream *)stream
{
	self = [super init];

	_stream = [stream retain];

	return self;
}

- (void)dealloc
{
	[_stream release];

	if (_decompression != NULL && _decompression->state == HUFFMAN_TREE)
		if (_decompression->context.huffmanTree.codeLenTree != NULL)
			releaseTree(
			    _decompression->context.huffmanTree.codeLenTree);

	if (_decompression != NULL && (_decompression->state == HUFFMAN_TREE ||
	    _decompression->state == HUFFMAN_BLOCK)) {
		if (_decompression->context.huffman.litLenTree !=
		    fixedLitLenTree)
			releaseTree(_decompression->context.huffman.litLenTree);
		if (_decompression->context.huffman.distTree != fixedDistTree)
			releaseTree(_decompression->context.huffman.distTree);
	}

	[super dealloc];
}
#endif

- (void)OF_initDecompression
{
	_decompression = [self allocMemoryWithSize: sizeof(*_decompression)];
	memset(_decompression, 0, sizeof(*_decompression));

	/* 0-7 address the bit, 8 means fetch next byte */
	_decompression->bitIndex = 8;
#ifdef DEFLATE64
	_decompression->slidingWindowMask = 0xFFFF;
#else
	_decompression->slidingWindowMask = 0x7FFF;
#endif
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer_
			  length: (size_t)length
{
	struct of_deflate_stream_decompression_ivars *ivars = _decompression;
	uint8_t *buffer = buffer_;
	uint16_t bits, tmp;
	uint16_t value;
	size_t bytesWritten = 0;
	uint8_t *slidingWindow;
	uint16_t slidingWindowIndex;

	if (ivars == NULL) {
		[self OF_initDecompression];
		ivars = _decompression;
	}

	if (ivars->atEndOfStream)
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length];

start:
	switch ((enum state)ivars->state) {
	case BLOCK_HEADER:
		if OF_UNLIKELY (ivars->inLastBlock) {
			[_stream unreadFromBuffer: ivars->buffer +
						   ivars->bufferIndex
					   length: ivars->bufferLength -
						   ivars->bufferIndex];

			ivars->atEndOfStream = true;
			return bytesWritten;
		}

		if OF_UNLIKELY (!tryReadBits(self, ivars, &bits, 3))
			return bytesWritten;

		ivars->inLastBlock = (bits & 1);

		switch (bits >> 1) {
		case 0: /* No compression */
			ivars->state = UNCOMPRESSED_BLOCK_HEADER;
			ivars->bitIndex = 8;
			ivars->context.uncompressedHeader.position = 0;
			memset(ivars->context.uncompressedHeader.length, 0, 4);
			break;
		case 1: /* Fixed Huffman */
			ivars->state = HUFFMAN_BLOCK;
			ivars->context.huffman.state = AWAIT_CODE;
			ivars->context.huffman.litLenTree = fixedLitLenTree;
			ivars->context.huffman.distTree = fixedDistTree;
			ivars->context.huffman.treeIter = fixedLitLenTree;
			break;
		case 2: /* Dynamic Huffman */
			ivars->state = HUFFMAN_TREE;
			ivars->context.huffmanTree.lengths = NULL;
			ivars->context.huffmanTree.receivedCount = 0;
			ivars->context.huffmanTree.value = 0xFE;
			ivars->context.huffmanTree.litLenCodesCount = 0xFF;
			ivars->context.huffmanTree.distCodesCount = 0xFF;
			ivars->context.huffmanTree.codeLenCodesCount = 0xFF;
			break;
		default:
			@throw [OFInvalidFormatException exception];
		}

		goto start;
	case UNCOMPRESSED_BLOCK_HEADER:
#define CTX ivars->context.uncompressedHeader
		/* FIXME: This can be done more efficiently than unreading */
		[_stream unreadFromBuffer: ivars->buffer + ivars->bufferIndex
				   length: ivars->bufferLength -
					   ivars->bufferIndex];
		ivars->bufferIndex = ivars->bufferLength = 0;

		CTX.position += [_stream
		    readIntoBuffer: CTX.length + CTX.position
			    length: 4 - CTX.position];

		if OF_UNLIKELY (CTX.position < 4)
			return bytesWritten;

		if OF_UNLIKELY ((CTX.length[0] | (CTX.length[1] << 8)) !=
		    (uint16_t)~(CTX.length[2] | (CTX.length[3] << 8)))
			@throw [OFInvalidFormatException exception];

		ivars->state = UNCOMPRESSED_BLOCK;

		/*
		 * Do not reorder! ivars->context.uncompressed.position and
		 * ivars->context.uncompressedHeader.length overlap!
		 */
		ivars->context.uncompressed.length =
		    CTX.length[0] | (CTX.length[1] << 8);
		ivars->context.uncompressed.position = 0;

		goto start;
#undef CTX
	case UNCOMPRESSED_BLOCK:
#define CTX ivars->context.uncompressed
		if OF_UNLIKELY (length == 0)
			return bytesWritten;

		tmp = (length < (size_t)CTX.length - CTX.position
		    ? (uint16_t)length : CTX.length - CTX.position);

		tmp = (uint16_t)[_stream readIntoBuffer: buffer + bytesWritten
						 length: tmp];

		if OF_UNLIKELY (ivars->slidingWindow == NULL) {
			ivars->slidingWindow = [self allocMemoryWithSize:
			    ivars->slidingWindowMask + 1];
			/* Avoid leaking data */
			memset(ivars->slidingWindow, 0,
			    ivars->slidingWindowMask + 1);
		}

		slidingWindow = ivars->slidingWindow;
		slidingWindowIndex = ivars->slidingWindowIndex;
		for (uint16_t i = 0; i < tmp; i++) {
			slidingWindow[slidingWindowIndex] =
			    buffer[bytesWritten + i];
			slidingWindowIndex = (slidingWindowIndex + 1) &
			    ivars->slidingWindowMask;
		}
		ivars->slidingWindowIndex = slidingWindowIndex;

		length -= tmp;
		bytesWritten += tmp;

		CTX.position += tmp;
		if OF_UNLIKELY (CTX.position == CTX.length)
			ivars->state = BLOCK_HEADER;

		goto start;
#undef CTX
	case HUFFMAN_TREE:
#define CTX ivars->context.huffmanTree
		if OF_LIKELY (CTX.value == 0xFE) {
			if OF_LIKELY (CTX.litLenCodesCount == 0xFF) {
				if OF_UNLIKELY (!tryReadBits(self, ivars,
				    &bits, 5))
					return bytesWritten;

				if OF_UNLIKELY (bits > 29)
					@throw [OFInvalidFormatException
					    exception];

				CTX.litLenCodesCount = bits;
			}

			if OF_LIKELY (CTX.distCodesCount == 0xFF) {
				if OF_UNLIKELY (!tryReadBits(self, ivars,
				    &bits, 5))
					return bytesWritten;

				CTX.distCodesCount = bits;
			}

			if OF_LIKELY (CTX.codeLenCodesCount == 0xFF) {
				if OF_UNLIKELY (!tryReadBits(self, ivars,
				    &bits, 4))
					return bytesWritten;

				CTX.codeLenCodesCount = bits;
			}

			if OF_LIKELY (CTX.lengths == NULL) {
				CTX.lengths = [self allocMemoryWithSize: 19];
				memset(CTX.lengths, 0, 19);
			}

			for (uint16_t i = CTX.receivedCount;
			    i < CTX.codeLenCodesCount + 4; i++) {
				if OF_UNLIKELY (!tryReadBits(self, ivars,
				    &bits, 3)) {
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

		for (uint16_t i = CTX.receivedCount;
		    i < CTX.litLenCodesCount + CTX.distCodesCount + 258;) {
			uint8_t j, count;

			if OF_LIKELY (CTX.value == 0xFF) {
				if OF_UNLIKELY (!walkTree(self, ivars,
				    &CTX.treeIter, &value)) {
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

				if OF_UNLIKELY (!tryReadBits(self, ivars,
				    &bits, 2)) {
					CTX.receivedCount = i;
					CTX.value = value;
					return bytesWritten;
				}

				value = CTX.lengths[i - 1];
				count = bits + 3;

				break;
			case 17:
				if OF_UNLIKELY (!tryReadBits(self, ivars,
				    &bits, 3)) {
					CTX.receivedCount = i;
					CTX.value = value;
					return bytesWritten;
				}

				value = 0;
				count = bits + 3;

				break;
			case 18:
				if OF_UNLIKELY (!tryReadBits(self, ivars,
				    &bits, 7)) {
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
		CTX.codeLenTree = NULL;

		CTX.litLenTree = constructTree(CTX.lengths,
		    CTX.litLenCodesCount + 257);
		CTX.distTree = constructTree(
		    CTX.lengths + CTX.litLenCodesCount + 257,
		    CTX.distCodesCount + 1);

		[self freeMemory: CTX.lengths];

		/*
		 * litLenTree and distTree are at the same location in
		 * ivars->context.huffman and ivars->context.huffmanTree, thus
		 * no need to set them.
		 */
		ivars->state = HUFFMAN_BLOCK;
		ivars->context.huffman.state = AWAIT_CODE;
		ivars->context.huffman.treeIter = CTX.litLenTree;

		goto start;
#undef CTX
	case HUFFMAN_BLOCK:
#define CTX ivars->context.huffman
		for (;;) {
			uint8_t extraBits, lengthCodeIndex;

			if OF_UNLIKELY (CTX.state == WRITE_VALUE) {
				if OF_UNLIKELY (length == 0)
					return bytesWritten;

				buffer[bytesWritten++] = CTX.value;
				length--;

				if (ivars->slidingWindow == NULL) {
					ivars->slidingWindow = [self
					    allocMemoryWithSize:
					    ivars->slidingWindowMask + 1];
					/* Avoid leaking data */
					memset(ivars->slidingWindow, 0,
					    ivars->slidingWindowMask + 1);
				}

				ivars->slidingWindow[
				    ivars->slidingWindowIndex] = CTX.value;
				ivars->slidingWindowIndex =
				    (ivars->slidingWindowIndex + 1) &
				    ivars->slidingWindowMask;

				CTX.state = AWAIT_CODE;
				CTX.treeIter = CTX.litLenTree;
			}

			if OF_UNLIKELY (CTX.state == AWAIT_LENGTH_EXTRA_BITS) {
				if OF_UNLIKELY (!tryReadBits(self, ivars,
				    &bits, CTX.extraBits))
					return bytesWritten;

				CTX.length += bits;

				CTX.state = AWAIT_DISTANCE;
				CTX.treeIter = CTX.distTree;
			}

			/* Distance of length distance pair */
			if (CTX.state == AWAIT_DISTANCE) {
				if OF_UNLIKELY (!walkTree(self, ivars,
				    &CTX.treeIter, &value))
					return bytesWritten;

				if OF_UNLIKELY (value >= numDistanceCodes)
					@throw [OFInvalidFormatException
					    exception];

				CTX.distance = distanceCodes[value];
				extraBits = distanceExtraBits[value];

				if (extraBits > 0) {
					if OF_UNLIKELY (!tryReadBits(self,
					    ivars, &bits, extraBits)) {
						CTX.state =
						    AWAIT_DISTANCE_EXTRA_BITS;
						CTX.extraBits = extraBits;
						return bytesWritten;
					}

					CTX.distance += bits;
				}

				CTX.state = PROCESS_PAIR;
			} else if (CTX.state == AWAIT_DISTANCE_EXTRA_BITS) {
				if OF_UNLIKELY (!tryReadBits(self, ivars,
				    &bits, CTX.extraBits))
					return bytesWritten;

				CTX.distance += bits;

				CTX.state = PROCESS_PAIR;
			}

			/* Length distance pair */
			if (CTX.state == PROCESS_PAIR) {
				uint16_t j;

				if OF_UNLIKELY (ivars->slidingWindow == NULL)
					@throw [OFInvalidFormatException
					    exception];

				for (j = 0; j < CTX.length; j++) {
					uint16_t index;

					if OF_UNLIKELY (length == 0) {
						CTX.length -= j;
						return bytesWritten;
					}

					index = (ivars->slidingWindowIndex -
					    CTX.distance) &
					    ivars->slidingWindowMask;
					value = ivars->slidingWindow[index];

					buffer[bytesWritten++] = value;
					length--;

					ivars->slidingWindow[
					    ivars->slidingWindowIndex] = value;
					ivars->slidingWindowIndex =
					    (ivars->slidingWindowIndex + 1) &
					    ivars->slidingWindowMask;
				}

				CTX.state = AWAIT_CODE;
				CTX.treeIter = CTX.litLenTree;
			}

			if OF_UNLIKELY (!walkTree(self, ivars,
			    &CTX.treeIter, &value))
				return bytesWritten;

			/* End of block */
			if OF_UNLIKELY (value == 256) {
				if (CTX.litLenTree != fixedLitLenTree)
					releaseTree(CTX.litLenTree);
				if (CTX.distTree != fixedDistTree)
					releaseTree(CTX.distTree);

				ivars->state = BLOCK_HEADER;
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

				if (ivars->slidingWindow == NULL) {
					ivars->slidingWindow = [self
					    allocMemoryWithSize:
					    ivars->slidingWindowMask + 1];
					/* Avoid leaking data */
					memset(ivars->slidingWindow, 0,
					    ivars->slidingWindowMask + 1);
				}

				ivars->slidingWindow[
				    ivars->slidingWindowIndex] = value;
				ivars->slidingWindowIndex =
				    (ivars->slidingWindowIndex + 1) &
				    ivars->slidingWindowMask;

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
				if OF_UNLIKELY (!tryReadBits(self, ivars,
				    &bits, extraBits)) {
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
	if (_decompression == NULL)
		return false;

	return _decompression->atEndOfStream;
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
