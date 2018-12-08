/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
 *   Jonathan Schleifer <js@heap.zone>
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

/*! @file */

@class OFStream;
@class OFData;

#if defined(OF_HAVE_SOCKETS) && defined(OF_HAVE_BLOCKS)
/*!
 * @brief A block which is called when data was read asynchronously from a
 *	  stream.
 *
 * @param stream The stream on which data was read
 * @param buffer A buffer with the data that has been read
 * @param length The length of the data that has been read
 * @param exception An exception which occurred while reading or `nil` on
 *		    success
 * @return A bool whether the same block should be used for the next read
 */
typedef bool (^of_stream_async_read_block_t)(OF_KINDOF(OFStream *) stream,
    void *buffer, size_t length, id _Nullable exception);

/*!
 * @brief A block which is called when a line was read asynchronously from a
 *	  stream.
 *
 * @param stream The stream on which a line was read
 * @param line The line which has been read or `nil` when the end of stream
 *	       occurred
 * @param exception An exception which occurred while reading or `nil` on
 *		    success
 * @return A bool whether the same block should be used for the next read
 */
typedef bool (^of_stream_async_read_line_block_t)(OF_KINDOF(OFStream *) stream,
    OFString *_Nullable line, id _Nullable exception);

/*!
 * @brief A block which is called when data was written asynchronously to a
 *	  stream.
 *
 * @param stream The stream to which data was written
 * @param buffer A pointer to the buffer which was written to the stream. This
 *		 can be changed to point to a different buffer to be used on the
 *		 next write.
 * @param bytesWritten The number of bytes which have been written. This
 *		       matches the length specified on the asynchronous write
 *		       if no exception was encountered.
 * @param exception An exception which occurred while writing or `nil` on
 *		    success
 * @return The length to repeat the write with or 0 if it should not repeat.
 *	   The buffer may be changed, so that every time a new buffer and length
 *	   can be specified
 */
typedef size_t (^of_stream_async_write_block_t)(OF_KINDOF(OFStream *) stream,
    const void *_Nonnull *_Nonnull buffer, size_t bytesWritten,
    id _Nullable exception);
#endif

/*!
 * @protocol OFStreamDelegate OFStream.h ObjFW/OFStream.h
 *
 * A delegate for OFStream.
 */
@protocol OFStreamDelegate <OFObject>
@optional
/*!
 * @brief This method is called when data was read asynchronously from a
 *	  stream.
 *
 * @param stream The stream on which data was read
 * @param buffer A buffer with the data that has been read
 * @param length The length of the data that has been read
 * @return A bool whether the read should be repeated
 */
-      (bool)stream: (OF_KINDOF(OFStream *))stream
  didReadIntoBuffer: (void *)buffer
	     length: (size_t)length;

/*!
 * @brief This method is called when a line was read asynchronously from a
 *	  stream.
 *
 * @param stream The stream on which a line was read
 * @param line The line which has been read or `nil` when the end of stream
 *	       occurred
 * @return A bool whether the read should be repeated
 */
- (bool)stream: (OF_KINDOF(OFStream *))stream
   didReadLine: (nullable OFString *)line;

/*!
 * @brief This method is called when data was written asynchronously to a
 *	  stream.
 *
 * @param stream The stream to which data was written
 * @param buffer A pointer to the buffer which was written to the stream. This
 *		 can be changed to point to a different buffer to be used on the
 *		 next write.
 * @param length The length of the buffer that has been written
 * @return The length to repeat the write with or 0 if it should not repeat.
 *	   The buffer may be changed, so that every time a new buffer and
 *	   length can be specified
 */
- (size_t)stream: (OF_KINDOF(OFStream *))stream
  didWriteBuffer: (const void *_Nonnull *_Nonnull)buffer
	  length: (size_t)length;

/*!
 * @brief This method is called when an exception occurred during an
 *	  asynchronous read on a stream.
 *
 * @param stream The stream for which an exception occurred
 * @param exception The exception which occurred for the stream
 */
-		(void)stream: (OF_KINDOF(OFStream *))stream
  didFailToReadWithException: (id)exception;

/*!
 * @brief This method is called when an exception occurred during an
 *	  asynchronous write on a stream.
 *
 * @param stream The stream for which an exception occurred
 * @param exception The exception which occurred for the stream
 */
-		 (void)stream: (OF_KINDOF(OFStream *))stream
  didFailToWriteWithException: (id)exception;
@end

/*!
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
#if !defined(OF_SEEKABLE_STREAM_M) && !defined(OF_TCP_SOCKET_M)
@private
#endif
	char *_Nullable _readBuffer, *_Nullable _readBufferMemory;
	char *_Nullable _writeBuffer;
	size_t _readBufferLength, _writeBufferLength;
	bool _writeBuffered, _waitingForDelimiter;
@protected
	bool _blocking;
	id _Nullable _delegate;
}

/*!
 * @brief Whether the end of the stream has been reached.
 */
@property (readonly, nonatomic, getter=isAtEndOfStream) bool atEndOfStream;

/*!
 * @brief Whether writes are buffered.
 */
@property (nonatomic, nonatomic, getter=isWriteBuffered) bool writeBuffered;

/*!
 * @brief Whether data is present in the internal read buffer.
 */
@property (readonly, nonatomic) bool hasDataInReadBuffer;

/*!
 * @brief Whether the stream is in blocking mode.
 *
 * By default, a stream is in blocking mode.
 * On Win32, setting this currently only works for sockets!
 */
@property (nonatomic, getter=isBlocking) bool blocking;

/*!
 * @brief The delegate for asynchronous operations on the stream.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still outstanding.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFStreamDelegate> delegate;

/*!
 * @brief Reads *at most* size bytes from the stream into a buffer.
 *
 * On network streams, this might read less than the specified number of bytes.
 * If you want to read exactly the specified number of bytes, use
 * @ref readIntoBuffer:exactLength:. Note that a read can even return 0 bytes -
 * this does not necessarily mean that the stream ended, so you still need to
 * check @ref atEndOfStream.
 *
 * @param buffer The buffer into which the data is read
 * @param length The length of the data that should be read at most.
 *		 The buffer *must* be *at least* this big!
 * @return The number of bytes read
 */
- (size_t)readIntoBuffer: (void *)buffer
		  length: (size_t)length;

/*!
 * @brief Reads exactly the specified length bytes from the stream into a
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
 */
 - (void)readIntoBuffer: (void *)buffer
	    exactLength: (size_t)length;

#ifdef OF_HAVE_SOCKETS
/*!
 * @brief Asynchronously reads *at most* size bytes from the stream into a
 *	  buffer.
 *
 * On network streams, this might read less than the specified number of bytes.
 * If you want to read exactly the specified number of bytes, use
 * @ref asyncReadIntoBuffer:exactLength:target:selector:context:. Note that a
 * read can even return 0 bytes - this does not necessarily mean that the
 * stream ended, so you still need to check @ref atEndOfStream.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 *
 * @param buffer The buffer into which the data is read.
 *		 The buffer must not be freed before the async read completed!
 * @param length The length of the data that should be read at most.
 *		 The buffer *must* be *at least* this big!
 */
- (void)asyncReadIntoBuffer: (void *)buffer
		     length: (size_t)length;

/*!
 * @brief Asynchronously reads *at most* size bytes from the stream into a
 *	  buffer.
 *
 * On network streams, this might read less than the specified number of bytes.
 * If you want to read exactly the specified number of bytes, use
 * @ref asyncReadIntoBuffer:exactLength:target:selector:context:. Note that a
 * read can even return 0 bytes - this does not necessarily mean that the
 * stream ended, so you still need to check @ref atEndOfStream.
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
		runLoopMode: (of_run_loop_mode_t)runLoopMode;

/*!
 * @brief Asynchronously reads exactly the specified length bytes from the
 *	  stream into a buffer.
 *
 * Unlike @ref asyncReadIntoBuffer:length:target:selector:context:, this method
 * does not call the method when less than the specified length has been read -
 * instead, it waits until it got exactly the specified length, the stream has
 * ended or an exception occurred.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 *
 * @param buffer The buffer into which the data is read
 * @param length The length of the data that should be read.
 *		 The buffer *must* be *at least* this big!
 */
- (void)asyncReadIntoBuffer: (void *)buffer
		exactLength: (size_t)length;

/*!
 * @brief Asynchronously reads exactly the specified length bytes from the
 *	  stream into a buffer.
 *
 * Unlike @ref asyncReadIntoBuffer:length:target:selector:context:, this method
 * does not call the method when less than the specified length has been read -
 * instead, it waits until it got exactly the specified length, the stream has
 * ended or an exception occurred.
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
		runLoopMode: (of_run_loop_mode_t)runLoopMode;

# ifdef OF_HAVE_BLOCKS
/*!
 * @brief Asynchronously reads *at most* ref size bytes from the stream into a
 *	  buffer.
 *
 * On network streams, this might read less than the specified number of bytes.
 * If you want to read exactly the specified number of bytes, use
 * @ref asyncReadIntoBuffer:exactLength:block:. Note that a read can even
 * return 0 bytes - this does not necessarily mean that the stream ended, so
 * you still need to check @ref atEndOfStream.
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
		      block: (of_stream_async_read_block_t)block;

/*!
 * @brief Asynchronously reads *at most* ref size bytes from the stream into a
 *	  buffer.
 *
 * On network streams, this might read less than the specified number of bytes.
 * If you want to read exactly the specified number of bytes, use
 * @ref asyncReadIntoBuffer:exactLength:block:. Note that a read can even
 * return 0 bytes - this does not necessarily mean that the stream ended, so
 * you still need to check @ref atEndOfStream.
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
		runLoopMode: (of_run_loop_mode_t)runLoopMode
		      block: (of_stream_async_read_block_t)block;

/*!
 * @brief Asynchronously reads exactly the specified length bytes from the
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
		      block: (of_stream_async_read_block_t)block;

/*!
 * @brief Asynchronously reads exactly the specified length bytes from the
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
		runLoopMode: (of_run_loop_mode_t)runLoopMode
		      block: (of_stream_async_read_block_t)block;
# endif
#endif

/*!
 * @brief Reads a uint8_t from the stream.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A uint8_t from the stream
 */
- (uint8_t)readInt8;

/*!
 * @brief Reads a uint16_t from the stream which is encoded in big endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A uint16_t from the stream in native endianess
 */
- (uint16_t)readBigEndianInt16;

/*!
 * @brief Reads a uint32_t from the stream which is encoded in big endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A uint32_t from the stream in the native endianess
 */
- (uint32_t)readBigEndianInt32;

/*!
 * @brief Reads a uint64_t from the stream which is encoded in big endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A uint64_t from the stream in the native endianess
 */
- (uint64_t)readBigEndianInt64;

/*!
 * @brief Reads a float from the stream which is encoded in big endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A float from the stream in the native endianess
 */
- (float)readBigEndianFloat;

/*!
 * @brief Reads a double from the stream which is encoded in big endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A double from the stream in the native endianess
 */
- (double)readBigEndianDouble;

/*!
 * @brief Reads the specified number of uint16_ts from the stream which are
 *	  encoded in big endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @param buffer A buffer of sufficient size to store the specified number of
 *		 uint16_ts
 * @param count The number of uint16_ts to read
 * @return The number of bytes read
 */
- (size_t)readBigEndianInt16sIntoBuffer: (uint16_t *)buffer
				  count: (size_t)count;

/*!
 * @brief Reads the specified number of uint32_ts from the stream which are
 *	  encoded in big endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @param buffer A buffer of sufficient size to store the specified number of
 *		 uint32_ts
 * @param count The number of uint32_ts to read
 * @return The number of bytes read
 */
- (size_t)readBigEndianInt32sIntoBuffer: (uint32_t *)buffer
				  count: (size_t)count;

/*!
 * @brief Reads the specified number of uint64_ts from the stream which are
 *	  encoded in big endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @param buffer A buffer of sufficient size to store the specified number of
 *		 uint64_ts
 * @param count The number of uint64_ts to read
 * @return The number of bytes read
 */
- (size_t)readBigEndianInt64sIntoBuffer: (uint64_t *)buffer
				  count: (size_t)count;

/*!
 * @brief Reads the specified number of floats from the stream which are encoded
 *	  in big endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @param buffer A buffer of sufficient size to store the specified number of
 *		 floats
 * @param count The number of floats to read
 * @return The number of bytes read
 */
- (size_t)readBigEndianFloatsIntoBuffer: (float *)buffer
				  count: (size_t)count;

/*!
 * @brief Reads the specified number of doubles from the stream which are
 *	  encoded in big endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @param buffer A buffer of sufficient size to store the specified number of
 *		 doubles
 * @param count The number of doubles to read
 * @return The number of bytes read
 */
- (size_t)readBigEndianDoublesIntoBuffer: (double *)buffer
				   count: (size_t)count;

/*!
 * @brief Reads a uint16_t from the stream which is encoded in little endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A uint16_t from the stream in native endianess
 */
- (uint16_t)readLittleEndianInt16;

/*!
 * @brief Reads a uint32_t from the stream which is encoded in little endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A uint32_t from the stream in the native endianess
 */
- (uint32_t)readLittleEndianInt32;

/*!
 * @brief Reads a uint64_t from the stream which is encoded in little endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A uint64_t from the stream in the native endianess
 */
- (uint64_t)readLittleEndianInt64;

/*!
 * @brief Reads a float from the stream which is encoded in little endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A float from the stream in the native endianess
 */
- (float)readLittleEndianFloat;

/*!
 * @brief Reads a double from the stream which is encoded in little endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @return A double from the stream in the native endianess
 */
- (double)readLittleEndianDouble;

/*!
 * @brief Reads the specified number of uint16_ts from the stream which are
 *	  encoded in little endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @param buffer A buffer of sufficient size to store the specified number of
 *		 uint16_ts
 * @param count The number of uint16_ts to read
 * @return The number of bytes read
 */
- (size_t)readLittleEndianInt16sIntoBuffer: (uint16_t *)buffer
				     count: (size_t)count;

/*!
 * @brief Reads the specified number of uint32_ts from the stream which are
 *	  encoded in little endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @param buffer A buffer of sufficient size to store the specified number of
 *		 uint32_ts
 * @param count The number of uint32_ts to read
 * @return The number of bytes read
 */
- (size_t)readLittleEndianInt32sIntoBuffer: (uint32_t *)buffer
				     count: (size_t)count;

/*!
 * @brief Reads the specified number of uint64_ts from the stream which are
 *	  encoded in little endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @param buffer A buffer of sufficient size to store the specified number of
 *		 uint64_ts
 * @param count The number of uint64_ts to read
 * @return The number of bytes read
 */
- (size_t)readLittleEndianInt64sIntoBuffer: (uint64_t *)buffer
				     count: (size_t)count;

/*!
 * @brief Reads the specified number of floats from the stream which are
 *	  encoded in little endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @param buffer A buffer of sufficient size to store the specified number of
 *		 floats
 * @param count The number of floats to read
 * @return The number of bytes read
 */
- (size_t)readLittleEndianFloatsIntoBuffer: (float *)buffer
				     count: (size_t)count;

/*!
 * @brief Reads the specified number of doubles from the stream which are
 *	  encoded in little endian.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @param buffer A buffer of sufficient size to store the specified number of
 *		 doubles
 * @param count The number of doubles to read
 * @return The number of bytes read
 */
- (size_t)readLittleEndianDoublesIntoBuffer: (double *)buffer
				      count: (size_t)count;

/*!
 * @brief Reads the specified number of items with an item size of 1 from the
 *	  stream and returns them as OFData.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @param count The number of items to read
 * @return OFData with count items.
 */
- (OFData *)readDataWithCount: (size_t)count;

/*!
 * @brief Reads the specified number of items with the specified item size from
 *	  the stream and returns them as OFData.
 *
 * @warning Only call this when you know that enough data is available!
 *	    Otherwise you will get an exception!
 *
 * @param itemSize The size of each item
 * @param count The number of items to read
 * @return OFData with count items.
 */
- (OFData *)readDataWithItemSize: (size_t)itemSize
			   count: (size_t)count;

/*!
 * @brief Returns OFData with all the remaining data of the stream.
 *
 * @return OFData with an item size of 1 with all the data of the stream until
 *	   the end of the stream is reached.
 */
- (OFData *)readDataUntilEndOfStream;

/*!
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
 */
- (OFString *)readStringWithLength: (size_t)length;

/*!
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
 */
- (OFString *)readStringWithLength: (size_t)length
			  encoding: (of_string_encoding_t)encoding;

/*!
 * @brief Reads until a newline, `\0` or end of stream occurs.
 *
 * @return The line that was read, autoreleased, or `nil` if the end of the
 *	   stream has been reached.
 */
- (nullable OFString *)readLine;

/*!
 * @brief Reads with the specified encoding until a newline, `\0` or end of
 *	  stream occurs.
 *
 * @param encoding The encoding used by the stream
 * @return The line that was read, autoreleased, or `nil` if the end of the
 *	   stream has been reached.
 */
- (nullable OFString *)readLineWithEncoding: (of_string_encoding_t)encoding;

#ifdef OF_HAVE_SOCKETS
/*!
 * @brief Asynchronously reads until a newline, `\0`, end of stream or an
 *	  exception occurs.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 */
- (void)asyncReadLine;

/*!
 * @brief Asynchronously reads with the specified encoding until a newline,
 *	  `\0`, end of stream or an exception occurs.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 *
 * @param encoding The encoding used by the stream
 */
- (void)asyncReadLineWithEncoding: (of_string_encoding_t)encoding;

/*!
 * @brief Asynchronously reads with the specified encoding until a newline,
 *	  `\0`, end of stream or an exception occurs.
 *
 * @note The stream must conform to @ref OFReadyForReadingObserving in order
 *	 for this to work!
 *
 * @param encoding The encoding used by the stream
 * @param runLoopMode The run loop mode in which to perform the async read
 */
- (void)asyncReadLineWithEncoding: (of_string_encoding_t)encoding
		      runLoopMode: (of_run_loop_mode_t)runLoopMode;

# ifdef OF_HAVE_BLOCKS
/*!
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
- (void)asyncReadLineWithBlock: (of_stream_async_read_line_block_t)block;

/*!
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
- (void)asyncReadLineWithEncoding: (of_string_encoding_t)encoding
			    block: (of_stream_async_read_line_block_t)block;

/*!
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
- (void)asyncReadLineWithEncoding: (of_string_encoding_t)encoding
		      runLoopMode: (of_run_loop_mode_t)runLoopMode
			    block: (of_stream_async_read_line_block_t)block;
# endif
#endif

/*!
 * @brief Tries to read a line from the stream (see @ref readLine) and returns
 *	  `nil` if no complete line has been received yet.
 *
 * @return The line that was read, autoreleased, or `nil` if the line is not
 *	   complete yet
 */
- (nullable OFString *)tryReadLine;

/*!
 * @brief Tries to read a line from the stream with the specified encoding (see
 *	  @ref readLineWithEncoding:) and returns `nil` if no complete line has
 *	  been received yet.
 *
 * @param encoding The encoding used by the stream
 * @return The line that was read, autoreleased, or `nil` if the line is not
 *	   complete yet
 */
- (nullable OFString *)tryReadLineWithEncoding: (of_string_encoding_t)encoding;

/*!
 * @brief Reads until the specified string or `\0` is found or the end of
 *	  stream occurs.
 *
 * @param delimiter The delimiter
 * @return The line that was read, autoreleased, or `nil` if the end of the
 *	   stream has been reached.
 */
- (nullable OFString *)readTillDelimiter: (OFString *)delimiter;

/*!
 * @brief Reads until the specified string or `\0` is found or the end of
 *	  stream occurs.
 *
 * @param delimiter The delimiter
 * @param encoding The encoding used by the stream
 * @return The line that was read, autoreleased, or `nil` if the end of the
 *	   stream has been reached.
 */
- (nullable OFString *)readTillDelimiter: (OFString *)delimiter
				encoding: (of_string_encoding_t)encoding;

/*!
 * @brief Tries to reads until the specified string or `\0` is found or the end
 *	  of stream (see @ref readTillDelimiter:) and returns `nil` if not
 *	  enough data has been received yet.
 *
 * @param delimiter The delimiter
 * @return The line that was read, autoreleased, or `nil` if the end of the
 *	   stream has been reached.
 */
- (nullable OFString *)tryReadTillDelimiter: (OFString *)delimiter;

/*!
 * @brief Tries to read until the specified string or `\0` is found or the end
 *	  of stream occurs (see @ref readTillDelimiter:encoding:) and returns
 *	  `nil` if not enough data has been received yet.
 *
 * @param delimiter The delimiter
 * @param encoding The encoding used by the stream
 * @return The line that was read, autoreleased, or `nil` if the end of the
 *	   stream has been reached.
 */
- (nullable OFString *)tryReadTillDelimiter: (OFString *)delimiter
				   encoding: (of_string_encoding_t)encoding;

/*!
 * @brief Writes everything in the write buffer to the stream.
 */
- (void)flushWriteBuffer;

/*!
 * @brief Writes from a buffer into the stream.
 *
 * @param buffer The buffer from which the data is written into the stream
 * @param length The length of the data that should be written
 * @return The number of bytes written. This can only differ from the specified
 *	   length in non-blocking mode.
 */
- (size_t)writeBuffer: (const void *)buffer
	       length: (size_t)length;

#ifdef OF_HAVE_SOCKETS
/*!
 * @brief Asynchronously writes a buffer into the stream.
 *
 * @note The stream must conform to @ref OFReadyForWritingObserving in order
 *	 for this to work!
 *
 * @param buffer The buffer from which the data is written into the stream. The
 *		 buffer needs to be valid until the write request is completed!
 * @param length The length of the data that should be written
 */
- (void)asyncWriteBuffer: (const void *)buffer
		  length: (size_t)length;

/*!
 * @brief Asynchronously writes a buffer into the stream.
 *
 * @note The stream must conform to @ref OFReadyForWritingObserving in order
 *	 for this to work!
 *
 * @param buffer The buffer from which the data is written into the stream. The
 *		 buffer needs to be valid until the write request is completed!
 * @param length The length of the data that should be written
 * @param runLoopMode The run loop mode in which to perform the async write
 */
- (void)asyncWriteBuffer: (const void *)buffer
		  length: (size_t)length
	     runLoopMode: (of_run_loop_mode_t)runLoopMode;

# ifdef OF_HAVE_BLOCKS
/*!
 * @brief Asynchronously writes a buffer into the stream.
 *
 * @note The stream must conform to @ref OFReadyForWritingObserving in order
 *	 for this to work!
 *
 * @param buffer The buffer from which the data is written into the stream. The
 *		 buffer needs to be valid until the write request is completed!
 * @param length The length of the data that should be written
 * @param block The block to call when the data has been written. It should
 *		return the length for the next write with the same callback or
 *		0 if it should not repeat. The buffer may be changed, so that
 *		every time a new buffer and length can be specified while the
 *		callback stays the same.
 */
- (void)asyncWriteBuffer: (const void *)buffer
		  length: (size_t)length
		   block: (of_stream_async_write_block_t)block;

/*!
 * @brief Asynchronously writes a buffer into the stream.
 *
 * @note The stream must conform to @ref OFReadyForWritingObserving in order
 *	 for this to work!
 *
 * @param buffer The buffer from which the data is written into the stream. The
 *		 buffer needs to be valid until the write request is completed!
 * @param length The length of the data that should be written
 * @param runLoopMode The run loop mode in which to perform the async write
 * @param block The block to call when the data has been written. It should
 *		return the length for the next write with the same callback or
 *		0 if it should not repeat. The buffer may be changed, so that
 *		every time a new buffer and length can be specified while the
 *		callback stays the same.
 */
- (void)asyncWriteBuffer: (const void *)buffer
		  length: (size_t)length
	     runLoopMode: (of_run_loop_mode_t)runLoopMode
		   block: (of_stream_async_write_block_t)block;
# endif
#endif

/*!
 * @brief Writes a uint8_t into the stream.
 *
 * @param int8 A uint8_t
 */
- (void)writeInt8: (uint8_t)int8;

/*!
 * @brief Writes a uint16_t into the stream, encoded in big endian.
 *
 * @param int16 A uint16_t
 */
- (void)writeBigEndianInt16: (uint16_t)int16;

/*!
 * @brief Writes a uint32_t into the stream, encoded in big endian.
 *
 * @param int32 A uint32_t
 */
- (void)writeBigEndianInt32: (uint32_t)int32;

/*!
 * @brief Writes a uint64_t into the stream, encoded in big endian.
 *
 * @param int64 A uint64_t
 */
- (void)writeBigEndianInt64: (uint64_t)int64;

/*!
 * @brief Writes a float into the stream, encoded in big endian.
 *
 * @param float_ A float
 */
- (void)writeBigEndianFloat: (float)float_;

/*!
 * @brief Writes a double into the stream, encoded in big endian.
 *
 * @param double_ A double
 */
- (void)writeBigEndianDouble: (double)double_;

/*!
 * @brief Writes the specified number of uint16_ts into the stream, encoded in
 *	  big endian.
 *
 * @param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * @param count The number of uint16_ts to write
 * @return The number of bytes written to the stream
 */
- (size_t)writeBigEndianInt16s: (const uint16_t *)buffer
			 count: (size_t)count;

/*!
 * @brief Writes the specified number of uint32_ts into the stream, encoded in
 *	  big endian.
 *
 * @param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * @param count The number of uint32_ts to write
 * @return The number of bytes written to the stream
 */
- (size_t)writeBigEndianInt32s: (const uint32_t *)buffer
			 count: (size_t)count;

/*!
 * @brief Writes the specified number of uint64_ts into the stream, encoded in
 *	  big endian.
 *
 * @param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * @param count The number of uint64_ts to write
 * @return The number of bytes written to the stream
 */
- (size_t)writeBigEndianInt64s: (const uint64_t *)buffer
			 count: (size_t)count;

/*!
 * @brief Writes the specified number of floats into the stream, encoded in big
 *	  endian.
 *
 * @param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * @param count The number of floats to write
 * @return The number of bytes written to the stream
 */
- (size_t)writeBigEndianFloats: (const float *)buffer
			 count: (size_t)count;

/*!
 * @brief Writes the specified number of doubles into the stream, encoded in
 *	  big endian.
 *
 * @param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * @param count The number of doubles to write
 * @return The number of bytes written to the stream
 */
- (size_t)writeBigEndianDoubles: (const double *)buffer
			  count: (size_t)count;

/*!
 * @brief Writes a uint16_t into the stream, encoded in little endian.
 *
 * @param int16 A uint16_t
 */
- (void)writeLittleEndianInt16: (uint16_t)int16;

/*!
 * @brief Writes a uint32_t into the stream, encoded in little endian.
 *
 * @param int32 A uint32_t
 */
- (void)writeLittleEndianInt32: (uint32_t)int32;

/*!
 * @brief Writes a uint64_t into the stream, encoded in little endian.
 *
 * @param int64 A uint64_t
 */
- (void)writeLittleEndianInt64: (uint64_t)int64;

/*!
 * @brief Writes a float into the stream, encoded in little endian.
 *
 * @param float_ A float
 */
- (void)writeLittleEndianFloat: (float)float_;

/*!
 * @brief Writes a double into the stream, encoded in little endian.
 *
 * @param double_ A double
 */
- (void)writeLittleEndianDouble: (double)double_;

/*!
 * @brief Writes the specified number of uint16_ts into the stream, encoded in
 *	  little endian.
 *
 * @param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * @param count The number of uint16_ts to write
 * @return The number of bytes written to the stream
 */
- (size_t)writeLittleEndianInt16s: (const uint16_t *)buffer
			    count: (size_t)count;

/*!
 * @brief Writes the specified number of uint32_ts into the stream, encoded in
 *	  little endian.
 *
 * @param count The number of uint32_ts to write
 * @param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * @return The number of bytes written to the stream
 */
- (size_t)writeLittleEndianInt32s: (const uint32_t *)buffer
			    count: (size_t)count;

/*!
 * @brief Writes the specified number of uint64_ts into the stream, encoded in
 *	  little endian.
 *
 * @param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * @param count The number of uint64_ts to write
 * @return The number of bytes written to the stream
 */
- (size_t)writeLittleEndianInt64s: (const uint64_t *)buffer
			    count: (size_t)count;

/*!
 * @brief Writes the specified number of floats into the stream, encoded in
 *	  little endian.
 *
 * @param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * @param count The number of floats to write
 * @return The number of bytes written to the stream
 */
- (size_t)writeLittleEndianFloats: (const float *)buffer
			    count: (size_t)count;

/*!
 * @brief Writes the specified number of doubles into the stream, encoded in
 *	  little endian.
 *
 * @param buffer The buffer from which the data is written to the stream after
 *		 it has been byte swapped if necessary
 * @param count The number of doubles to write
 * @return The number of bytes written to the stream
 */
- (size_t)writeLittleEndianDoubles: (const double *)buffer
			     count: (size_t)count;

/*!
 * @brief Writes OFData into the stream.
 *
 * @param data The OFData to write into the stream
 * @return The number of bytes written
 */
- (size_t)writeData: (OFData *)data;

/*!
 * @brief Writes a string into the stream, without the trailing zero.
 *
 * @param string The string from which the data is written to the stream
 * @return The number of bytes written
 */
- (size_t)writeString: (OFString *)string;

/*!
 * @brief Writes a string into the stream in the specified encoding, without
 *	  the trailing zero.
 *
 * @param string The string from which the data is written to the stream
 * @param encoding The encoding in which to write the string to the stream
 * @return The number of bytes written
 */
- (size_t)writeString: (OFString *)string
	     encoding: (of_string_encoding_t)encoding;

/*!
 * @brief Writes a string into the stream with a trailing newline.
 *
 * @param string The string from which the data is written to the stream
 * @return The number of bytes written
 */
- (size_t)writeLine: (OFString *)string;

/*!
 * @brief Writes a string into the stream in the specified encoding with a
 *	  trailing newline.
 *
 * @param string The string from which the data is written to the stream
 * @param encoding The encoding in which to write the string to the stream
 * @return The number of bytes written
 */
- (size_t)writeLine: (OFString *)string
	   encoding: (of_string_encoding_t)encoding;

/*!
 * @brief Writes a formatted string into the stream.
 *
 * See printf for the format syntax. As an addition, `%@` is available as
 * format specifier for objects, `%C` for `of_unichar_t` and `%S` for
 * `const of_unichar_t *`.
 *
 * @param format A string used as format
 * @return The number of bytes written
 */
- (size_t)writeFormat: (OFConstantString *)format, ...;

/*!
 * @brief Writes a formatted string into the stream.
 *
 * See printf for the format syntax. As an addition, `%@` is available as
 * format specifier for objects, `%C` for `of_unichar_t` and `%S` for
 * `const of_unichar_t *`.
 *
 * @param format A string used as format
 * @param arguments The arguments used in the format string
 * @return The number of bytes written
 */
- (size_t)writeFormat: (OFConstantString *)format
	    arguments: (va_list)arguments;

#ifdef OF_HAVE_SOCKETS
/*!
 * @brief Cancels all pending asynchronous requests on the stream.
 */
- (void)cancelAsyncRequests;
#endif

/*!
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
- (void)unreadFromBuffer: (const void *)buffer
		  length: (size_t)length;

/*!
 * @brief Closes the stream.
 *
 * @note If you override this, make sure to call `[super close]`!
 */
- (void)close;

/*!
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
 */
- (size_t)lowlevelReadIntoBuffer: (void *)buffer
			  length: (size_t)length;

/*!
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
 */
- (size_t)lowlevelWriteBuffer: (const void *)buffer
		       length: (size_t)length;

/*!
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
