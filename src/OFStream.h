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

#import "OFObject.h"
#import "OFString.h"

/**
 * The OFStream class provides a base class for different types of streams.
 */
@interface OFStream: OFObject
{
	char   *cache;
	size_t cache_len;
}

/**
 * \return A boolean whether the end of the stream has been reached
 */
- (BOOL)atEndOfStream;

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
 * Read until a newline, \\0 or end of stream occurs.
 *
 * If you want to use readNBytes afterwards again, you have to clear the cache
 * before and optionally get the cache before clearing it!
 *
 * You also need to pay attention to the cache if you want to know if there is
 * still data left - atEndOfStream can return NO even if there is still data
 * in the cache!
 *
 * \return The line that was read, autoreleased, or nil if the end of the
 *	   stream has been reached.
 */
- (OFString*)readLine;

/**
 * Read with the specified encoding until a newline, \\0 or end of stream
 * occurs.
 *
 * If you want to use readNBytes afterwards again, you have to clear the cache
 * before and optionally get the cache before clearing it!
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
 * Sets a specified pointer to the cache and returns the length of the cache.
 *
 * \param ptr A pointer to a pointer. It will be set to the cache.
 *	      If it is NULL, only the number of bytes in the cache is returned.
 * \return The number of bytes in the cache.
 */
- (size_t)getCache: (char**)ptr;

/**
 * Clears the cache.
 */
- clearCache;

/**
 * Closes the stream.
 */
- close;
@end
