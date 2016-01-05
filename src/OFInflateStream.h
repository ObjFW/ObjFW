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

#import "OFStream.h"

OF_ASSUME_NONNULL_BEGIN

#define OF_INFLATE_STREAM_BUFFER_SIZE 4096

/*!
 * @class OFInflateStream OFInflateStream.h ObjFW/OFInflateStream.h
 *
 * @brief A class that handles Deflate decompression transparently for an
 *	  underlying stream.
 */
@interface OFInflateStream: OFStream
{
#ifdef OF_INFLATE_STREAM_M
@public
#endif
	OFStream *_stream;
	uint8_t _buffer[OF_INFLATE_STREAM_BUFFER_SIZE];
	uint16_t _bufferIndex, _bufferLength;
	uint8_t _byte;
	uint8_t _bitIndex, _savedBitsLength;
	uint16_t _savedBits;
@protected
	uint8_t *_slidingWindow;
	uint16_t _slidingWindowIndex, _slidingWindowMask;
	enum {
		OF_INFLATE_STREAM_BLOCK_HEADER,
		OF_INFLATE_STREAM_UNCOMPRESSED_BLOCK_HEADER,
		OF_INFLATE_STREAM_UNCOMPRESSED_BLOCK,
		OF_INFLATE_STREAM_HUFFMAN_TREE,
		OF_INFLATE_STREAM_HUFFMAN_BLOCK
	} _state;
	union {
		struct {
			uint8_t position;
			uint8_t length[4];
		} uncompressedHeader;
		struct {
			uint16_t position, length;
		} uncompressed;
		struct {
			struct huffman_tree *litLenTree, *distTree;
			struct huffman_tree *codeLenTree, *treeIter;
			uint8_t *lengths;
			uint16_t receivedCount;
			uint8_t value, litLenCodesCount, distCodesCount;
			uint8_t codeLenCodesCount;
		} huffmanTree;
		struct {
			struct huffman_tree *litLenTree, *distTree, *treeIter;
			enum {
				OF_INFLATE_STREAM_WRITE_VALUE,
				OF_INFLATE_STREAM_AWAIT_CODE,
				OF_INFLATE_STREAM_AWAIT_LENGTH_EXTRA_BITS,
				OF_INFLATE_STREAM_AWAIT_DISTANCE,
				OF_INFLATE_STREAM_AWAIT_DISTANCE_EXTRA_BITS,
				OF_INFLATE_STREAM_PROCESS_PAIR
			} state;
			uint16_t value, length, distance;
			uint16_t extraBits;
		} huffman;
	} _context;
	bool _inLastBlock, _atEndOfStream;
}

/*!
 * @brief Creates a new OFInflateStream with the specified underlying stream.
 *
 * @param stream The underlying stream to which compressed data is written or
 *		 from which compressed data is read
 * @return A new, autoreleased OFInflateStream
 */
+ (instancetype)streamWithStream: (OFStream*)stream;

/*!
 * @brief Initializes an already allocated OFInflateStream with the specified
 *	  underlying stream.
 *
 * @param stream The underlying stream to which compressed data is written or
 *		 from which compressed data is read
 * @return A initialized OFInflateStream
 */
- initWithStream: (OFStream*)stream;
@end

OF_ASSUME_NONNULL_END
