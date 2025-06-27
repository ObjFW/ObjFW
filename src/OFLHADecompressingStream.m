/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#include "config.h"

#import "OFLHADecompressingStream.h"
#import "OFKernelEventObserver.h"

#import "OFHuffmanTree.h"

#import "OFInvalidFormatException.h"
#import "OFNotOpenException.h"

enum State {
	stateBlockHeader,
	stateCodeLenCodesCount,
	stateCodeLenTree,
	stateCodeLenTreeSingle,
	stateLitLenCodesCount,
	stateLitLenTree,
	stateLitLenTreeSingle,
	stateDistCodesCount,
	stateDistTree,
	stateDistTreeSingle,
	stateBlockLitLen,
	stateBlockDistLength,
	stateBlockDistLengthExtra,
	stateBlockLenDistPair
};

@implementation OFLHADecompressingStream
@synthesize bytesConsumed = _bytesConsumed;

static OF_INLINE bool
tryReadBits(OFLHADecompressingStream *stream, uint16_t *bits, uint8_t count)
{
	uint16_t ret = stream->_savedBits;

	OFAssert(stream->_savedBitsLength < count);

	for (uint_fast8_t i = stream->_savedBitsLength; i < count; i++) {
		if OF_UNLIKELY (stream->_bitIndex == 8) {
			if OF_LIKELY (stream->_bufferIndex <
			    stream->_bufferLength)
				stream->_byte =
				    stream->_buffer[stream->_bufferIndex++];
			else {
				const size_t bufferLength =
				    OFLHADecompressingStreamBufferSize;
				size_t length = [stream->_stream
				    readIntoBuffer: stream->_buffer
					    length: bufferLength];

				stream->_bytesConsumed += (uint32_t)length;

				if OF_UNLIKELY (length < 1) {
					stream->_savedBits = ret;
					stream->_savedBitsLength = i;
					return false;
				}

				stream->_byte = stream->_buffer[0];
				stream->_bufferIndex = 1;
				stream->_bufferLength = (uint16_t)length;
			}

			stream->_bitIndex = 0;
		}

		ret = (ret << 1) |
		    ((stream->_byte >> (7 - stream->_bitIndex++)) & 1);
	}

	stream->_savedBits = 0;
	stream->_savedBitsLength = 0;
	*bits = ret;

	return true;
}

- (instancetype)of_initWithStream: (OFStream *)stream
		     distanceBits: (uint8_t)distanceBits
		   dictionaryBits: (uint8_t)dictionaryBits
{
	self = [super init];

	@try {
		_stream = objc_retain(stream);

		/* 0-7 address the bit, 8 means fetch next byte */
		_bitIndex = 8;

		_distanceBits = distanceBits;
		_dictionaryBits = dictionaryBits;

		_slidingWindowMask = (1u << dictionaryBits) - 1;
		_slidingWindow = OFAllocMemory(_slidingWindowMask + 1, 1);
		memset(_slidingWindow, ' ', _slidingWindowMask + 1);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_stream != nil)
		[self close];

	OFFreeMemory(_slidingWindow);

	if (_codeLenTree != NULL)
		_OFHuffmanTreeFree(_codeLenTree);
	if (_litLenTree != NULL)
		_OFHuffmanTreeFree(_litLenTree);
	if (_distTree != NULL)
		_OFHuffmanTreeFree(_distTree);

	OFFreeMemory(_codesLengths);

	[super dealloc];
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer_
			  length: (size_t)length
{
	unsigned char *buffer = buffer_;
	uint16_t bits = 0, value = 0;
	size_t bytesWritten = 0;

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_stream.atEndOfStream && _bufferLength - _bufferIndex == 0 &&
	    _state == stateBlockHeader)
		return 0;

start:
	switch ((enum State)_state) {
	case stateBlockHeader:
		if OF_UNLIKELY (!tryReadBits(self, &bits, 16))
			return bytesWritten;

		_symbolsLeft = bits;

		_state = stateCodeLenCodesCount;
		goto start;
	case stateCodeLenCodesCount:
		if OF_UNLIKELY (!tryReadBits(self, &bits, 5))
			return bytesWritten;

		if OF_UNLIKELY (bits > 20)
			@throw [OFInvalidFormatException exception];

		if OF_UNLIKELY (bits == 0) {
			_state = stateCodeLenTreeSingle;
			goto start;
		}

		_codesCount = bits;
		_codesReceived = 0;
		_codesLengths = OFAllocZeroedMemory(bits, 1);
		_skip = true;

		_state = stateCodeLenTree;
		goto start;
	case stateCodeLenTree:
		while (_codesReceived < _codesCount) {
			if OF_UNLIKELY (_currentIsExtendedLength) {
				if OF_UNLIKELY (!tryReadBits(self, &bits, 1))
					return bytesWritten;

				if OF_UNLIKELY (bits == 0) {
					_codesReceived++;
					_currentIsExtendedLength = false;
					continue;
				}

				_codesLengths[_codesReceived]++;
				continue;
			}

			if OF_UNLIKELY (_codesReceived == 3 && _skip) {
				if OF_UNLIKELY (!tryReadBits(self, &bits, 2))
					return bytesWritten;

				if OF_UNLIKELY (_codesReceived + bits >
				    _codesCount)
					@throw [OFInvalidFormatException
					    exception];

				for (uint_fast8_t j = 0; j < bits; j++)
					_codesLengths[_codesReceived++] = 0;

				_skip = false;
				continue;
			}

			if OF_UNLIKELY (!tryReadBits(self, &bits, 3))
				return bytesWritten;

			_codesLengths[_codesReceived] = bits;

			if OF_UNLIKELY (bits == 7) {
				_currentIsExtendedLength = true;
				continue;
			} else
				_codesReceived++;
		}

		_codeLenTree = _OFHuffmanTreeNew(_codesLengths, _codesCount);
		OFFreeMemory(_codesLengths);
		_codesLengths = NULL;

		_state = stateLitLenCodesCount;
		goto start;
	case stateCodeLenTreeSingle:
		if OF_UNLIKELY (!tryReadBits(self, &bits, 5))
			return bytesWritten;

		_codeLenTree = _OFHuffmanTreeNewSingle(bits);

		_state = stateLitLenCodesCount;
		goto start;
	case stateLitLenCodesCount:
		if OF_UNLIKELY (!tryReadBits(self, &bits, 9))
			return bytesWritten;

		if OF_UNLIKELY (bits > 510)
			@throw [OFInvalidFormatException exception];

		if OF_UNLIKELY (bits == 0) {
			_OFHuffmanTreeFree(_codeLenTree);
			_codeLenTree = NULL;

			_state = stateLitLenTreeSingle;
			goto start;
		}

		_codesCount = bits;
		_codesReceived = 0;
		_codesLengths = OFAllocZeroedMemory(bits, 1);
		_skip = false;

		_treeIter = _codeLenTree;
		_state = stateLitLenTree;
		goto start;
	case stateLitLenTree:
		while (_codesReceived < _codesCount) {
			if OF_UNLIKELY (_skip) {
				uint16_t skipCount;

				switch (_codesLengths[_codesReceived]) {
				case 0:
					skipCount = 1;
					break;
				case 1:
					if OF_UNLIKELY (!tryReadBits(self,
					    &bits, 4))
						return bytesWritten;

					skipCount = bits + 3;
					break;
				case 2:
					if OF_UNLIKELY (!tryReadBits(self,
					    &bits, 9))
						return bytesWritten;

					skipCount = bits + 20;
					break;
				default:
					OFEnsure(0);
				}

				if OF_UNLIKELY (_codesReceived + skipCount >
				    _codesCount)
					@throw [OFInvalidFormatException
					    exception];

				for (uint_fast16_t j = 0; j < skipCount; j++)
					_codesLengths[_codesReceived++] = 0;

				_skip = false;
				continue;
			}

			if (!_OFHuffmanTreeWalk(self, tryReadBits, &_treeIter,
			    &value))
				return bytesWritten;

			_treeIter = _codeLenTree;

			if (value < 3) {
				_codesLengths[_codesReceived] = value;
				_skip = true;
			} else
				_codesLengths[_codesReceived++] = value - 2;
		}

		_litLenTree = _OFHuffmanTreeNew(_codesLengths, _codesCount);
		OFFreeMemory(_codesLengths);
		_codesLengths = NULL;

		_OFHuffmanTreeFree(_codeLenTree);
		_codeLenTree = NULL;

		_state = stateDistCodesCount;
		goto start;
	case stateLitLenTreeSingle:
		if OF_UNLIKELY (!tryReadBits(self, &bits, 9))
			return bytesWritten;

		_litLenTree = _OFHuffmanTreeNewSingle(bits);

		_state = stateDistCodesCount;
		goto start;
	case stateDistCodesCount:
		if OF_UNLIKELY (!tryReadBits(self, &bits, _distanceBits))
			return bytesWritten;

		if OF_UNLIKELY (bits > _dictionaryBits)
			@throw [OFInvalidFormatException exception];

		if OF_UNLIKELY (bits == 0) {
			_state = stateDistTreeSingle;
			goto start;
		}

		_codesCount = bits;
		_codesReceived = 0;
		_codesLengths = OFAllocZeroedMemory(bits, 1);

		_treeIter = _codeLenTree;
		_state = stateDistTree;
		goto start;
	case stateDistTree:
		while (_codesReceived < _codesCount) {
			if OF_UNLIKELY (_currentIsExtendedLength) {
				if OF_UNLIKELY (!tryReadBits(self, &bits, 1))
					return bytesWritten;

				if OF_UNLIKELY (bits == 0) {
					_codesReceived++;
					_currentIsExtendedLength = false;
					continue;
				}

				_codesLengths[_codesReceived]++;
				continue;
			}

			if OF_UNLIKELY (!tryReadBits(self, &bits, 3))
				return bytesWritten;

			_codesLengths[_codesReceived] = bits;

			if OF_UNLIKELY (bits == 7) {
				_currentIsExtendedLength = true;
				continue;
			} else
				_codesReceived++;
		}

		_distTree = _OFHuffmanTreeNew(_codesLengths, _codesCount);
		OFFreeMemory(_codesLengths);
		_codesLengths = NULL;

		_treeIter = _litLenTree;
		_state = stateBlockLitLen;
		goto start;
	case stateDistTreeSingle:
		if OF_UNLIKELY (!tryReadBits(self, &bits, _distanceBits))
			return bytesWritten;

		_distTree = _OFHuffmanTreeNewSingle(bits);

		_treeIter = _litLenTree;
		_state = stateBlockLitLen;
		goto start;
	case stateBlockLitLen:
		if OF_UNLIKELY (_symbolsLeft == 0) {
			_OFHuffmanTreeFree(_litLenTree);
			_OFHuffmanTreeFree(_distTree);
			_litLenTree = _distTree = NULL;

			_state = stateBlockHeader;

			/*
			 * We must return here, as there is no indication
			 * whether this was the last block. Whoever called this
			 * method needs to check if everything has been read
			 * already and only call read again if that is not the
			 * case.
			 *
			 * We must also unread the buffer, in case this was the
			 * last block and something else follows, e.g. another
			 * LHA header.
			 */
			[_stream unreadFromBuffer: _buffer + _bufferIndex
					   length: _bufferLength -
						   _bufferIndex];
			_bytesConsumed -= _bufferLength - _bufferIndex;
			_bufferIndex = _bufferLength = 0;

			return bytesWritten;
		}

		if OF_UNLIKELY (length == 0)
			return bytesWritten;

		if OF_UNLIKELY (!_OFHuffmanTreeWalk(self, tryReadBits,
		    &_treeIter, &value))
			return bytesWritten;

		if OF_LIKELY (value < 256) {
			buffer[bytesWritten++] = value;
			length--;

			_slidingWindow[_slidingWindowIndex] = value;
			_slidingWindowIndex = (_slidingWindowIndex + 1) &
			    _slidingWindowMask;

			_symbolsLeft--;
			_treeIter = _litLenTree;
		} else {
			_length = value - 253;
			_treeIter = _distTree;
			_state = stateBlockDistLength;
		}

		goto start;
	case stateBlockDistLength:
		if OF_UNLIKELY (!_OFHuffmanTreeWalk(self, tryReadBits,
		    &_treeIter, &value))
			return bytesWritten;

		_distance = value;

		_state = (value < 2
		    ? stateBlockLenDistPair : stateBlockDistLengthExtra);
		goto start;
	case stateBlockDistLengthExtra:
		if OF_UNLIKELY (!tryReadBits(self, &bits, _distance - 1))
			return bytesWritten;

		_distance = bits + (1u << (_distance - 1));

		_state = stateBlockLenDistPair;
		goto start;
	case stateBlockLenDistPair:
		for (uint_fast16_t i = 0; i < _length; i++) {
			uint32_t idx;

			if OF_UNLIKELY (length == 0) {
				_length -= i;
				return bytesWritten;
			}

			idx = (_slidingWindowIndex - _distance - 1) &
			    _slidingWindowMask;
			value = _slidingWindow[idx];

			buffer[bytesWritten++] = value;
			length--;

			_slidingWindow[_slidingWindowIndex] = value;
			_slidingWindowIndex = (_slidingWindowIndex + 1) &
			    _slidingWindowMask;
		}

		_symbolsLeft--;

		_treeIter = _litLenTree;
		_state = stateBlockLitLen;
		goto start;
	}

	OF_UNREACHABLE
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	return (_stream.atEndOfStream &&
	    _bufferLength - _bufferIndex == 0 && _state == stateBlockHeader);
}

- (int)fileDescriptorForReading
{
	return ((id <OFReadyForReadingObserving>)_stream)
	    .fileDescriptorForReading;
}

- (bool)lowlevelHasDataInReadBuffer
{
	return (_stream.hasDataInReadBuffer ||
	    _bufferLength - _bufferIndex > 0);
}

- (void)close
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	/* Give back our buffer to the stream, in case it's shared */
	[_stream unreadFromBuffer: _buffer + _bufferIndex
			   length: _bufferLength - _bufferIndex];
	_bytesConsumed -= _bufferLength - _bufferIndex;
	_bufferIndex = _bufferLength = 0;

	objc_release(_stream);
	_stream = nil;

	[super close];
}
@end
