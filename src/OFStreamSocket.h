/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import "OFStream.h"
#import "OFSocket.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFStreamSocket;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A block which is called when the socket accepted a connection.
 *
 * @deprecated Use OFStreamSocketAcceptedHandler instead.
 *
 * @param acceptedSocket The socket which has been accepted
 * @param exception An exception which occurred while accepting the socket or
 *		    `nil` on success
 * @return A bool whether the same block should be used for the next incoming
 *	   connection
 */
typedef bool (^OFStreamSocketAsyncAcceptBlock)(OFStreamSocket *acceptedSocket,
    id _Nullable exception)
    OF_DEPRECATED(ObjFW, 1, 2, "Use OFStreamSocketAcceptedHandler instead");

/**
 * @brief A handler which is called when the socket accepted a connection.
 *
 * @param socket The socket which accepted the connection
 * @param acceptedSocket The socket which has been accepted
 * @param exception An exception which occurred while accepting the socket or
 *		    `nil` on success
 * @return A bool whether the same handler should be used for the next incoming
 *	   connection
 */
typedef bool (^OFStreamSocketAcceptedHandler)(OFStreamSocket *socket,
    OFStreamSocket *acceptedSocket, id _Nullable exception);
#endif

/**
 * @protocol OFStreamSocketDelegate OFStreamSocket.h ObjFW/ObjFW.h
 *
 * A delegate for OFStreamSocket.
 */
@protocol OFStreamSocketDelegate <OFStreamDelegate>
@optional
/**
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

/**
 * @class OFStreamSocket OFStreamSocket.h ObjFW/ObjFW.h
 *
 * @brief A class which provides methods to create and use stream sockets.
 */
@interface OFStreamSocket: OFStream <OFReadyForReadingObserving,
    OFReadyForWritingObserving>
{
	OFSocketHandle _socket;
#ifdef OF_AMIGAOS
	LONG _socketID;
	int _family;	/* unused, reserved for ABI stability */
#endif
	bool _atEndOfStream, _listening;
	OFSocketAddress _remoteAddress;
	OF_RESERVE_IVARS(OFStreamSocket, 4)
}

/**
 * @brief Whether the socket is a listening socket.
 */
@property (readonly, nonatomic, getter=isListening) bool listening;

/**
 * @brief The remote address.
 *
 * @note This only works for accepted sockets!
 *
 * @throw OFNotOpenException The socket is not open
 * @throw OFInvalidArgumentException The socket has no remote address
 */
@property (readonly, nonatomic) const OFSocketAddress *remoteAddress;

/**
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFStreamSocketDelegate> delegate;

/**
 * @brief Returns a new, autoreleased OFStreamSocket.
 *
 * @return A new, autoreleased OFStreamSocket
 */
+ (instancetype)socket;

/**
 * @brief Listen on the socket.
 *
 * @param backlog Maximum length for the queue of pending connections.
 * @throw OFListenOnSocketFailedException Listening failed
 * @throw OFNotOpenException The socket is not open
 */
- (void)listenWithBacklog: (int)backlog;

/**
 * @brief Listen on the socket.
 *
 * @throw OFListenOnSocketFailedException Listening failed
 * @throw OFNotOpenException The socket is not open
 */
- (void)listen;

/**
 * @brief Accept an incoming connection.
 *
 * The accepted socket inherits @ref canBlock from the server socket.
 *
 * @return An autoreleased OFStreamSocket for the accepted connection.
 * @throw OFAcceptSocketFailedException Accepting failed
 * @throw OFNotOpenException The socket is not open
 */
- (instancetype)accept;

/**
 * @brief Asynchronously accept an incoming connection.
 *
 * The accepted socket inherits @ref canBlock from the server socket.
 */
- (void)asyncAccept;

/**
 * @brief Asynchronously accept an incoming connection.
 *
 * The accepted socket inherits @ref canBlock from the server socket.
 *
 * @param runLoopMode The run loop mode in which to perform the async accept
 */
- (void)asyncAcceptWithRunLoopMode: (OFRunLoopMode)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously accept an incoming connection.
 *
 * @deprecated Use @ref asyncAcceptWithHandler: instead.
 *
 * @param block The block to execute when a new connection has been accepted.
 *		Returns whether the next incoming connection should be accepted
 *		by the specified block as well.
 */
- (void)asyncAcceptWithBlock: (OFStreamSocketAsyncAcceptBlock)block
    OF_DEPRECATED(ObjFW, 1, 2, "Use -[asyncAcceptWithHandler:] instead");

/**
 * @brief Asynchronously accept an incoming connection.
 *
 * The accepted socket inherits @ref canBlock from the server socket.
 *
 * @param handler The handler to execute when a new connection has been
 *		  accepted. Returns whether the next incoming connection should
 *		  be accepted by the specified handler as well.
 */
- (void)asyncAcceptWithHandler: (OFStreamSocketAcceptedHandler)handler;

/**
 * @brief Asynchronously accept an incoming connection.
 *
 * @deprecated Use @ref asyncAcceptWithRunLoopMode:handler: instead.
 *
 * @param runLoopMode The run loop mode in which to perform the async accept
 * @param block The block to execute when a new connection has been accepted.
 *		Returns whether the next incoming connection should be accepted
 *		by the specified block as well.
 */
- (void)asyncAcceptWithRunLoopMode: (OFRunLoopMode)runLoopMode
			     block: (OFStreamSocketAsyncAcceptBlock)block
    OF_DEPRECATED(ObjFW, 1, 2,
	"Use -[asyncAcceptWithRunLoopMode:handler:] instead");

/**
 * @brief Asynchronously accept an incoming connection.
 *
 * The accepted socket inherits @ref canBlock from the server socket.
 *
 * @param runLoopMode The run loop mode in which to perform the async accept
 * @param handler The handler to execute when a new connection has been
 *		  accepted. Returns whether the next incoming connection
 *		  should be accepted by the specified handler as well.
 */
- (void)asyncAcceptWithRunLoopMode: (OFRunLoopMode)runLoopMode
			   handler: (OFStreamSocketAcceptedHandler)handler;
#endif

/**
 * @brief Releases the socket from the current thread.
 *
 * This is necessary on some platforms in order to allow a different thread to
 * use the socket, e.g. on AmigaOS, but you should call it on all operating
 * systems before using the socket from a different thread.
 *
 * After calling this method, you must no longer use the socket until
 * @ref obtainSocketForCurrentThread has been called.
 */
- (void)releaseSocketFromCurrentThread;

/**
 * @brief Obtains the socket for the current thread.
 *
 * This is necessary on some platforms in order to allow a different thread to
 * use the socket, e.g. on AmigaOS, but you should call it on all operating
 * systems before using the socket from a different thread.
 *
 * You must only call this method after @ref releaseSocketFromCurrentThread has
 * been called from a different thread.
 */
- (void)obtainSocketForCurrentThread;
@end

OF_ASSUME_NONNULL_END
