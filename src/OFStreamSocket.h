/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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

#import "OFStream.h"

#import "socket.h"

OF_ASSUME_NONNULL_BEGIN

/*! @file */

@class OFStreamSocket;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief A block which is called when the socket accepted a connection.
 *
 * @param acceptedSocket The socket which has been accepted
 * @param exception An exception which occurred while accepting the socket or
 *		    `nil` on success
 * @return A bool whether the same block should be used for the next incoming
 *	   connection
 */
typedef bool (^of_stream_socket_async_accept_block_t)(
    OFStreamSocket *acceptedSocket, id _Nullable exception);
#endif

/*!
 * @protocol OFStreamSocketDelegate OFStreamSocket.h ObjFW/OFStreamSocket.h
 *
 * A delegate for OFStreamSocket.
 */
@protocol OFStreamSocketDelegate <OFStreamDelegate>
@optional
/*!
 * @brief A method which is called when a socket accepted a connection.
 *
 * @param socket The socket which accepted the connection
 * @param acceptedSocket The socket which has been accepted
 * @param exception An exception that occurred while accepting, or nil on
 *		    success
 * @return A bool whether to accept the next incoming connection
 */
-    (bool)socket: (OFStreamSocket *)socket
  didAcceptSocket: (OFStreamSocket *)acceptedSocket
	exception: (nullable id)exception;
@end

/*!
 * @class OFStreamSocket OFStreamSocket.h ObjFW/OFStreamSocket.h
 *
 * @brief A class which provides methods to create and use stream sockets.
 */
@interface OFStreamSocket: OFStream <OFReadyForReadingObserving,
    OFReadyForWritingObserving>
{
	of_socket_t _socket;
	bool _atEndOfStream, _listening;
	of_socket_address_t _remoteAddress;
	OF_RESERVE_IVARS(4)
}

/*!
 * @brief Whether the socket is a listening socket.
 */
@property (readonly, nonatomic, getter=isListening) bool listening;

/*!
 * @brief The remote address.
 *
 * @note This only works for accepted sockets!
 */
@property (readonly, nonatomic) const of_socket_address_t *remoteAddress;

/*!
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFStreamSocketDelegate> delegate;

/*!
 * @brief Returns a new, autoreleased OFStreamSocket.
 *
 * @return A new, autoreleased OFStreamSocket
 */
+ (instancetype)socket;

/*!
 * @brief Listen on the socket.
 *
 * @param backlog Maximum length for the queue of pending connections.
 */
- (void)listenWithBacklog: (int)backlog;

/*!
 * @brief Listen on the socket.
 */
- (void)listen;

/*!
 * @brief Accept an incoming connection.
 *
 * @return An autoreleased OFStreamSocket for the accepted connection.
 */
- (instancetype)accept;

/*!
 * @brief Asynchronously accept an incoming connection.
 */
- (void)asyncAccept;

/*!
 * @brief Asynchronously accept an incoming connection.
 *
 * @param runLoopMode The run loop mode in which to perform the async accept
 */
- (void)asyncAcceptWithRunLoopMode: (of_run_loop_mode_t)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/*!
 * @brief Asynchronously accept an incoming connection.
 *
 * @param block The block to execute when a new connection has been accepted.
 *		Returns whether the next incoming connection should be accepted
 *		by the specified block as well.
 */
- (void)asyncAcceptWithBlock: (of_stream_socket_async_accept_block_t)block;

/*!
 * @brief Asynchronously accept an incoming connection.
 *
 * @param runLoopMode The run loop mode in which to perform the async accept
 * @param block The block to execute when a new connection has been accepted.
 *		Returns whether the next incoming connection should be accepted
 *		by the specified block as well.
 */
- (void)asyncAcceptWithRunLoopMode: (of_run_loop_mode_t)runLoopMode
			     block: (of_stream_socket_async_accept_block_t)
					block;
#endif
@end

OF_ASSUME_NONNULL_END
