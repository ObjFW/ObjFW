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
# define _WIN32_WINNT 0x0501
# include <windows.h>
#endif

@class OFSocket;
@class OFTCPSocket;
#ifdef OF_HAVE_POLL
@class OFDataArray;
#endif
@class OFMutableDictionary;

/**
 * \brief A protocol that needs to be implemented by delegates for
 *	  OFSocketObserver.
 */
@protocol OFSocketObserverDelegate
/*
 * This callback is called when a listening socket got a new incoming
 * connection.
 *
 * \param sock The socket which did receive an incoming connection
 */
- (void)socketDidReceiveIncomingConnection: (OFTCPSocket*)sock;

/**
 * This callback is called when a socket did get ready for reading.
 *
 * \param sock The socket which did become ready for reading
 */
- (void)socketDidBecomeReadyForReading: (OFSocket*)sock;

/**
 * This callback is called when a socket did get ready for writing.
 *
 * \param sock The socket which did become ready for writing
 */
- (void)socketDidBecomeReadyForWriting: (OFSocket*)sock;
@end

/**
 * \brief A class that can observe multiple sockets at once.
 */
@interface OFSocketObserver: OFObject
{
	OFObject <OFSocketObserverDelegate> *delegate;
#ifdef OF_HAVE_POLL
	OFDataArray *fds;
#else
	fd_set readfds;
	fd_set writefds;
	int nfds;
#endif
	OFMutableDictionary *fdToSocket;
}

#ifdef OF_HAVE_PROPERTIES
@property (retain) OFObject <OFSocketObserverDelegate> *delegate;
#endif

/**
 * \return A new, autoreleased OFSocketObserver
 */
+ socketObserver;

/**
 * \return The delegate for the OFSocketObserver
 */
- (OFObject <OFSocketObserverDelegate>*)delegate;

/**
 * Sets the delegate for the OFSocketObserver.
 *
 * \param delegate The delegate for the OFSocketObserver
 */
- (void)setDelegate: (OFObject <OFSocketObserverDelegate>*)delegate;

/**
 * Adds a socket to observe for incoming connections.
 *
 * \param sock The socket to observe for incoming connections
 */
- (void)addSocketToObserveForIncomingConnections: (OFTCPSocket*)sock;

/**
 * Adds a socket to observe for reading.
 *
 * \param sock The socket to observe for reading
 */
- (void)addSocketToObserveForReading: (OFSocket*)sock;

/**
 * Adds a socket to observe for writing.
 *
 * \param sock The socket to observe for writing
 */
- (void)addSocketToObserveForWriting: (OFSocket*)sock;

/**
 * Removes a socket to observe for incoming connections.
 *
 * \param sock The socket to remove from observing for incoming connections
 */
- (void)removeSocketToObserveForIncomingConnections: (OFTCPSocket*)sock;

/**
 * Removes a socket to observe for reading.
 *
 * \param sock The socket to remove from observing for reading
 */
- (void)removeSocketToObserveForReading: (OFSocket*)sock;

/**
 * Removes a socket to observe for writing.
 *
 * \param sock The socket to remove from observing for writing
 */
- (void)removeSocketToObserveForWriting: (OFSocket*)sock;

/**
 * Observes all sockets and blocks until an event happens on a socket.
 */
- (void)observe;

/**
 * Observes all sockets until an event happens on a socket or the timeout is
 * reached.
 *
 * \param timeout The time to wait for an event, in milliseconds
 * \return A boolean whether events occurred during the timeinterval
 */
- (BOOL)observeWithTimeout: (int)timeout;
@end

@interface OFObject (OFSocketObserverDelegate) <OFSocketObserverDelegate>
@end
