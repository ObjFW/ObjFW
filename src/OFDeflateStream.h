/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
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

#import "OFStream.h"

#define OF_DEFLATE_STREAM_BUFFER_SIZE 4096

/*!
 * @class OFDeflateStream OFDeflateStream.h ObjFW/OFDeflateStream.h
 *
 * @brief A class for a stream that handles Deflate compression or decompression
 *	  transparently for an underlying stream.
 */
@interface OFDeflateStream: OFStream
{
#ifdef OF_DEFLATE_STREAM_M
@public
#endif
	OFStream *_stream;
	uint8_t _buffer[OF_DEFLATE_STREAM_BUFFER_SIZE];
	uint_fast16_t _bufferIndex, _bufferLength;
	uint8_t _byte;
	uint_fast8_t _bitIndex, _savedBitsLength;
	uint_fast16_t _savedBits;
@protected
	uint8_t *_slidingWindow;
	uint_fast16_t _slidingWindowIndex, _slidingWindowMask;
	struct {
		uint_fast8_t numDistanceCodes;
		const uint8_t *lengthCodes;
		const uint8_t *lengthExtraBits;
		const uint16_t *distanceCodes;
		const uint8_t *distanceExtraBits;
	} _codes;
	enum {
		OF_DEFLATE_STREAM_BLOCK_HEADER,
		OF_DEFLATE_STREAM_UNCOMPRESSED_BLOCK_HEADER,
		OF_DEFLATE_STREAM_UNCOMPRESSED_BLOCK,
		OF_DEFLATE_STREAM_HUFFMAN_TREE,
		OF_DEFLATE_STREAM_HUFFMAN_BLOCK
	} _state;
	union {
		struct {
			uint_fast8_t position;
			uint8_t length[4];
		} uncompressedHeader;
		struct {
			uint_fast16_t position, length;
		} uncompressed;
		struct {
			struct huffman_tree *litLenTree, *distTree;
			struct huffman_tree *codeLenTree, *treeIter;
			uint8_t *lengths;
			uint_fast16_t receivedCount;
			uint_fast8_t value, litLenCodesCount, distCodesCount;
			uint_fast8_t codeLenCodesCount;
		} huffmanTree;
		struct {
			struct huffman_tree *litLenTree, *distTree, *treeIter;
			enum {
				OF_DEFLATE_STREAM_WRITE_VALUE,
				OF_DEFLATE_STREAM_AWAIT_CODE,
				OF_DEFLATE_STREAM_AWAIT_LENGTH_EXTRA_BITS,
				OF_DEFLATE_STREAM_AWAIT_DISTANCE,
				OF_DEFLATE_STREAM_AWAIT_DISTANCE_EXTRA_BITS,
				OF_DEFLATE_STREAM_PROCESS_PAIR
			} state;
			uint_fast16_t value, length, distance;
			uint_fast16_t extraBits;
		} huffman;
	} _context;
	bool _inLastBlock, _atEndOfStream;
}

/*!
 * @brief Creates a new OFDeflateStream with the specified underlying stream.
 *
 * @param stream The underlying stream to which compressed data is written or
 *		 from which compressed data is read
 * @return A new, autoreleased OFDeflateStream
 */
+ (instancetype)streamWithStream: (OFStream*)stream;

/*!
 * @brief Initializes an already allocated OFDeflateStream with the specified
 *	  underlying stream.
 *
 * @param stream The underlying stream to which compressed data is written or
 *		 from which compressed data is read
 * @return A initialized OFDeflateStream
 */
- initWithStream: (OFStream*)stream;
@end
