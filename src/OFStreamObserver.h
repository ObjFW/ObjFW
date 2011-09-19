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

#import "OFObject.h"

#ifdef _WIN32
# ifndef _WIN32_WINNT
#  define _WIN32_WINNT 0x0501
# endif
# include <windows.h>
# include <ws2tcpip.h>
#endif

@class OFStream;
@class OFMutableArray;
@class OFMutableDictionary;

/**
 * \brief A protocol that needs to be implemented by delegates for
 *	  OFStreamObserver.
 */
#ifndef OF_STREAM_OBSERVER_M
@protocol OFStreamObserverDelegate <OFObject>
#else
@protocol OFStreamObserverDelegate
#endif
#ifdef OF_HAVE_OPTIONAL_PROTOCOLS
@optional
#endif
/**
 * \brief This callback is called when a stream did get ready for reading.
 *
 * \param stream The stream which did become ready for reading
 */
- (void)streamDidBecomeReadyForReading: (OFStream*)stream;

/**
 * \brief This callback is called when a stream did get ready for writing.
 *
 * \param stream The stream which did become ready for writing
 */
- (void)streamDidBecomeReadyForWriting: (OFStream*)stream;

/**
 * \brief This callback is called when an exception occurred on the stream.
 *
 * \param stream The stream on which an exception occurred
 */
- (void)streamDidReceiveException: (OFStream*)stream;
@end

/**
 * \brief A class that can observe multiple streams at once.
 *
 * Note: Currently, Win32 can only observe sockets and not files!
 */
@interface OFStreamObserver: OFObject
{
	OFMutableArray *readStreams;
	OFMutableArray *writeStreams;
	OFStream **FDToStream;
	size_t maxFD;
	OFMutableArray *queue, *queueInfo;
	id <OFStreamObserverDelegate> delegate;
	int cancelFD[2];
#ifdef _WIN32
	struct sockaddr_in cancelAddr;
#endif
}

#ifdef OF_HAVE_PROPERTIES
@property (retain) id <OFStreamObserverDelegate> delegate;
#endif

/**
 * \brief Creates a new OFStreamObserver.
 *
 * \return A new, autoreleased OFStreamObserver
 */
+ observer;

/**
 * \brief Returns the delegate for the OFStreamObserver.
 *
 * \return The delegate for the OFStreamObserver
 */
- (id <OFStreamObserverDelegate>)delegate;

/**
 * \brief Sets the delegate for the OFStreamObserver.
 *
 * \param delegate The delegate for the OFStreamObserver
 */
- (void)setDelegate: (id <OFStreamObserverDelegate>)delegate;

/**
 * \brief Adds a stream to observe for reading.
 *
 * This is also used to observe a listening socket for incoming connections,
 * which then triggers a read event for the observed stream.
 *
 * It is recommended that the stream you add is set to non-blocking mode.
 *
 * If there is an -[observe] call blocking, it will be canceled. The reason for
 * this is to prevent blocking even though the new added stream is ready.
 *
 * \param stream The stream to observe for reading
 */
- (void)addStreamToObserveForReading: (OFStream*)stream;

/**
 * \brief Adds a stream to observe for writing.
 *
 * It is recommended that the stream you add is set to non-blocking mode.
 *
 * If there is an -[observe] call blocking, it will be canceled. The reason for
 * this is to prevent blocking even though the new added stream is ready.
 *
 * \param stream The stream to observe for writing
 */
- (void)addStreamToObserveForWriting: (OFStream*)stream;

/**
 * \brief Removes a stream to observe for reading.
 *
 * If there is an -[observe] call blocking, it will be canceled. The reason for
 * this is to prevent the removed stream from still being observed.
 *
 * \param stream The stream to remove from observing for reading
 */
- (void)removeStreamToObserveForReading: (OFStream*)stream;

/**
 * \brief Removes a stream to observe for writing.
 *
 * If there is an -[observe] call blocking, it will be canceled. The reason for
 * this is to prevent the removed stream from still being observed.
 *
 * \param stream The stream to remove from observing for writing
 */
- (void)removeStreamToObserveForWriting: (OFStream*)stream;

/**
 * \brief Observes all streams and blocks until an event happens on a stream.
 */
- (void)observe;

/**
 * \brief Observes all streams until an event happens on a stream or the
 *	  timeout is reached.
 *
 * \param timeout The time to wait for an event, in milliseconds
 * \return A boolean whether events occurred during the timeinterval
 */
- (BOOL)observeWithTimeout: (int)timeout;

/// \cond internal
- (void)_processQueue;
- (BOOL)_processCache;
/// \endcond
@end

@interface OFObject (OFStreamObserverDelegate) <OFStreamObserverDelegate>
@end
