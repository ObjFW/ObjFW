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

#import "OFStream.h"

OF_ASSUME_NONNULL_BEGIN

#define OF_LHA_DECOMPRESSING_STREAM_BUFFER_SIZE 4096

@interface OFLHADecompressingStream: OFStream
{
@public
	OFStream *_stream;
	uint8_t _distanceBits, _dictionaryBits;
	unsigned char _buffer[OF_LHA_DECOMPRESSING_STREAM_BUFFER_SIZE];
	uint32_t _bytesConsumed;
	uint16_t _bufferIndex, _bufferLength;
	uint8_t _byte;
	uint8_t _bitIndex, _savedBitsLength;
	uint16_t _savedBits;
	unsigned char *_slidingWindow;
	uint32_t _slidingWindowIndex, _slidingWindowMask;
	int _state;
	uint16_t _symbolsLeft;
	struct of_huffman_tree *_Nullable _codeLenTree, *_Nullable _litLenTree;
	struct of_huffman_tree *_Nullable _distTree, *_Nullable _treeIter;
	uint16_t _codesCount, _codesReceived;
	bool _currentIsExtendedLength, _skip;
	uint8_t *_Nullable _codesLengths;
	uint16_t _length;
	uint32_t _distance;
}

- (instancetype)of_initWithStream: (OFStream *)stream
		     distanceBits: (uint8_t)distanceBits
		   dictionaryBits: (uint8_t)dictionaryBits;
@end

OF_ASSUME_NONNULL_END
