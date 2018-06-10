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

#import "OFStream.h"
#import "OFKernelEventObserver.h"

OF_ASSUME_NONNULL_BEGIN

#define OF_INFLATE64_STREAM_BUFFER_SIZE 4096

/*!
 * @class OFInflate64Stream OFInflate64Stream.h ObjFW/OFInflate64Stream.h
 *
 * @note This class only conforms to OFReadyForReadingObserving if the
 *	 underlying stream does so, too.
 *
 * @brief A class that handles Deflate decompression transparently for an
 *	  underlying stream.
 */
@interface OFInflate64Stream: OFStream <OFReadyForReadingObserving>
{
#ifdef OF_INFLATE64_STREAM_M
@public
#endif
	OF_KINDOF(OFStream *) _stream;
	unsigned char _buffer[OF_INFLATE64_STREAM_BUFFER_SIZE];
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
			struct of_huffman_tree *_Nullable litLenTree;
			struct of_huffman_tree *_Nullable distTree;
			struct of_huffman_tree *_Nullable codeLenTree;
			struct of_huffman_tree *_Nullable treeIter;
			uint8_t *_Nullable lengths;
			uint16_t receivedCount;
			uint8_t value, litLenCodesCount, distCodesCount;
			uint8_t codeLenCodesCount;
		} huffmanTree;
		struct {
			struct of_huffman_tree *_Nullable litLenTree;
			struct of_huffman_tree *_Nullable distTree;
			struct of_huffman_tree *_Nullable treeIter;
			int state;
			uint16_t value, length, distance, extraBits;
		} huffman;
	} _context;
	bool _inLastBlock, _atEndOfStream;
}

/*!
 * @brief Creates a new OFInflate64Stream with the specified underlying stream.
 *
 * @param stream The underlying stream to which compressed data is written or
 *		 from which compressed data is read
 * @return A new, autoreleased OFInflate64Stream
 */
+ (instancetype)streamWithStream: (OF_KINDOF(OFStream *))stream;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFInflate64Stream with the specified
 *	  underlying stream.
 *
 * @param stream The underlying stream to which compressed data is written or
 *		 from which compressed data is read
 * @return A initialized OFInflate64Stream
 */
- (instancetype)initWithStream: (OF_KINDOF(OFStream *))stream
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
