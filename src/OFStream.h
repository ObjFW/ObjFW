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
@class OFDataArray;

/**
 * \brief A base class for different types of streams.
 *
 * IMPORTANT: If you want to subclass this, override _readNBytes:intoBuffer:,
 * _writeNBytes:fromBuffer: and _atEndOfStream, but nothing else. Those are not
 * defined in the headers, but do the actual work. OFStream uses those and does
 * all the caching and other stuff. If you override these methods without the
 * _ prefix, you *WILL* break caching and get broken results!
 */
@interface OFStream: OFObject
{
	char   *cache, *wcache;
	size_t cache_len, wcache_len;
	BOOL   use_wcache;
}

/**
 * Returns a boolean whether the end of the stream has been reached.
 *
 * \return A boolean whether the end of the stream has been reached
 */
- (BOOL)atEndOfStream;

/**
 * Reads at most size bytes from the stream into a buffer.
 *
 * \param buf The buffer into which the data is read
 * \param size The size of the data that should be read at most.
 *	       The buffer MUST be at least size big!
 * \return The number of bytes read
 */
- (size_t)readNBytes: (size_t)size
	  intoBuffer: (char*)buf;

/**
 * Reads exactly size bytes from the stream into a buffer. Unlike
 * readNBytes:intoBuffer:, this method does not return when less than the
 * specified size has been read - instead, it waits until it got exactly size
 * bytes.
 *
 * \param buf The buffer into which the data is read
 * \param size The size of the data that should be read.
 *	       The buffer MUST be EXACTLY this big!
 */
- (void)readExactlyNBytes: (size_t)size
	       intoBuffer: (char*)buf;

/**
 * Reads an uint8_t from the stream.
 *
 * \return An uint8_t from the stream
 */
- (uint8_t)readInt8;

/**
 * Reads an uint16_t from the stream which is encoded in big endian.
 *
 * \return An uint16_t from the stream in native endianess
 */
- (uint16_t)readBigEndianInt16;

/**
 * Reads an uint32_t from the stream which is encoded in big endian.
 *
 * \return An uint32_t from the stream in the native endianess
 */
- (uint32_t)readBigEndianInt32;

/**
 * Reads an uint64_t from the stream which is encoded in big endian.
 *
 * \return An uint64_t from the stream in the native endianess
 */
- (uint64_t)readBigEndianInt64;

/**
 * Reads an uint16_t from the stream which is encoded in little endian.
 *
 * \return An uint16_t from the stream in native endianess
 */
- (uint16_t)readLittleEndianInt16;

/**
 * Reads an uint32_t from the stream which is encoded in little endian.
 *
 * \return An uint32_t from the stream in the native endianess
 */
- (uint32_t)readLittleEndianInt32;

/**
 * Reads an uint64_t from the stream which is encoded in little endian.
 *
 * \return An uint64_t from the stream in the native endianess
 */
- (uint64_t)readLittleEndianInt64;

/**
 * Reads nitems items with the specified item size from the stream and returns
 * them in an OFDataArray.
 *
 * \param itemsize The size of each item
 * \param nitems The number of iteams to read
 * \return An OFDataArray with at nitems items.
 */
- (OFDataArray*)readDataArrayWithItemSize: (size_t)itemsize
				andNItems: (size_t)nitems;

/**
 * \return An OFDataArray with an item size of 1 with all the data of the
 *	   stream until the end of the stream is reached.
 */
- (OFDataArray*)readDataArrayTillEndOfStream;

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
 * \param encoding The encoding used by the stream
 * \return The line that was read, autoreleased, or nil if the end of the
 *	   stream has been reached.
 */
- (OFString*)readLineWithEncoding: (enum of_string_encoding)encoding;

/**
 * Read until the specified string or \\0 is found or the end of stream occurs.
 *
 * \param delimiter The delimiter
 * \return The line that was read, autoreleased, or nil if the end of the
 *	   stream has been reached.
 */
- (OFString*)readTillDelimiter: (OFString*)delimiter;

/**
 * Read until the specified string or \\0 is found or the end of stream occurs.
 *
 * \param delimiter The delimiter
 * \param encoding The encoding used by the stream
 * \return The line that was read, autoreleased, or nil if the end of the
 *	   stream has been reached.
 */
- (OFString*)readTillDelimiter: (OFString*)delimiter
		  withEncoding: (enum of_string_encoding)encoding;

/**
 * Caches all writes until flushWriteCache is called.
 */
- cacheWrites;

/**
 * Writes everything in the write cache to the stream.
 */
- flushWriteCache;

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
 * Writes an uint8_t into the stream.
 *
 * \param int8 An uint8_t
 */
- (void)writeInt8: (uint8_t)int8;

/**
 * Writes an uint16_t into the stream, encoded in big endian.
 *
 * \param int16 An uint16_t
 */
- (void)writeBigEndianInt16: (uint16_t)int16;

/**
 * Writes an uint32_t into the stream, encoded in big endian.
 *
 * \param int32 An uint32_t
 */
- (void)writeBigEndianInt32: (uint32_t)int32;

/**
 * Writes an uint64_t into the stream, encoded in big endian.
 *
 * \param int64 An uint64_t
 */
- (void)writeBigEndianInt64: (uint64_t)int64;

/**
 * Writes an uint16_t into the stream, encoded in little endian.
 *
 * \param int16 An uint16_t
 */
- (void)writeLittleEndianInt16: (uint16_t)int16;

/**
 * Writes an uint32_t into the stream, encoded in little endian.
 *
 * \param int32 An uint32_t
 */
- (void)writeLittleEndianInt32: (uint32_t)int32;

/**
 * Writes an uint64_t into the stream, encoded in little endian.
 *
 * \param int64 An uint64_t
 */
- (void)writeLittleEndianInt64: (uint64_t)int64;

/**
 * Writes from an OFDataArray into the stream.
 *
 * \param dataarray The OFDataArray to write into the stream
 * \return The number of bytes written
 */
- (size_t)writeDataArray: (OFDataArray*)dataarray;

/**
 * Writes a string into the stream, without the trailing zero.
 *
 * \param str The string from which the data is written to the stream
 * \return The number of bytes written
 */
- (size_t)writeString: (OFString*)str;

/**
 * Writes a string into the stream with a trailing newline.
 *
 * \param str The string from which the data is written to the stream
 * \return The number of bytes written
 */
- (size_t)writeLine: (OFString*)str;

/**
 * Writes a formatted string into the stream.
 *
 * \param fmt A string used as format
 * \return The number of bytes written
 */
- (size_t)writeFormat: (OFString*)fmt, ...;

/**
 * Closes the stream.
 */
- close;
@end
