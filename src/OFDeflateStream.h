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

#import "OFStream.h"

OF_ASSUME_NONNULL_BEGIN

#define OF_INFLATE_STREAM_BUFFER_SIZE 4096

/*!
 * @class OFDeflateStream OFDeflateStream.h ObjFW/OFDeflateStream.h
 *
 * @brief A class that handles Deflate decompression transparently for an
 *	  underlying stream.
 */
@interface OFDeflateStream: OFStream
{
#ifdef OF_INFLATE_STREAM_M
@public
#endif
	OFStream *_stream;
	struct of_deflate_stream_decompression_ivars {
		uint8_t buffer[OF_INFLATE_STREAM_BUFFER_SIZE];
		uint16_t bufferIndex, bufferLength;
		uint8_t byte;
		uint8_t bitIndex, savedBitsLength;
		uint16_t savedBits;
		uint8_t *slidingWindow;
		uint16_t slidingWindowIndex, slidingWindowMask;
		int state;
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
				struct huffman_tree *litLenTree, *distTree;
				struct huffman_tree *treeIter;
				int state;
				uint16_t value, length, distance;
				uint16_t extraBits;
			} huffman;
		} context;
		bool inLastBlock, atEndOfStream;
	} *_decompression;
}

/*!
 * @brief Creates a new OFDeflateStream with the specified underlying stream.
 *
 * @param stream The underlying stream to which compressed data is written or
 *		 from which compressed data is read
 * @return A new, autoreleased OFDeflateStream
 */
+ (instancetype)streamWithStream: (OFStream *)stream;

/*!
 * @brief Initializes an already allocated OFDeflateStream with the specified
 *	  underlying stream.
 *
 * @param stream The underlying stream to which compressed data is written or
 *		 from which compressed data is read
 * @return A initialized OFDeflateStream
 */
- initWithStream: (OFStream *)stream;
@end

OF_ASSUME_NONNULL_END
