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

@class OFSocket;
@class OFDataArray;
@class OFMutableDictionary;

/**
 * \brief A protocol that needs to be implemented by delegates for
 *	  OFSocketObserver.
 */
@protocol OFSocketObserverDelegate
/**
 * This callback is called when a socket did get ready for reading.
 *
 * This callback is also called when a listening socket got a new incoming
 * connection.
 *
 * \param sock The socket which did get ready for reading
 */
- (void)socketDidGetReadyForReading: (OFSocket*)sock;

/**
 * This callback is called when a socket did get ready for writing.
 *
 * \param sock The socket which did get ready for writing
 */
- (void)socketDidGetReadyForWriting: (OFSocket*)sock;
@end

/**
 * \brief A class that can observe multiple sockets at once.
 */
@interface OFSocketObserver: OFObject
{
	OFObject <OFSocketObserverDelegate> *delegate;
	OFDataArray *fds;
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
 *
 * \return The number of sockets that have pending events
 */
- (int)observe;

/**
 * Observes all sockets until an event happens on a socket or the timeout is
 * reached.
 *
 * \return The number of sockets that have pending events
 */
- (int)observeWithTimeout: (int)timeout;
@end

@interface OFObject (OFSocketObserverDelegate) <OFSocketObserverDelegate>
@end
