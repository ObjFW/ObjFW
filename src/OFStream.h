/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#include <stdarg.h>

#import "OFObject.h"
#import "OFString.h"
#import "OFRunLoop.h"
#ifdef OF_HAVE_SOCKETS
# import "OFKernelEventObserver.h"
#endif

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFStream;
@class OFData;

#if defined(OF_HAVE_SOCKETS) && defined(OF_HAVE_BLOCKS)
/**
 * @brief A block which is called when data was read asynchronously from a
 *	  stream.
 *
 * @param length The length of the data that has been read
 * @param exception An exception which occurred while reading or `nil` on
 *		    success
 * @return A bool whether the same block should be used for the next read
 */
typedef bool (^OFStreamAsyncReadBlock)(size_t length, id _Nullable exception);

/**
 * @brief A block which is called when a line was read asynchronously from a
 *	  stream.
 *
 * @param line The line which has been read or `nil` when the end of stream
 *	       occurred
 * @param exception An exception which occurred while reading or `nil` on
 *		    success
 * @return A bool whether the same block should be used for the next read
 */
typedef bool (^OFStreamAsyncReadLineBlock)(OFString *_Nullable line,
    id _Nullable exception);

/**
 * @brief A block which is called when data was written asynchronously to a
 *	  stream.
 *
 * @param bytesWritten The number of bytes which have been written. This
 *		       matches the length of the specified data on the
 *		       asynchronous write if no exception was encountered.
 * @param exception An exception which occurred while writing or `nil` on
 *		    success
 * @return The data to repeat the write with or nil if it should not repeat
 */
typedef OFData *_Nullable (^OFStreamAsyncWriteDataBlock)(size_t bytesWritten,
    id _Nullable exception);

/**
 * @brief A block which is called when a string was written asynchronously to a
 *	  stream.
 *
 * @param bytesWritten The number of bytes which have been written. This
 *		       matches the length of the specified data on the
 *		       asynchronous write if no exception was encountered.
 * @param exception An exception which occurred while writing or `nil` on
 *		    success
 * @return The string to repeat the write with or nil if it should not repeat
 */
typedef OFString *_Nullable (^OFStreamAsyncWriteStringBlock)(
    size_t bytesWritten, id _Nullable exception);
#endif

/**
 * @protocol OFStreamDelegate OFStream.h ObjFW/OFStream.h
 *
 * A delegate for OFStream.
 */
@protocol OFStreamDelegate <OFObject>
@optional
/**
 * @brief This method is called when data was read asynchronously from a
 *	  stream.
 *
 * @param stream The stream on which data was read
 * @param buffer A buffer with the data that has been read
 * @param length The length of the data that has been read
 * @param exception An exception that occurred while reading, or nil on success
 * @return A bool whether the read should be repeated
 */
-      (bool)stream: (OFStream *)stream
  didReadIntoBuffer: (void *)buffer
	     length: (size_t)length
	  exception: (nullable id)exception;

/**
 * @brief This method is called when a line was read asynchronously from a
 *	  stream.
 *
 * @param stream The stream on which a line was read
 * @param line The line which has been read or `nil` when the end of stream
 *	       occurred
 * @param exception An exception that occurred while reading, or nil on success
 * @return A bool whether the read should be repeated
 */
- (bool)stream: (OFStream *)stream
   didReadLine: (nullable OFString *)line
     exception: (nullable id)exception;

/**
 * @brief This method is called when data was written asynchronously to a
 *	  stream.
 *
 * @param stream The stream to which data was written
 * @param data The data which was written to the stream
 * @param bytesWritten The number of bytes which have been written. This
 *		       matches the length of the specified data on the
 *		       asynchronous write if no exception was encountered.
 * @param exception An exception that occurred while writing, or nil on success
 * @return The data to repeat the write with or nil if it should not repeat
 */
- (nullable OFData *)stream: (OFStream *)stream
	       didWriteData: (OFData *)data
	       bytesWritten: (size_t)bytesWritten
		  exception: (nullable id)exception;

/**
 * @brief This method is called when a string was written asynchronously to a
 *	  stream.
 *
 * @param stream The stream to which a string was written
 * @param string The string which was written to the stream
 * @param encoding The encoding in which the string was written
 * @param bytesWritten The number of bytes which have been written. This
 *		       matches the length of the specified data on the
 *		       asynchronous write if no exception was encountered.
 * @param exception An exception that occurred while writing, or nil on success
 * @return The string to repeat the write with or nil if it should not repeat
 */
- (nullable OFString *)stream: (OFStream *)stream
	       didWriteString: (OFString *)string
		     encoding: (OFStringEncoding)encoding
		 bytesWritten: (size_t)bytesWritten
		    exception: (nullable id)exception;
@end

/**
 * @class OFStream OFStream.h ObjFW/OFStream.h
 *
 * @brief A base class for different types of streams.
 *
 * @warning Even though the OFCopying protocol is implemented, it does *not*
 *	    return an independent copy of the stream, but instead retains it.
 *	    This is so that the stream can be used as a key for a dictionary,
 *	    so context can be associated with a stream. Using a stream in more
 *	    than one thread at the same time is not thread-safe, even if copy
 *	    was called to create one "instance" for every thread!
 *
 * @note If you want to subclass this, override
 *	 @ref lowlevelReadIntoBuffer:length:, @ref lowlevelWriteBuffer:length:
 *	 and @ref lowlevelIsAtEndOfStream, but nothing else, as those are are
 *	 the methods that do the actual work. OFStream uses those for all other
 *	 methods and does all the caching and other stuff for you. If you
 *	 override these methods without the `lowlevel` prefix, you *will* break
 *	 caching and get broken results!
 */
@interface OFStream: OFObject <OFCopying>
{
	bool _canBlock;
	id _Nullable _delegate;
#ifndef OF_SEEKABLE_STREAM_M
@private
#endif
	char *_Nullable _readBuffer, *_Nullable _readBufferMemory;
	char *_Nullable _writeBuffer;
	size_t _readBufferLength, _writeBufferLength;
	bool _buffersWrites, _waitingForDelimiter;
	OF_RESERVE_IVARS(OFStream, 4)
}

/**
 * @brief Whether the end of the stream has been reached.
 */
@property (readonly, nonatomic, getter=isAtEndOfStream) bool atEndOfStream;

/**
 * @brief Whether writes are buffered.
 */
@property (nonatomic) bool buffersWrites;

/**
 * @brief Whether data is present in the internal read buffer.
 */
@property (readonly, nonatomic) bool hasDataInReadBuffer;

/**
 * @brief Whether the stream can block.
 *
 * By default, a stream can block.
 * On Win32, setting this currently only works for sockets!
 *
 * @throw OFGetOptionFailedException The option could not be retrieved
 * @throw OFSetOptionFailedException The option could not be set
 */
@property (nonatomic) bool canBlock;

/**
 * @brief The delegate for asynchronous operations on the stream.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFStreamDelegate> delegate;

/**
 * @brief Reads *at most* `length` bytes from the stream into a buffer.
 *
 * On network streams, this might read less than the specified number of bytes.
 * If you want to read exactly the specified number of bytes, use
 * @ref readIntoBuffer:exactLength:. Note that a read can even return 0 bytes -
 * this does not necessarily mean that the stream ended, so you still need to
 * check @ref atEndOfStream. Do not assume that the stream ended just because a
 * read returned 0 bytes - some streams do internal processing that has a
 * result of 0 bytes.
 *
 * @param buffer The buffer into which the data is read
 * @param length The length of the data that should be read at most.
 *		 The buffer *must* be *at least* this big!
 * @return The number of bytes read
 * @throw OFReadFailedException Reading failed
 * @throw OFNotOpenException The stream is not open
 */
- (size_t)readIntoBuffer: (void *)buffer length: (size_t)length;

/**
 * @brief Reads exactly the specified `length` bytes from the stream into a
 *	  buffer.
 *
 * Unlike @ref readIntoBuffer:length:, this method does not return when less
 * than the specified length has been read - instead, it waits until it got
 * exactly the specified length.
 *
 * @warning Only call this when you know that specified amount of data is
 *	    available! Otherwise you will get an exception!
 *
 * @param buffer The buffer into which the data is read
 * @param length The length of the data that should be read.
 *		 The buffer *must* be *at least* this big!
 * @throw OFReadFailedException Reading failed
 * @throw OFTruncatedDataException The end of the stream was reached before
 *				   reading the specified amount
 * @throw OFNotOpenException The stream is not open
 */
 - (void)readIntoBuffer: (void *)buffer exactLength: (size_t)length;

#ifdef OF_HAVE_SOCKETS
/**
 * @brief Asynchronously reads *at most* `length` bytes from the stream into a
 *	  buffer.
 *
 * On network streams, this might read less than the specified number of bytes.
 * If you want to read exactly the specified number of bytes, use
 * @ref asyncReadIntoBuffer:exactLength:. Note that a read can even return 0
 * bytes - this does not necessarily mean that the stream ended, so you still
 * need to check @ref atEndOfStream. Do not assume that the stream ended just
 * because a read returned 0 bytes - some streams do internal processing that
 * has a result of 0 bytes.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 *
 * @param buffer The buffer into which the data is read.
 *		 The buffer must not be freed before the async read completed!
 * @param length The length of the data that should be read at most.
 *		 The buffer *must* be *at least* this big!
 */
- (void)asyncReadIntoBuffer: (void *)buffer length: (size_t)length;

/**
 * @brief Asynchronously reads *at most* `length` bytes from the stream into a
 *	  buffer.
 *
 * On network streams, this might read less than the specified number of bytes.
 * If you want to read exactly the specified number of bytes, use
 * @ref asyncReadIntoBuffer:exactLength:. Note that a read can even return 0
 * bytes - this does not necessarily mean that the stream ended, so you still
 * need to check @ref atEndOfStream. Do not assume that the stream ended just
 * because a read returned 0 bytes - some streams do internal processing that
 * has a result of 0 bytes.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 *
 * @param buffer The buffer into which the data is read.
 *		 The buffer must not be freed before the async read completed!
 * @param length The length of the data that should be read at most.
 *		 The buffer *must* be *at least* this big!
 * @param runLoopMode The run loop mode in which to perform the async read
 */
- (void)asyncReadIntoBuffer: (void *)buffer
		     length: (size_t)length
		runLoopMode: (OFRunLoopMode)runLoopMode;

/**
 * @brief Asynchronously reads exactly the specified `length` bytes from the
 *	  stream into a buffer.
 *
 * Unlike @ref asyncReadIntoBuffer:length:, this method does not call the
 * method when less than the specified length has been read - instead, it waits
 * until it got exactly the specified length, the stream has ended or an
 * exception occurred.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 *
 * @param buffer The buffer into which the data is read
 * @param length The length of the data that should be read.
 *		 The buffer *must* be *at least* this big!
 */
- (void)asyncReadIntoBuffer: (void *)buffer exactLength: (size_t)length;

/**
 * @brief Asynchronously reads exactly the specified `length` bytes from the
 *	  stream into a buffer.
 *
 * Unlike @ref asyncReadIntoBuffer:length:, this method does not call the
 * method when less than the specified length has been read - instead, it waits
 * until it got exactly the specified length, the stream has ended or an
 * exception occurred.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 *
 * @param buffer The buffer into which the data is read
 * @param length The length of the data that should be read.
 *		 The buffer *must* be *at least* this big!
 * @param runLoopMode The run loop mode in which to perform the async read
 */
- (void)asyncReadIntoBuffer: (void *)buffer
		exactLength: (size_t)length
		runLoopMode: (OFRunLoopMode)runLoopMode;

# ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously reads *at most* ref `length` bytes from the stream
 *	  into a buffer.
 *
 * On network streams, this might read less than the specified number of bytes.
 * If you want to read exactly the specified number of bytes, use
 * @ref asyncReadIntoBuffer:exactLength:block:. Note that a read can even
 * return 0 bytes - this does not necessarily mean that the stream ended, so
 * you still need to check @ref atEndOfStream. Do not assume that the stream
 * ended just because a read returned 0 bytes - some streams do internal
 * processing that has a result of 0 bytes.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 *
 * @param buffer The buffer into which the data is read.
 *		 The buffer must not be freed before the async read completed!
 * @param length The length of the data that should be read at most.
 *		 The buffer *must* be *at least* this big!
 * @param block The block to call when the data has been received.
 *		If the block returns true, it will be called again with the same
 *		buffer and maximum length when more data has been received. If
 *		you want the next block in the queue to handle the data
 *		received next, you need to return false from the block.
 */
- (void)asyncReadIntoBuffer: (void *)buffer
		     length: (size_t)length
		      block: (OFStreamAsyncReadBlock)block;

/**
 * @brief Asynchronously reads *at most* `length` bytes from the stream into a
 *	  buffer.
 *
 * On network streams, this might read less than the specified number of bytes.
 * If you want to read exactly the specified number of bytes, use
 * @ref asyncReadIntoBuffer:exactLength:block:. Note that a read can even
 * return 0 bytes - this does not necessarily mean that the stream ended, so
 * you still need to check @ref atEndOfStream. Do not assume that the stream
 * ended just because a read returned 0 bytes - some streams do internal
 * processing that has a result of 0 bytes.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 *
 * @param buffer The buffer into which the data is read.
 *		 The buffer must not be freed before the async read completed!
 * @param length The length of the data that should be read at most.
 *		 The buffer *must* be *at least* this big!
 * @param runLoopMode The run loop mode in which to perform the async read
 * @param block The block to call when the data has been received.
 *		If the block returns true, it will be called again with the same
 *		buffer and maximum length when more data has been received. If
 *		you want the next block in the queue to handle the data
 *		received next, you need to return false from the block.
 */
- (void)asyncReadIntoBuffer: (void *)buffer
		     length: (size_t)length
		runLoopMode: (OFRunLoopMode)runLoopMode
		      block: (OFStreamAsyncReadBlock)block;

/**
 * @brief Asynchronously reads exactly the specified `length` bytes from the
 *	  stream into a buffer.
 *
 * Unlike @ref asyncReadIntoBuffer:length:block:, this method does not invoke
 * the block when less than the specified length has been read - instead, it
 * waits until it got exactly the specified length, the stream has ended or an
 * exception occurred.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 *
 * @param buffer The buffer into which the data is read
 * @param length The length of the data that should be read.
 *		 The buffer *must* be *at least* this big!
 * @param block The block to call when the data has been received.
 *		If the block returns true, it will be called again with the same
 *		buffer and exact length when more data has been received. If
 *		you want the next block in the queue to handle the data
 *		received next, you need to return false from the block.
 */
- (void)asyncReadIntoBuffer: (void *)buffer
		exactLength: (size_t)length
		      block: (OFStreamAsyncReadBlock)block;

/**
 * @brief Asynchronously reads exactly the specified `length` bytes from the
 *	  stream into a buffer.
 *
 * Unlike @ref asyncReadIntoBuffer:length:block:, this method does not invoke
 * the block when less than the specified length has been read - instead, it
 * waits until it got exactly the specified length, the stream has ended or an
 * exception occurred.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 *
 * @param buffer The buffer into which the data is read
 * @param length The length of the data that should be read.
 *		 The buffer *must* be *at least* this big!
 * @param runLoopMode The run loop mode in which to perform the async read
 * @param block The block to call when the data has been received.
 *		If the block returns true, it will be called again with the same
 *		buffer and exact length when more data has been received. If
 *		you want the next block in the queue to handle the data
 *		received next, you need to return false from the block.
 */
- (void)asyncReadIntoBuffer: (void *)buffer
		exactLength: (size_t)length
		runLoopMode: (OFRunLoopMode)runLoopMode
		      block: (OFStreamAsyncReadBlock)block;
# endif
#endif

/**
 * @brief Reads a uint8_t from the stream.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A uint8_t from the stream
 * @throw OFReadFailedException Reading failed
 * @throw OFTruncatedDataException The end of the stream was reached before
 *				   reading enough bytes
 * @throw OFNotOpenException The stream is not open
 */
- (uint8_t)readInt8;

/**
 * @brief Reads a uint16_t from the stream which is encoded in big endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A uint16_t from the stream in big endian
 * @throw OFReadFailedException Reading failed
 * @throw OFTruncatedDataException The end of the stream was reached before
 *				   reading enough bytes
 * @throw OFNotOpenException The stream is not open
 */
- (uint16_t)readBigEndianInt16;

/**
 * @brief Reads a uint32_t from the stream which is encoded in big endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A uint32_t from the stream in big endian
 * @throw OFReadFailedException Reading failed
 * @throw OFTruncatedDataException The end of the stream was reached before
 *				   reading enough bytes
 * @throw OFNotOpenException The stream is not open
 */
- (uint32_t)readBigEndianInt32;

/**
 * @brief Reads a uint64_t from the stream which is encoded in big endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A uint64_t from the stream in big endian
 * @throw OFReadFailedException Reading failed
 * @throw OFTruncatedDataException The end of the stream was reached before
 *				   reading enough bytes
 * @throw OFNotOpenException The stream is not open
 */
- (uint64_t)readBigEndianInt64;

/**
 * @brief Reads a float from the stream which is encoded in big endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A float from the stream in big endian
 * @throw OFReadFailedException Reading failed
 * @throw OFTruncatedDataException The end of the stream was reached before
 *				   reading enough bytes
 * @throw OFNotOpenException The stream is not open
 */
- (float)readBigEndianFloat;

/**
 * @brief Reads a double from the stream which is encoded in big endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A double from the stream in big endian
 * @throw OFReadFailedException Reading failed
 * @throw OFTruncatedDataException The end of the stream was reached before
 *				   reading enough bytes
 * @throw OFNotOpenException The stream is not open
 */
- (double)readBigEndianDouble;

/**
 * @brief Reads a uint16_t from the stream which is encoded in little endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A uint16_t from the stream in little endian
 * @throw OFReadFailedException Reading failed
 * @throw OFTruncatedDataException The end of the stream was reached before
 *				   reading enough bytes
 * @throw OFNotOpenException The stream is not open
 */
- (uint16_t)readLittleEndianInt16;

/**
 * @brief Reads a uint32_t from the stream which is encoded in little endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A uint32_t from the stream in little endian
 * @throw OFReadFailedException Reading failed
 * @throw OFTruncatedDataException The end of the stream was reached before
 *				   reading enough bytes
 * @throw OFNotOpenException The stream is not open
 */
- (uint32_t)readLittleEndianInt32;

/**
 * @brief Reads a uint64_t from the stream which is encoded in little endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A uint64_t from the stream in little endian
 * @throw OFReadFailedException Reading failed
 * @throw OFTruncatedDataException The end of the stream was reached before
 *				   reading enough bytes
 * @throw OFNotOpenException The stream is not open
 */
- (uint64_t)readLittleEndianInt64;

/**
 * @brief Reads a float from the stream which is encoded in little endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A float from the stream in little endian
 * @throw OFReadFailedException Reading failed
 * @throw OFTruncatedDataException The end of the stream was reached before
 *				   reading enough bytes
 * @throw OFNotOpenException The stream is not open
 */
- (float)readLittleEndianFloat;

/**
 * @brief Reads a double from the stream which is encoded in little endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A double from the stream in little endian
 * @throw OFReadFailedException Reading failed
 * @throw OFTruncatedDataException The end of the stream was reached before
 *				   reading enough bytes
 * @throw OFNotOpenException The stream is not open
 */
- (double)readLittleEndianDouble;

/**
 * @brief Reads the specified number of items with an item size of 1 from the
 *	  stream and returns them as OFData.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @param count The number of items to read
 * @return OFData with count items.
 * @throw OFReadFailedException Reading failed
 * @throw OFTruncatedDataException The end of the stream was reached before
 *				   reading enough bytes
 * @throw OFNotOpenException The stream is not open
 */
- (OFData *)readDataWithCount: (size_t)count;

/**
 * @brief Reads the specified number of items with the specified item size from
 *	  the stream and returns them as OFData.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @param itemSize The size of each item
 * @param count The number of items to read
 * @return OFData with count items.
 * @throw OFReadFailedException Reading failed
 * @throw OFTruncatedDataException The end of the stream was reached before
 *				   reading enough bytes
 * @throw OFNotOpenException The stream is not open
 */
- (OFData *)readDataWithItemSize: (size_t)itemSize count: (size_t)count;

/**
 * @brief Returns OFData with all the remaining data of the stream.
 *
 * @return OFData with an item size of 1 with all the data of the stream until
 *	   the end of the stream is reached.
 * @throw OFReadFailedException Reading failed
 * @throw OFNotOpenException The stream is not open
 */
- (OFData *)readDataUntilEndOfStream;

/**
 * @brief Reads a string with the specified length from the stream.
 *
 * If `\0` appears in the stream, the string will be truncated at the `\0` and
 * the rest of the bytes of the string will be lost. This way, reading from the
 * stream will not break because of a `\0` because the specified number of
 * bytes is still being read and only the string gets truncated.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @param length The length (in bytes) of the string to read from the stream
 * @return A string with the specified length
 * @throw OFReadFailedException Reading failed
 * @throw OFInvalidEncodingException The string read from the stream has
 *				     invalid encoding
 * @throw OFTruncatedDataException The end of the stream was reached before
 *				   reading enough bytes
 * @throw OFNotOpenException The stream is not open
 */
- (OFString *)readStringWithLength: (size_t)length;

/**
 * @brief Reads a string with the specified encoding and length from the stream.
 *
 * If a `\0` appears in the stream, the string will be truncated at the `\0`
 * and the rest of the bytes of the string will be lost. This way, reading from
 * the stream will not break because of a `\0` because the specified number of
 * bytes is still being read and only the string gets truncated.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @param encoding The encoding of the string to read from the stream
 * @param length The length (in bytes) of the string to read from the stream
 * @return A string with the specified length
 * @throw OFReadFailedException Reading failed
 * @throw OFInvalidEncodingException The string read from the stream has
 *				     invalid encoding
 * @throw OFTruncatedDataException The end of the stream was reached before
 *				   reading enough bytes
 * @throw OFNotOpenException The stream is not open
 */
- (OFString *)readStringWithLength: (size_t)length
			  encoding: (OFStringEncoding)encoding;

/**
 * @brief Reads until a newline, `\0` or end of stream occurs.
 *
 * @return The line that was read, autoreleased, or `nil` if the end of the
 *	   stream has been reached.
 * @throw OFReadFailedException Reading failed
 * @throw OFInvalidEncodingException The string read from the stream has
 *				     invalid encoding
 * @throw OFNotOpenException The stream is not open
 */
- (nullable OFString *)readLine;

/**
 * @brief Reads with the specified encoding until a newline, `\0` or end of
 *	  stream occurs.
 *
 * @param encoding The encoding used by the stream
 * @return The line that was read, autoreleased, or `nil` if the end of the
 *	   stream has been reached.
 * @throw OFReadFailedException Reading failed
 * @throw OFInvalidEncodingException The string read from the stream has
 *				     invalid encoding
 * @throw OFNotOpenException The stream is not open
 */
- (nullable OFString *)readLineWithEncoding: (OFStringEncoding)encoding;

#ifdef OF_HAVE_SOCKETS
/**
 * @brief Asynchronously reads until a newline, `\0`, end of stream or an
 *	  exception occurs.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 */
- (void)asyncReadLine;

/**
 * @brief Asynchronously reads with the specified encoding until a newline,
 *	  `\0`, end of stream or an exception occurs.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 *
 * @param encoding The encoding used by the stream
 */
- (void)asyncReadLineWithEncoding: (OFStringEncoding)encoding;

/**
 * @brief Asynchronously reads with the specified encoding until a newline,
 *	  `\0`, end of stream or an exception occurs.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 *
 * @param encoding The encoding used by the stream
 * @param runLoopMode The run loop mode in which to perform the async read
 */
- (void)asyncReadLineWithEncoding: (OFStringEncoding)encoding
		      runLoopMode: (OFRunLoopMode)runLoopMode;

# ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously reads until a newline, `\0`, end of stream or an
 *	  exception occurs.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 *
 * @param block The block to call when the data has been received.
 *		If the block returns true, it will be called again when the next
 *		line has been received. If you want the next block in the queue
 *		to handle the next line, you need to return false from the
 *		block.
 */
- (void)asyncReadLineWithBlock: (OFStreamAsyncReadLineBlock)block;

/**
 * @brief Asynchronously reads with the specified encoding until a newline,
 *	  `\0`, end of stream or an exception occurs.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 *
 * @param encoding The encoding used by the stream
 * @param block The block to call when the data has been received.
 *		If the block returns true, it will be called again when the next
 *		line has been received. If you want the next block in the queue
 *		to handle the next line, you need to return false from the
 *		block.
 */
- (void)asyncReadLineWithEncoding: (OFStringEncoding)encoding
			    block: (OFStreamAsyncReadLineBlock)block;

/**
 * @brief Asynchronously reads with the specified encoding until a newline,
 *	  `\0`, end of stream or an exception occurs.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 *
 * @param encoding The encoding used by the stream
 * @param runLoopMode The run loop mode in which to perform the async read
 * @param block The block to call when the data has been received.
 *		If the block returns true, it will be called again when the next
 *		line has been received. If you want the next block in the queue
 *		to handle the next line, you need to return false from the
 *		block.
 */
- (void)asyncReadLineWithEncoding: (OFStringEncoding)encoding
		      runLoopMode: (OFRunLoopMode)runLoopMode
			    block: (OFStreamAsyncReadLineBlock)block;
# endif
#endif

/**
 * @brief Tries to read a line from the stream (see @ref readLine) and returns
 *	  `nil` if no complete line has been received yet.
 *
 * @return The line that was read, autoreleased, or `nil` if the line is not
 *	   complete yet
 * @throw OFReadFailedException Reading failed
 * @throw OFInvalidEncodingException The string read from the stream has
 *				     invalid encoding
 * @throw OFNotOpenException The stream is not open
 */
- (nullable OFString *)tryReadLine;

/**
 * @brief Tries to read a line from the stream with the specified encoding (see
 *	  @ref readLineWithEncoding:) and returns `nil` if no complete line has
 *	  been received yet.
 *
 * @param encoding The encoding used by the stream
 * @return The line that was read, autoreleased, or `nil` if the line is not
 *	   complete yet
 * @throw OFReadFailedException Reading failed
 * @throw OFInvalidEncodingException The string read from the stream has
 *				     invalid encoding
 * @throw OFNotOpenException The stream is not open
 */
- (nullable OFString *)tryReadLineWithEncoding: (OFStringEncoding)encoding;

/**
 * @brief Reads until the specified string or `\0` is found or the end of
 *	  stream occurs.
 *
 * @param delimiter The delimiter
 * @return The string that was read, autoreleased, or `nil` if the end of the
 *	   stream has been reached.
 * @throw OFReadFailedException Reading failed
 * @throw OFInvalidEncodingException The string read from the stream has
 *				     invalid encoding
 * @throw OFNotOpenException The stream is not open
 */
- (nullable OFString *)readUntilDelimiter: (OFString *)delimiter;

/**
 * @brief Reads until the specified string or `\0` is found or the end of
 *	  stream occurs.
 *
 * @param delimiter The delimiter
 * @param encoding The encoding used by the stream
 * @return The string that was read, autoreleased, or `nil` if the end of the
 *	   stream has been reached.
 * @throw OFReadFailedException Reading failed
 * @throw OFInvalidEncodingException The string read from the stream has
 *				     invalid encoding
 * @throw OFNotOpenException The stream is not open
 */
- (nullable OFString *)readUntilDelimiter: (OFString *)delimiter
				 encoding: (OFStringEncoding)encoding;

/**
 * @brief Tries to reads until the specified string or `\0` is found or the end
 *	  of stream (see @ref readUntilDelimiter:) and returns `nil` if not
 *	  enough data has been received yet.
 *
 * @param delimiter The delimiter
 * @return The string that was read, autoreleased, or `nil` if the end of the
 *	   stream has been reached.
 * @throw OFReadFailedException Reading failed
 * @throw OFInvalidEncodingException The string read from the stream has
 *				     invalid encoding
 * @throw OFNotOpenException The stream is not open
 */
- (nullable OFString *)tryReadUntilDelimiter: (OFString *)delimiter;

/**
 * @brief Tries to read until the specified string or `\0` is found or the end
 *	  of stream occurs (see @ref readUntilDelimiter:encoding:) and returns
 *	  `nil` if not enough data has been received yet.
 *
 * @param delimiter The delimiter
 * @param encoding The encoding used by the stream
 * @return The string that was read, autoreleased, or `nil` if the end of the
 *	   stream has been reached.
 * @throw OFReadFailedException Reading failed
 * @throw OFInvalidEncodingException The string read from the stream has
 *				     invalid encoding
 * @throw OFNotOpenException The stream is not open
 */
- (nullable OFString *)tryReadUntilDelimiter: (OFString *)delimiter
				    encoding: (OFStringEncoding)encoding;

/**
 * @brief Writes everything in the write buffer to the stream.
 *
 * @return Whether the write buffer was flushed entirely. On non-blocking
 *	   sockets, this can return `false` if flushing the write buffer in its
 *	   entirety would block.
 */
- (bool)flushWriteBuffer;

/**
 * @brief Writes from a buffer into the stream.
 *
 * In non-blocking mode, if less than the specified length could be written, an
 * @ref OFWriteFailedException is thrown with @ref OFWriteFailedException#errNo
 * being set to `EWOULDBLOCK` or `EAGAIN` (you need to check for both, as they
 * are not the same on some systems) and
 * @ref OFWriteFailedException#bytesWritten being set to the number of bytes
 * that were written, if any.
 *
 * @param buffer The buffer from which the data is written into the stream
 * @param length The length of the data that should be written
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (void)writeBuffer: (const void *)buffer length: (size_t)length;

#ifdef OF_HAVE_SOCKETS
/**
 * @brief Asynchronously writes data into the stream.
 *
 * @note The stream must conform to @ref OFReadyForWritingObserving in order
 *	 for this to work!
 *
 * @param data The data which is written into the stream
 */
- (void)asyncWriteData: (OFData *)data;

/**
 * @brief Asynchronously writes data into the stream.
 *
 * @note The stream must conform to @ref OFReadyForWritingObserving in order
 *	 for this to work!
 *
 * @param data The data which is written into the stream
 * @param runLoopMode The run loop mode in which to perform the async write
 */
- (void)asyncWriteData: (OFData *)data
	   runLoopMode: (OFRunLoopMode)runLoopMode;

/**
 * @brief Asynchronously writes a string in UTF-8 encoding into the stream.
 *
 * @note The stream must conform to @ref OFReadyForWritingObserving in order
 *	 for this to work!
 *
 * @param string The string which is written into the stream
 */
- (void)asyncWriteString: (OFString *)string;

/**
 * @brief Asynchronously writes a string in the specified encoding into the
 *	  stream.
 *
 * @note The stream must conform to @ref OFReadyForWritingObserving in order
 *	 for this to work!
 *
 * @param string The string which is written into the stream
 * @param encoding The encoding in which the string should be written to the
 *		   stream
 */
- (void)asyncWriteString: (OFString *)string
		encoding: (OFStringEncoding)encoding;

/**
 * @brief Asynchronously writes a string in the specified encoding into the
 *	  stream.
 *
 * @note The stream must conform to @ref OFReadyForWritingObserving in order
 *	 for this to work!
 *
 * @param string The string which is written into the stream
 * @param encoding The encoding in which the string should be written to the
 *		   stream
 * @param runLoopMode The run loop mode in which to perform the async write
 */
- (void)asyncWriteString: (OFString *)string
		encoding: (OFStringEncoding)encoding
	     runLoopMode: (OFRunLoopMode)runLoopMode;

# ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously writes data into the stream.
 *
 * @note The stream must conform to @ref OFReadyForWritingObserving in order
 *	 for this to work!
 *
 * @param data The data which is written into the stream
 * @param block The block to call when the data has been written. It should
 *		return the data for the next write with the same callback or
 *		nil if it should not repeat.
 */
- (void)asyncWriteData: (OFData *)data
		 block: (OFStreamAsyncWriteDataBlock)block;

/**
 * @brief Asynchronously writes data into the stream.
 *
 * @note The stream must conform to @ref OFReadyForWritingObserving in order
 *	 for this to work!
 *
 * @param data The data which is written into the stream
 * @param runLoopMode The run loop mode in which to perform the async write
 * @param block The block to call when the data has been written. It should
 *		return the data for the next write with the same callback or
 *		nil if it should not repeat.
 */
- (void)asyncWriteData: (OFData *)data
	   runLoopMode: (OFRunLoopMode)runLoopMode
		 block: (OFStreamAsyncWriteDataBlock)block;

/**
 * @brief Asynchronously writes a string into the stream.
 *
 * @note The stream must conform to @ref OFReadyForWritingObserving in order
 *	 for this to work!
 *
 * @param string The string which is written into the stream
 * @param block The block to call when the string has been written. It should
 *		return the string for the next write with the same callback or
 *		nil if it should not repeat.
 */
- (void)asyncWriteString: (OFString *)string
		   block: (OFStreamAsyncWriteStringBlock)block;

/**
 * @brief Asynchronously writes a string in the specified encoding into the
 *	  stream.
 *
 * @note The stream must conform to @ref OFReadyForWritingObserving in order
 *	 for this to work!
 *
 * @param string The string which is written into the stream
 * @param encoding The encoding in which the string should be written to the
 *		   stream
 * @param block The block to call when the string has been written. It should
 *		return the string for the next write with the same callback or
 *		nil if it should not repeat.
 */
- (void)asyncWriteString: (OFString *)string
		encoding: (OFStringEncoding)encoding
		   block: (OFStreamAsyncWriteStringBlock)block;

/**
 * @brief Asynchronously writes a string in the specified encoding into the
 *	  stream.
 *
 * @note The stream must conform to @ref OFReadyForWritingObserving in order
 *	 for this to work!
 *
 * @param string The string which is written into the stream
 * @param encoding The encoding in which the string should be written to the
 *		   stream
 * @param runLoopMode The run loop mode in which to perform the async write
 * @param block The block to call when the string has been written. It should
 *		return the string for the next write with the same callback or
 *		nil if it should not repeat.
 */
- (void)asyncWriteString: (OFString *)string
		encoding: (OFStringEncoding)encoding
	     runLoopMode: (OFRunLoopMode)runLoopMode
		   block: (OFStreamAsyncWriteStringBlock)block;
# endif
#endif

/**
 * @brief Writes a uint8_t into the stream.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param int8 A uint8_t
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (void)writeInt8: (uint8_t)int8;

/**
 * @brief Writes a uint16_t into the stream, encoded in big endian.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param int16 A uint16_t
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (void)writeBigEndianInt16: (uint16_t)int16;

/**
 * @brief Writes a uint32_t into the stream, encoded in big endian.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param int32 A uint32_t
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (void)writeBigEndianInt32: (uint32_t)int32;

/**
 * @brief Writes a uint64_t into the stream, encoded in big endian.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param int64 A uint64_t
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (void)writeBigEndianInt64: (uint64_t)int64;

/**
 * @brief Writes a float into the stream, encoded in big endian.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param float_ A float
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (void)writeBigEndianFloat: (float)float_;

/**
 * @brief Writes a double into the stream, encoded in big endian.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param double_ A double
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (void)writeBigEndianDouble: (double)double_;

/**
 * @brief Writes a uint16_t into the stream, encoded in little endian.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param int16 A uint16_t
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (void)writeLittleEndianInt16: (uint16_t)int16;

/**
 * @brief Writes a uint32_t into the stream, encoded in little endian.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param int32 A uint32_t
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (void)writeLittleEndianInt32: (uint32_t)int32;

/**
 * @brief Writes a uint64_t into the stream, encoded in little endian.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param int64 A uint64_t
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (void)writeLittleEndianInt64: (uint64_t)int64;

/**
 * @brief Writes a float into the stream, encoded in little endian.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param float_ A float
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (void)writeLittleEndianFloat: (float)float_;

/**
 * @brief Writes a double into the stream, encoded in little endian.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param double_ A double
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (void)writeLittleEndianDouble: (double)double_;

/**
 * @brief Writes OFData into the stream.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param data The OFData to write into the stream
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (void)writeData: (OFData *)data;

/**
 * @brief Writes a string into the stream, without the trailing zero.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param string The string from which the data is written to the stream
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (void)writeString: (OFString *)string;

/**
 * @brief Writes a string into the stream in the specified encoding, without
 *	  the trailing zero.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param string The string from which the data is written to the stream
 * @param encoding The encoding in which to write the string to the stream
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (void)writeString: (OFString *)string encoding: (OFStringEncoding)encoding;

/**
 * @brief Writes a string into the stream with a trailing newline.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param string The string from which the data is written to the stream
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (void)writeLine: (OFString *)string;

/**
 * @brief Writes a string into the stream in the specified encoding with a
 *	  trailing newline.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param string The string from which the data is written to the stream
 * @param encoding The encoding in which to write the string to the stream
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (void)writeLine: (OFString *)string encoding: (OFStringEncoding)encoding;

/**
 * @brief Writes a formatted string into the stream.
 *
 * See printf for the format syntax. As an addition, `%@` is available as
 * format specifier for objects, `%C` for `OFUnichar` and `%S` for
 * `const OFUnichar *`.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param format A string used as format
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 * @throw OFInvalidFormatException The specified format is invalid
 */
- (void)writeFormat: (OFConstantString *)format, ...;

/**
 * @brief Writes a formatted string into the stream.
 *
 * See printf for the format syntax. As an addition, `%@` is available as
 * format specifier for objects, `%C` for `OFUnichar` and `%S` for
 * `const OFUnichar *`.
 *
 * In non-blocking mode, the behavior is the same as @ref writeBuffer:length:.
 *
 * @param format A string used as format
 * @param arguments The arguments used in the format string
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 * @throw OFInvalidFormatException The specified format is invalid
 */
- (void)writeFormat: (OFConstantString *)format arguments: (va_list)arguments;

#ifdef OF_HAVE_SOCKETS
/**
 * @brief Cancels all pending asynchronous requests on the stream.
 */
- (void)cancelAsyncRequests;
#endif

/**
 * @brief "Reverses" a read operation, meaning the bytes from the specified
 *	  buffer will be returned on the next read operation.
 *
 * This is useful for reading into a buffer, parsing the data and then giving
 * back the data which does not need to be processed. This can be used to
 * optimize situations in which the length of the data that needs to be
 * processed is not known before all data has been processed - for example in
 * decompression - in which it would otherwise be necessary to read byte by
 * byte to avoid consuming bytes that need to be parsed by something else -
 * for example the data descriptor in a ZIP archive which immediately follows
 * the compressed data.
 *
 * If the stream is a file, this method does not change any data in the file.
 *
 * If the stream is seekable, a seek operation will discard any data which was
 * unread.
 *
 * @param buffer The buffer to unread
 * @param length The length of the buffer to unread
 */
- (void)unreadFromBuffer: (const void *)buffer length: (size_t)length;

/**
 * @brief Closes the stream.
 *
 * @note If you override this, make sure to call `[super close]`!
 *
 * @throw OFNotOpenException The stream is not open
 */
- (void)close;

/**
 * @brief Performs a lowlevel read.
 *
 * @warning Do not call this directly!
 *
 * @note Override this method with your actual read implementation when
 *	 subclassing!
 *
 * @param buffer The buffer for the data to read
 * @param length The length of the buffer
 * @return The number of bytes read
 * @throw OFReadFailedException Reading failed
 * @throw OFNotOpenException The stream is not open
 */
- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length;

/**
 * @brief Performs a lowlevel write.
 *
 * @warning Do not call this directly!
 *
 * @note Override this method with your actual write implementation when
 *	 subclassing!
 *
 * @param buffer The buffer with the data to write
 * @param length The length of the data to write
 * @return The number of bytes written
 * @throw OFWriteFailedException Writing failed
 * @throw OFNotOpenException The stream is not open
 */
- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length;

/**
 * @brief Returns whether the lowlevel is at the end of the stream.
 *
 * @warning Do not call this directly!
 *
 * @note Override this method with your actual end of stream checking
 *	 implementation when subclassing!
 *
 * @return Whether the lowlevel is at the end of the stream
 */
- (bool)lowlevelIsAtEndOfStream;
@end

OF_ASSUME_NONNULL_END
