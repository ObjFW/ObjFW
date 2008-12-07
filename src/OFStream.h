/*
 * Copyright (c) 2008
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

/**
 * The OFStream protocol provides functions to read and write streams.
 */
@protocol OFStream
/**
 * Reads from the stream into a buffer.
 *
 * \param buf The buffer into which the data is read
 * \param size The size of the data that should be read.
 *	  The buffer MUST be at least size big!
 * \return The number of bytes read
 */
- (size_t)readNBytes: (size_t)size
	  intoBuffer: (uint8_t*)buf;

/**
 * Reads from the stream into a new buffer.
 *
 * \param size The size of the data that should be read
 * \return A new buffer with the data read.
 *	   It is part of the memory pool of the OFFile.
 */
- (uint8_t*)readNBytes: (size_t)size;

/**
 * Writes from a buffer into the stream.
 *
 * \param buf The buffer from which the data is written to the stream
 * \param size The size of the data that should be written
 * \return The number of bytes written
 */
- (size_t)writeNBytes: (size_t)size
	   fromBuffer: (const uint8_t*)buf;

/**
 * Writes a C string into the stream, without the trailing zero.
 *
 * \param str The C string from which the data is written to the stream
 * \return The number of bytes written
 */
- (size_t)writeCString: (const char*)str;

/**
 * Writes a C string into the stream, without the trailing zero.
 *
 * \param str The wide C string from which the data is written to the stream
 * \return The number of bytes written
 */
- (size_t)writeWideCString: (const wchar_t*)str;
@end
