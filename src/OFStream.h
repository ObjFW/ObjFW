/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"

@class OFString;

/**
 * \brief A base class for different types of streams.
 */
@interface OFStream: OFObject
{
	char   *cache;
	size_t cache_len;
}

/**
 * Returns a boolean whether the end of the stream has been reached.
 *
 * IMPORTANT: Do *NOT* override this in subclasses! Override
 * atEndOfStreamWithoutCache instead, as otherwise, you *WILL* break caching and
 * thus get broken results!
 *
 * \return A boolean whether the end of the stream has been reached
 */
- (BOOL)atEndOfStream;

/**
 * Returns a boolean whether the end of the stream has been reached without
 * looking at the cache.
 *
 * IMPORTANT: Do *NOT* use this! Use atEndOfCache instead, as this is *ONLY*
 * for being overriden in subclasses!
 *
 * \return A boolean whether the end of the stream has been reached
 */
- (BOOL)atEndOfStreamWithoutCache;

/**
 * Reads from the stream into a buffer.
 *
 * IMPORTANT: Do *NOT* override this in subclasses! Override
 * readNBytesWithoutCache:intoBuffer: instead, as otherwise, you *WILL* break
 * caching and thus get broken results!
 *
 * \param buf The buffer into which the data is read
 * \param size The size of the data that should be read.
 *	  The buffer MUST be at least size big!
 * \return The number of bytes read
 */
- (size_t)readNBytes: (size_t)size
	  intoBuffer: (char*)buf;

/**
 * Reads from the stream into a buffer without looking at the cache.
 *
 * IMPORTANT: Do *NOT* use this! Use readNBytes:intoBuffer: instead, as this is
 * *ONLY* for being overriden in subclasses!
 *
 * \param buf The buffer into which the data is read
 * \param size The size of the data that should be read.
 *	  The buffer MUST be at least size big!
 * \return The number of bytes read
 */
- (size_t)readNBytesWithoutCache: (size_t)size
		      intoBuffer: (char*)buf;

/**
 * Read until a newline, \\0 or end of stream occurs.
 *
 * \return The line that was read, autoreleased, or nil if the end of the
 *	   stream has been reached.
 */
- (OFString*)readLine;

/**
 * Read with the specified encoding until a newline, \\0 or end of stream
 * occurs.
 *
 * \return The line that was read, autoreleased, or nil if the end of the
 *	   stream has been reached.
 */
- (OFString*)readLineWithEncoding: (enum of_string_encoding)encoding;

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
 * Writes a string into the stream, without the trailing zero.
 *
 * \param str The string from which the data is written to the stream
 * \return The number of bytes written
 */
- (size_t)writeString: (OFString*)str;

/**
 * Closes the stream.
 */
- close;
@end
