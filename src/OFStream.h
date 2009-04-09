/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

/**
 * The OFStream protocol provides functions to read from and write to streams.
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
	  intoBuffer: (char*)buf;

/**
 * Writes from a buffer into the stream.
 *
 * \param buf The buffer from which the data is written to the stream
 * \param size The size of the data that should be written
 * \return The number of bytes written
 */
- (size_t)writeNBytes: (size_t)size
	   fromBuffer: (const char*)buf;

/**
 * Writes a C string into the stream, without the trailing zero.
 *
 * \param str The C string from which the data is written to the stream
 * \return The number of bytes written
 */
- (size_t)writeCString: (const char*)str;

/**
 * Closes the stream.
 */
- close;
@end
