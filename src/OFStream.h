/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <stdarg.h>

#import "OFObject.h"
#import "OFString.h"

@class OFDataArray;

/**
 * \brief A base class for different types of streams.
 *
 * IMPORTANT: If you want to subclass this, override _readNBytes:intoBuffer:,
 * _writeNBytes:fromBuffer: and _isAtEndOfStream, but nothing else. Those are
 * not defined in the headers, but do the actual work. OFStream uses those and
 * does all the caching and other stuff. If you override these methods without
 * the _ prefix, you *WILL* break caching and get broken results!
 */
@interface OFStream: OFObject
{
	char   *cache;
	char   *writeBuffer;
	size_t cacheLength, writeBufferLength;
	BOOL   buffersWrites;
	BOOL   isBlocking;
}

#ifdef OF_HAVE_PROPERTIES
@property (assign, setter=setBlocking:) BOOL isBlocking;
#endif

/**
 * \brief Returns a boolean whether the end of the stream has been reached.
 *
 * \return A boolean whether the end of the stream has been reached
 */
- (BOOL)isAtEndOfStream;

/**
 * \brief Reads <i>at most</i> size bytes from the stream into a buffer.
 *
 * On network streams, this might read less than the specified number of bytes.
 * If you want to read exactly the specified number of bytes, use
 * -[readExactlyNBytes:intoBuffer:].
 *
 * \param buffer The buffer into which the data is read
 * \param length The length of the data that should be read at most.
 *		 The buffer MUST be at least this big!
 * \return The number of bytes read
 */
- (size_t)readNBytes: (size_t)size
	  intoBuffer: (void*)buffer;

/**
 * \brief Reads exactly the specified length bytes from the stream into a
 *	  buffer.
 *
 * Unlike readNBytes:intoBuffer:, this method does not return when less than the
 * specified length has been read - instead, it waits until it got exactly the
 * specified length.
 *
 * WARNING: Only call this when you know that specified amount of data is
 *	    available! Otherwise you will get an exception!
 *
 * \param buffer The buffer into which the data is read
 * \param length The length of the data that should be read.
 *	       The buffer MUST be EXACTLY this big!
 */
- (void)readExactlyNBytes: (size_t)length
	       intoBuffer: (void*)buffer;

/**
 * \brief Reads a uint8_t from the stream.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \return A uint8_t from the stream
 */
- (uint8_t)readInt8;

/**
 * \brief Reads a uint16_t from the stream which is encoded in big endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \return A uint16_t from the stream in native endianess
 */
- (uint16_t)readBigEndianInt16;

/**
 * \brief Reads a uint32_t from the stream which is encoded in big endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \return A uint32_t from the stream in the native endianess
 */
- (uint32_t)readBigEndianInt32;

/**
 * \brief Reads a uint64_t from the stream which is encoded in big endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \return A uint64_t from the stream in the native endianess
 */
- (uint64_t)readBigEndianInt64;

/**
 * \brief Reads a float from the stream which is encoded in big endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \return A float from the stream in the native endianess
 */
- (float)readBigEndianFloat;

/**
 * \brief Reads a double from the stream which is encoded in big endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \return A double from the stream in the native endianess
 */
- (double)readBigEndianDouble;

/**
 * \brief Reads the specified number of uint16_ts from the stream which are
 *	  encoded in big endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \param nInt16s The number of uint16_ts to read
 * \param buffer A buffer of sufficient size to store the specified number of
 *		 uint16_ts
 * \return The number of bytes read
 */
- (size_t)readNBigEndianInt16s: (size_t)nInt16s
		    intoBuffer: (uint16_t*)buffer;

/**
 * \brief Reads the specified number of uint32_ts from the stream which are
 *	  encoded in big endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \param nInt32s The number of uint32_ts to read
 * \param buffer A buffer of sufficient size to store the specified number of
 *		 uint32_ts
 * \return The number of bytes read
 */
- (size_t)readNBigEndianInt32s: (size_t)nInt32s
		    intoBuffer: (uint32_t*)buffer;

/**
 * \brief Reads the specified number of uint64_ts from the stream which are
 *	  encoded in big endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \param nInt64s The number of uint64_ts to read
 * \param buffer A buffer of sufficient size to store the specified number of
 *		 uint64_ts
 * \return The number of bytes read
 */
- (size_t)readNBigEndianInt64s: (size_t)nInt64s
		    intoBuffer: (uint64_t*)buffer;

/**
 * \brief Reads the specified number of floats from the stream which are encoded
 *	  in big endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \param nFloatss The number of floats to read
 * \param buffer A buffer of sufficient size to store the specified number of
 *		 floats
 * \return The number of bytes read
 */
- (size_t)readNBigEndianFloats: (size_t)nFloats
		    intoBuffer: (float*)buffer;

/**
 * \brief Reads the specified number of doubles from the stream which are
 *	  encoded in big endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \param nDoubles The number of doubles to read
 * \param buffer A buffer of sufficient size to store the specified number of
 *		 doubles
 * \return The number of bytes read
 */
- (size_t)readNBigEndianDoubles: (size_t)nDoubles
		     intoBuffer: (double*)buffer;

/**
 * \brief Reads a uint16_t from the stream which is encoded in little endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \return A uint16_t from the stream in native endianess
 */
- (uint16_t)readLittleEndianInt16;

/**
 * \brief Reads a uint32_t from the stream which is encoded in little endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \return A uint32_t from the stream in the native endianess
 */
- (uint32_t)readLittleEndianInt32;

/**
 * \brief Reads a uint64_t from the stream which is encoded in little endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \return A uint64_t from the stream in the native endianess
 */
- (uint64_t)readLittleEndianInt64;

/**
 * \brief Reads a float from the stream which is encoded in little endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \return A float from the stream in the native endianess
 */
- (float)readLittleEndianFloat;

/**
 * \brief Reads a double from the stream which is encoded in little endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \return A double from the stream in the native endianess
 */
- (double)readLittleEndianDouble;

/**
 * \brief Reads the specified number of uint16_ts from the stream which are
 *	  encoded in little endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \param nInt16s The number of uint16_ts to read
 * \param buffer A buffer of sufficient size to store the specified number of
 *		 uint16_ts
 * \return The number of bytes read
 */
- (size_t)readNLittleEndianInt16s: (size_t)nInt16s
		       intoBuffer: (uint16_t*)buffer;

/**
 * \brief Reads the specified number of uint32_ts from the stream which are
 *	  encoded in little endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \param nInt32s The number of uint32_ts to read
 * \param buffer A buffer of sufficient size to store the specified number of
 *		 uint32_ts
 * \return The number of bytes read
 */
- (size_t)readNLittleEndianInt32s: (size_t)nInt32s
		       intoBuffer: (uint32_t*)buffer;

/**
 * \brief Reads the specified number of uint64_ts from the stream which are
 *	  encoded in little endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \param nInt64s The number of uint64_ts to read
 * \param buffer A buffer of sufficient size to store the specified number of
 *		 uint64_ts
 * \return The number of bytes read
 */
- (size_t)readNLittleEndianInt64s: (size_t)nInt64s
		       intoBuffer: (uint64_t*)buffer;

/**
 * \brief Reads the specified number of floats from the stream which are
 *	  encoded in little endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \param nFloats The number of floats to read
 * \param buffer A buffer of sufficient size to store the specified number of
 *		 floats
 * \return The number of bytes read
 */
- (size_t)readNLittleEndianFloats: (size_t)nFloats
		       intoBuffer: (float*)buffer;

/**
 * \brief Reads the specified number of doubles from the stream which are
 *	  encoded in little endian.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \param nDoubles The number of doubles to read
 * \param buffer A buffer of sufficient size to store the specified number of
 *		 doubles
 * \return The number of bytes read
 */
- (size_t)readNLittleEndianDoubles: (size_t)nDoubles
			intoBuffer: (double*)buffer;

/**
 * \brief Reads the specified number of items with an item size of 1 from the
 *	  stream and returns them in an OFDataArray.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \param nItems The number of items to read
 * \return An OFDataArray with at nItems items.
 */
- (OFDataArray*)readDataArrayWithNItems: (size_t)nItems;

/**
 * \brief Reads the specified number of items with the specified item size from
 *	  the stream and returns them in an OFDataArray.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \param itemSize The size of each item
 * \param nItems The number of items to read
 * \return An OFDataArray with at nItems items.
 */
- (OFDataArray*)readDataArrayWithItemSize: (size_t)itemSize
				andNItems: (size_t)nItems;

/**
 * \brief Returns an OFDataArray with all the remaining data of the stream.
 *
 * \return An OFDataArray with an item size of 1 with all the data of the
 *	   stream until the end of the stream is reached.
 */
- (OFDataArray*)readDataArrayTillEndOfStream;

/**
 * \brief Reads a string with the specified length from the stream.
 *
 * If a \\0 appears in the stream, the string will be truncated at the \\0 and
 * the rest of the bytes of the string will be lost. This way, reading from the
 * stream will not break because of a \\0 because the specified number of bytes
 * is still being read and only the string gets truncated.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \param length The length (in bytes) of the string to read from the stream
 * \return A string with the specified length
 */
- (OFString*)readStringWithLength: (size_t)length;

/**
 * \brief Reads a string with the specified encoding and length from the stream.
 *
 * If a \\0 appears in the stream, the string will be truncated at the \\0 and
 * the rest of the bytes of the string will be lost. This way, reading from the
 * stream will not break because of a \\0 because the specified number of bytes
 * is still being read and only the string gets truncated.
 *
 * WARNING: Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * \param encoding The encoding of the string to read from the stream
 * \param length The length (in bytes) of the string to read from the stream
 * \return A string with the specified length
 */
- (OFString*)readStringWithEncoding: (of_string_encoding_t)encoding
			     length: (size_t)length;

/**
 * \brief Reads until a newline, \\0 or end of stream occurs.
 *
 * \return The line that was read, autoreleased, or nil if the end of the
 *	   stream has been reached.
 */
- (OFString*)readLine;

/**
 * \brief Reads with the specified encoding until a newline, \\0 or end of
 *	  stream occurs.
 *
 * \param encoding The encoding used by the stream
 * \return The line that was read, autoreleased, or nil if the end of the
 *	   stream has been reached.
 */
- (OFString*)readLineWithEncoding: (of_string_encoding_t)encoding;

/**
 * \brief Tries to read a line from the stream (see readLine) and returns nil if
 *	  no complete line has been received yet.
 *
 * \return The line that was read, autoreleased, or nil if the line is not
 *	   complete yet
 */
- (OFString*)tryReadLine;

/**
 * \brief Tries to read a line from the stream with the specified encoding (see
 *	  readLineWithEncoding:) and returns nil if no complete line has been
 *	  received yet.
 *
 * \param encoding The encoding used by the stream
 * \return The line that was read, autoreleased, or nil if the line is not
 *	   complete yet
 */
- (OFString*)tryReadLineWithEncoding: (of_string_encoding_t)encoding;

/**
 * \brief Reads until the specified string or \\0 is found or the end of stream
 *	  occurs.
 *
 * \param delimiter The delimiter
 * \return The line that was read, autoreleased, or nil if the end of the
 *	   stream has been reached.
 */
- (OFString*)readTillDelimiter: (OFString*)delimiter;

/**
 * \brief Reads until the specified string or \\0 is found or the end of stream
 *	  occurs.
 *
 * \param delimiter The delimiter
 * \param encoding The encoding used by the stream
 * \return The line that was read, autoreleased, or nil if the end of the
 *	   stream has been reached.
 */
- (OFString*)readTillDelimiter: (OFString*)delimiter
		  withEncoding: (of_string_encoding_t)encoding;

/**
 * \brief Returns a boolen whether writes are buffered.
 *
 * \return A boolean whether writes are buffered
 */
- (BOOL)buffersWrites;

/**
 * \brief Enables or disables the write buffer.
 *
 * \param enable Whether the write buffer should be enabled or disabled
 */
- (void)setBuffersWrites: (BOOL)enable;

/**
 * \brief Writes everythig in the write buffer to the stream.
 */
- (void)flushWriteBuffer;

/**
 * \brief Writes from a buffer into the stream.
 *
 * \param buffer The buffer from which the data is written to the stream
 * \param length The length of the data that should be written
 */
- (void)writeNBytes: (size_t)length
	 fromBuffer: (const void*)buffer;

/**
 * \brief Writes a uint8_t into the stream.
 *
 * \param int8 A uint8_t
 */
- (void)writeInt8: (uint8_t)int8;

/**
 * \brief Writes a uint16_t into the stream, encoded in big endian.
 *
 * \param int16 A uint16_t
 */
- (void)writeBigEndianInt16: (uint16_t)int16;

/**
 * \brief Writes a uint32_t into the stream, encoded in big endian.
 *
 * \param int32 A uint32_t
 */
- (void)writeBigEndianInt32: (uint32_t)int32;

/**
 * \brief Writes a uint64_t into the stream, encoded in big endian.
 *
 * \param int64 A uint64_t
 */
- (void)writeBigEndianInt64: (uint64_t)int64;

/**
 * \brief Writes a float into the stream, encoded in big endian.
 *
 * \param float_ A float
 */
- (void)writeBigEndianFloat: (float)float_;

/**
 * \brief Writes a double into the stream, encoded in big endian.
 *
 * \param double_ A double
 */
- (void)writeBigEndianDouble: (double)double_;

/**
 * \brief Writes the specified number of uint16_ts into the stream, encoded in
 *	  big endian.
 *
 * \param nInt16 The number of uint16_ts to write
 * \param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * \return The number of bytes written to the stream
 */
- (size_t)writeNBigEndianInt16s: (size_t)nInt16s
		     fromBuffer: (const uint16_t*)buffer;

/**
 * \brief Writes the specified number of uint32_ts into the stream, encoded in
 *	  big endian.
 *
 * \param nInt32 The number of uint32_ts to write
 * \param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * \return The number of bytes written to the stream
 */
- (size_t)writeNBigEndianInt32s: (size_t)nInt32s
		     fromBuffer: (const uint32_t*)buffer;

/**
 * \brief Writes the specified number of uint64_ts into the stream, encoded in
 *	  big endian.
 *
 * \param nInt64 The number of uint64_ts to write
 * \param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * \return The number of bytes written to the stream
 */
- (size_t)writeNBigEndianInt64s: (size_t)nInt64s
		     fromBuffer: (const uint64_t*)buffer;

/**
 * \brief Writes the specified number of floats into the stream, encoded in big
 *	  endian.
 *
 * \param nFloats The number of floats to write
 * \param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * \return The number of bytes written to the stream
 */
- (size_t)writeNBigEndianFloats: (size_t)nFloats
		     fromBuffer: (const float*)buffer;

/**
 * \brief Writes the specified number of doubles into the stream, encoded in
 *	  big endian.
 *
 * \param nDoubles The number of doubles to write
 * \param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * \return The number of bytes written to the stream
 */
- (size_t)writeNBigEndianDoubles: (size_t)nDoubles
		      fromBuffer: (const double*)buffer;

/**
 * \brief Writes a uint16_t into the stream, encoded in little endian.
 *
 * \param int16 A uint16_t
 */
- (void)writeLittleEndianInt16: (uint16_t)int16;

/**
 * \brief Writes a uint32_t into the stream, encoded in little endian.
 *
 * \param int32 A uint32_t
 */
- (void)writeLittleEndianInt32: (uint32_t)int32;

/**
 * \brief Writes a uint64_t into the stream, encoded in little endian.
 *
 * \param int64 A uint64_t
 */
- (void)writeLittleEndianInt64: (uint64_t)int64;

/**
 * \brief Writes a float into the stream, encoded in little endian.
 *
 * \param float_ A float
 */
- (void)writeLittleEndianFloat: (float)float_;

/**
 * \brief Writes a double into the stream, encoded in little endian.
 *
 * \param double_ A double
 */
- (void)writeLittleEndianDouble: (double)double_;

/**
 * \brief Writes the specified number of uint16_ts into the stream, encoded in
 *	  little endian.
 *
 * \param nInt16 The number of uint16_ts to write
 * \param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * \return The number of bytes written to the stream
 */
- (size_t)writeNLittleEndianInt16s: (size_t)nInt16s
			fromBuffer: (const uint16_t*)buffer;

/**
 * \brief Writes the specified number of uint32_ts into the stream, encoded in
 *	  little endian.
 *
 * \param nInt32 The number of uint32_ts to write
 * \param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * \return The number of bytes written to the stream
 */
- (size_t)writeNLittleEndianInt32s: (size_t)nInt32s
			fromBuffer: (const uint32_t*)buffer;

/**
 * \brief Writes the specified number of uint64_ts into the stream, encoded in
 *	  little endian.
 *
 * \param nInt64 The number of uint64_ts to write
 * \param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * \return The number of bytes written to the stream
 */
- (size_t)writeNLittleEndianInt64s: (size_t)nInt64s
			fromBuffer: (const uint64_t*)buffer;

/**
 * \brief Writes the specified number of floats into the stream, encoded in
 *	  little endian.
 *
 * \param nFloats The number of floats to write
 * \param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * \return The number of bytes written to the stream
 */
- (size_t)writeNLittleEndianFloats: (size_t)nFloats
			fromBuffer: (const float*)buffer;

/**
 * \brief Writes the specified number of doubles into the stream, encoded in
 *	  little endian.
 *
 * \param nDoubles The number of doubles to write
 * \param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * \return The number of bytes written to the stream
 */
- (size_t)writeNLittleEndianDoubles: (size_t)nDoubles
			 fromBuffer: (const double*)buffer;

/**
 * \brief Writes from an OFDataArray into the stream.
 *
 * \param dataArray The OFDataArray to write into the stream
 * \return The number of bytes written
 */
- (size_t)writeDataArray: (OFDataArray*)dataArray;

/**
 * \brief Writes a string into the stream, without the trailing zero.
 *
 * \param string The string from which the data is written to the stream
 * \return The number of bytes written
 */
- (size_t)writeString: (OFString*)string;

/**
 * \brief Writes a string into the stream with a trailing newline.
 *
 * \param string The string from which the data is written to the stream
 * \return The number of bytes written
 */
- (size_t)writeLine: (OFString*)string;

/**
 * \brief Writes a formatted string into the stream.
 *
 * See printf for the format syntax. As an addition, %@ is available as format
 * specifier for objects.
 *
 * \param format A string used as format
 * \return The number of bytes written
 */
- (size_t)writeFormat: (OFConstantString*)format, ...;

/**
 * \brief Writes a formatted string into the stream.
 *
 * See printf for the format syntax. As an addition, %@ is available as format
 * specifier for objects.
 *
 * \param format A string used as format
 * \param arguments The arguments used in the format string
 * \return The number of bytes written
 */
- (size_t)writeFormat: (OFConstantString*)format
	withArguments: (va_list)arguments;

/**
 * \brief Returns the number of bytes still present in the internal cache.
 *
 * \return The number of bytes still present in the internal cache.
 */
- (size_t)pendingBytes;

/**
 * \brief Returns whether the stream is in blocking mode.
 *
 * \return Whether the stream is in blocking mode
 */
- (BOOL)isBlocking;

/**
 * \brief Enables or disables non-blocking I/O.
 *
 * By default, a stream is in blocking mode.
 * On Win32, this currently only works for sockets!
 *
 * \param enable Whether the stream should be blocking
 */
- (void)setBlocking: (BOOL)enable;

/**
 * \brief Returns the file descriptor for the stream.
 *
 * \return The file descriptor for the stream
 */
- (int)fileDescriptor;

/**
 * \brief Closes the stream.
 */
- (void)close;
@end
