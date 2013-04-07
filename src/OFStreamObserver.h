/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
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

#import "OFObject.h"

#ifdef _WIN32
# include <winsock2.h>
#endif

@class OFStream;
@class OFMutableArray;
@class OFMutableDictionary;
@class OFDataArray;
#ifdef OF_HAVE_THREADS
@class OFMutex;
#endif

/*!
 * @brief A protocol that needs to be implemented by delegates for
 *	  OFStreamObserver.
 */
@protocol OFStreamObserverDelegate <OFObject>
#ifdef OF_HAVE_OPTIONAL_PROTOCOLS
@optional
#endif
/*!
 * @brief This callback is called when a stream did get ready for reading.
 *
 * @note When @ref OFStream::tryReadLine or
 *	 @ref OFStream::tryReadTillDelimiter: has been called on the stream,
 *	 this callback will not be called again until new data has been
 *	 received, even though there is still data in the cache. The reason for
 *	 this is to prevent spinning in a loop when there is an incomplete
 *	 string in the cache. Once the string is complete, the callback will be
 *	 called again if there is data in the cache.
 *
 * @param stream The stream which did become ready for reading
 */
- (void)streamIsReadyForReading: (OFStream*)stream;

/*!
 * @brief This callback is called when a stream did get ready for writing.
 *
 * @param stream The stream which did become ready for writing
 */
- (void)streamIsReadyForWriting: (OFStream*)stream;

/*!
 * @brief This callback is called when an exception occurred on the stream.
 *
 * @param stream The stream on which an exception occurred
 */
- (void)streamDidReceiveException: (OFStream*)stream;
@end

/*!
 * @brief A class that can observe multiple streams at once.
 *
 * @note Currently, Win32 can only observe sockets and not files!
 */
@interface OFStreamObserver: OFObject
{
	OFMutableArray *_readStreams;
	OFMutableArray *_writeStreams;
	__unsafe_unretained OFStream **_FDToStream;
	size_t _maxFD;
	OFMutableArray *_queue;
	OFDataArray *_queueInfo, *_queueFDs;
	id <OFStreamObserverDelegate> _delegate;
	int _cancelFD[2];
#ifdef _WIN32
	struct sockaddr_in _cancelAddr;
#endif
#ifdef OF_HAVE_THREADS
	OFMutex *_mutex;
#endif
}

#ifdef OF_HAVE_PROPERTIES
@property (assign) id <OFStreamObserverDelegate> delegate;
#endif

/*!
 * @brief Creates a new OFStreamObserver.
 *
 * @return A new, autoreleased OFStreamObserver
 */
+ (instancetype)observer;

/*!
 * @brief Returns the delegate for the OFStreamObserver.
 *
 * @return The delegate for the OFStreamObserver
 */
- (id <OFStreamObserverDelegate>)delegate;

/*!
 * @brief Sets the delegate for the OFStreamObserver.
 *
 * @param delegate The delegate for the OFStreamObserver
 */
- (void)setDelegate: (id <OFStreamObserverDelegate>)delegate;

/*!
 * @brief Adds a stream to observe for reading.
 *
 * This is also used to observe a listening socket for incoming connections,
 * which then triggers a read event for the observed stream.
 *
 * It is recommended that the stream you add is set to non-blocking mode.
 *
 * If there is an @ref observe call blocking, it will be canceled. The reason
 * for this is to prevent blocking even though the new added stream is ready.
 *
 * @param stream The stream to observe for reading
 */
- (void)addStreamForReading: (OFStream*)stream;

/*!
 * @brief Adds a stream to observe for writing.
 *
 * It is recommended that the stream you add is set to non-blocking mode.
 *
 * If there is an @ref observe call blocking, it will be canceled. The reason
 * for this is to prevent blocking even though the new added stream is ready.
 *
 * @param stream The stream to observe for writing
 */
- (void)addStreamForWriting: (OFStream*)stream;

/*!
 * @brief Removes a stream to observe for reading.
 *
 * If there is an @ref observe call blocking, it will be canceled. The reason
 * for this is to prevent the removed stream from still being observed.
 *
 * @param stream The stream to remove from observing for reading
 */
- (void)removeStreamForReading: (OFStream*)stream;

/*!
 * @brief Removes a stream to observe for writing.
 *
 * If there is an @ref observe call blocking, it will be canceled. The reason
 * for this is to prevent the removed stream from still being observed.
 *
 * @param stream The stream to remove from observing for writing
 */
- (void)removeStreamForWriting: (OFStream*)stream;

/*!
 * @brief Observes all streams and blocks until an event happens on a stream.
 */
- (void)observe;

/*!
 * @brief Observes all streams until an event happens on a stream or the
 *	  timeout is reached.
 *
 * @param timeout The time to wait for an event, in seconds
 * @return A boolean whether events occurred during the timeinterval
 */
- (bool)observeWithTimeout: (double)timeout;

/*!
 * @brief Cancels the currently blocking observe call.
 *
 * This is automatically done when a new stream is added or removed by another
 * thread, but in some circumstances, it might be desirable for a thread to
 * manually stop the observe running in another thread.
 */
- (void)cancel;

- (void)OF_addFileDescriptorForReading: (int)fd;
- (void)OF_addFileDescriptorForWriting: (int)fd;
- (void)OF_removeFileDescriptorForReading: (int)fd;
- (void)OF_removeFileDescriptorForWriting: (int)fd;
- (void)OF_processQueue;
- (bool)OF_processCache;
@end

@interface OFObject (OFStreamObserverDelegate) <OFStreamObserverDelegate>
@end
