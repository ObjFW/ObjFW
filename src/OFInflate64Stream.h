/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import "OFStream.h"
#import "OFKernelEventObserver.h"

OF_ASSUME_NONNULL_BEGIN

#define OFInflate64StreamBufferSize 4096

/**
 * @class OFInflate64Stream OFInflate64Stream.h ObjFW/ObjFW.h
 *
 * @note This class only conforms to OFReadyForReadingObserving if the
 *	 underlying stream does so, too.
 *
 * @brief A class that handles Deflate decompression transparently for an
 *	  underlying stream.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFInflate64Stream: OFStream <OFReadyForReadingObserving>
{
	OFStream *_stream;
	unsigned char _buffer[OFInflate64StreamBufferSize];
	uint16_t _bufferIndex, _bufferLength;
	uint8_t _byte;
	uint8_t _bitIndex, _savedBitsLength;
	uint16_t _savedBits;
	unsigned char *_Nullable _slidingWindow;
	uint16_t _slidingWindowIndex, _slidingWindowMask;
	int _state;
	union {
		struct {
			uint8_t position;
			uint8_t length[4];
		} uncompressedHeader;
		struct {
			uint16_t position, length;
		} uncompressed;
		struct {
			struct _OFHuffmanTree *_Nullable litLenTree;
			struct _OFHuffmanTree *_Nullable distTree;
			struct _OFHuffmanTree *_Nullable codeLenTree;
			struct _OFHuffmanTree *_Nullable treeIter;
			uint8_t *_Nullable lengths;
			uint16_t receivedCount;
			uint8_t value, litLenCodesCount, distCodesCount;
			uint8_t codeLenCodesCount;
		} huffmanTree;
		struct {
			struct _OFHuffmanTree *_Nullable litLenTree;
			struct _OFHuffmanTree *_Nullable distTree;
			struct _OFHuffmanTree *_Nullable treeIter;
			int state;
			uint16_t value, length, distance, extraBits;
		} huffman;
	} _context;
	bool _inLastBlock, _atEndOfStream;
}

/**
 * @brief The underlying stream of the inflate stream.
 *
 * Setting this can be useful if the the data to be inflated is coming from
 * multiple streams, such as split across multiple files.
 */
@property (retain, nonatomic) OFStream *underlyingStream;

/**
 * @brief Creates a new OFInflate64Stream with the specified underlying stream.
 *
 * @param stream The underlying stream to which compressed data is written or
 *		 from which compressed data is read
 * @return A new, autoreleased OFInflate64Stream
 */
+ (instancetype)streamWithStream: (OFStream *)stream;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated OFInflate64Stream with the specified
 *	  underlying stream.
 *
 * @param stream The underlying stream to which compressed data is written or
 *		 from which compressed data is read
 * @return A initialized OFInflate64Stream
 */
- (instancetype)initWithStream: (OFStream *)stream OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
