/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
#import "OFHuffmanTree.h"

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
	OFHuffmanTree _Nullable _codeLenTree;
	OFHuffmanTree _Nullable _litLenTree;
	OFHuffmanTree _Nullable _distTree;
	OFHuffmanTree _Nullable _treeIter;
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
