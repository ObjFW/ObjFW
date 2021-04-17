/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#define OFLHADecompressingStreamBufferSize 4096

OF_DIRECT_MEMBERS
@interface OFLHADecompressingStream: OFStream
{
	OFStream *_stream;
	uint8_t _distanceBits, _dictionaryBits;
	unsigned char _buffer[OFLHADecompressingStreamBufferSize];
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

@property (readonly, nonatomic) uint32_t bytesConsumed;

- (instancetype)of_initWithStream: (OFStream *)stream
		     distanceBits: (uint8_t)distanceBits
		   dictionaryBits: (uint8_t)dictionaryBits;
@end

OF_ASSUME_NONNULL_END
