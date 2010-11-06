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

#if !defined(OF_HAVE_POLL) && defined(OF_HAVE_SYS_SELECT_H)
# include <sys/select.h>
#endif

#import "OFObject.h"

#ifdef _WIN32
# ifndef _WIN32_WINNT
#  define _WIN32_WINNT 0x0501
# endif
# include <windows.h>
#endif

@class OFStream;
#ifdef OF_HAVE_POLL
@class OFDataArray;
#endif
@class OFMutableArray;
@class OFMutableDictionary;

/**
 * \brief A protocol that needs to be implemented by delegates for
 *	  OFStreamObserver.
 */
@protocol OFStreamObserverDelegate

/**
 * This callback is called when a stream did get ready for reading.
 *
 * \param stream The stream which did become ready for reading
 */
- (void)streamDidBecomeReadyForReading: (OFStream*)stream;

/**
 * This callback is called when a stream did get ready for writing.
 *
 * \param stream The stream which did become ready for writing
 */
- (void)streamDidBecomeReadyForWriting: (OFStream*)stream;

/**
 * This callback is called when an exception occurred on the stream.
 *
 * \param stream The stream on which an exception occurred
 */
- (void)streamDidReceiveException: (OFStream*)stream;
@end

/**
 * \brief A class that can observe multiple streams at once.
 *
 * Note: Currently, it can only observe sockets on Win32.
 */
@interface OFStreamObserver: OFObject
{
	OFMutableArray *readStreams;
	OFMutableArray *writeStreams;
	id <OFStreamObserverDelegate> delegate;
#ifdef OF_HAVE_POLL
	OFDataArray *fds;
	OFMutableDictionary *fdToStream;
#else
	fd_set readfds;
	fd_set writefds;
	fd_set exceptfds;
	int nfds;
#endif
}

#ifdef OF_HAVE_PROPERTIES
@property (retain) id <OFStreamObserverDelegate> delegate;
#endif

/**
 * \return A new, autoreleased OFStreamObserver
 */
+ streamObserver;

/**
 * \return The delegate for the OFStreamObserver
 */
- (id <OFStreamObserverDelegate>)delegate;

/**
 * Sets the delegate for the OFStreamObserver.
 *
 * \param delegate The delegate for the OFStreamObserver
 */
- (void)setDelegate: (id <OFStreamObserverDelegate>)delegate;

/**
 * Adds a stream to observe for reading.
 *
 * \param stream The stream to observe for reading
 */
- (void)addStreamToObserveForReading: (OFStream*)stream;

/**
 * Adds a stream to observe for writing.
 *
 * \param stream The stream to observe for writing
 */
- (void)addStreamToObserveForWriting: (OFStream*)stream;

/**
 * Removes a stream to observe for reading.
 *
 * \param stream The stream to remove from observing for reading
 */
- (void)removeStreamToObserveForReading: (OFStream*)stream;

/**
 * Removes a stream to observe for writing.
 *
 * \param stream The stream to remove from observing for writing
 */
- (void)removeStreamToObserveForWriting: (OFStream*)stream;

/**
 * Observes all streams and blocks until an event happens on a stream.
 */
- (void)observe;

/**
 * Observes all streams until an event happens on a stream or the timeout is
 * reached.
 *
 * \param timeout The time to wait for an event, in milliseconds
 * \return A boolean whether events occurred during the timeinterval
 */
- (BOOL)observeWithTimeout: (int)timeout;
@end

@interface OFObject (OFStreamObserverDelegate) <OFStreamObserverDelegate>
@end
