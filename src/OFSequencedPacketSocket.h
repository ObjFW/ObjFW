/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFObject.h"
#import "OFKernelEventObserver.h"
#import "OFRunLoop.h"
#import "OFSocket.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFData;
@class OFSequencedPacketSocket;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A block which is called when a packet has been received.
 *
 * @param length The length of the packet
 * @param exception An exception which occurred while receiving or `nil` on
 *		    success
 * @return A bool whether the same block should be used for the next receive
 */
typedef bool (^OFSequencedPacketSocketAsyncReceiveBlock)(size_t length,
    id _Nullable exception);

/**
 * @brief A block which is called when a packet has been sent.
 *
 * @param exception An exception which occurred while reading or `nil` on
 *		    success
 * @return The data to repeat the send with or nil if it should not repeat
 */
typedef OFData *_Nullable (^OFSequencedPacketSocketAsyncSendDataBlock)(
    id _Nullable exception);

/**
 * @brief A block which is called when the socket accepted a connection.
 *
 * @param acceptedSocket The socket which has been accepted
 * @param exception An exception which occurred while accepting the socket or
 *		    `nil` on success
 * @return A bool whether the same block should be used for the next incoming
 *	   connection
 */
typedef bool (^OFSequencedPacketSocketAsyncAcceptBlock)(
    OFSequencedPacketSocket *acceptedSocket, id _Nullable exception);
#endif

/**
 * @protocol OFSequencedPacketSocketDelegate OFSequencedPacketSocket.h \
 *	     ObjFW/OFSequencedPacketSocket.h
 *
 * @brief A delegate for OFSequencedPacketSocket.
 */
@protocol OFSequencedPacketSocketDelegate <OFObject>
@optional
/**
 * @brief This method is called when a packet has been received.
 *
 * @param socket The sequenced packet socket which received a packet
 * @param buffer The buffer the packet has been written to
 * @param length The length of the packet
 * @param exception An exception that occurred while receiving, or nil on
 *		    success
 * @return A bool whether the same block should be used for the next receive
 */
-	  (bool)socket: (OFSequencedPacketSocket *)socket
  didReceiveIntoBuffer: (void *)buffer
		length: (size_t)length
	     exception: (nullable id)exception;

/**
 * @brief This method is called when a packet has been sent.
 *
 * @param socket The sequenced packet socket which sent a packet
 * @param data The data which was sent
 * @param exception An exception that occurred while sending, or nil on success
 * @return The data to repeat the send with or nil if it should not repeat
 */
- (nullable OFData *)socket: (OFSequencedPacketSocket *)socket
		didSendData: (OFData *)data
		  exception: (nullable id)exception;

/**
 * @brief A method which is called when a socket accepted a connection.
 *
 * @param socket The socket which accepted the connection
 * @param acceptedSocket The socket which has been accepted
 * @param exception An exception that occurred while accepting, or nil on
 *		    success
 * @return A bool whether to accept the next incoming connection
 */
-    (bool)socket: (OFSequencedPacketSocket *)socket
  didAcceptSocket: (OFSequencedPacketSocket *)acceptedSocket
	exception: (nullable id)exception;
@end

/**
 * @class OFSequencedPacketSocket OFSequencedPacketSocket.h \
 *	  ObjFW/OFSequencedPacketSocket.h
 *
 * @brief A base class for sequenced packet sockets.
 *
 * @warning Even though the OFCopying protocol is implemented, it does *not*
 *	    return an independent copy of the socket, but instead retains it.
 *	    This is so that the socket can be used as a key for a dictionary,
 *	    so context can be associated with a socket. Using a socket in more
 *	    than one thread at the same time is not thread-safe, even if copy
 *	    was called to create one "instance" for every thread!
 */
@interface OFSequencedPacketSocket: OFObject <OFCopying,
    OFReadyForReadingObserving, OFReadyForWritingObserving>
{
	OFSocketHandle _socket;
#ifdef OF_AMIGAOS
	LONG _socketID;	/* unused, reserved for ABI stability */
	int _family;	/* unused, reserved for ABI stability */
#endif
	bool _canBlock, _listening;
	OFSocketAddress _remoteAddress;
	id _Nullable _delegate;
	OF_RESERVE_IVARS(OFSequencedPacketSocket, 4)
}

/**
 * @brief Whether the socket can block.
 *
 * By default, a socket can block.
 *
 * @throw OFGetOptionFailedException The option could not be retrieved
 * @throw OFSetOptionFailedException The option could not be set
 */
@property (nonatomic) bool canBlock;

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
    id <OFSequencedPacketSocketDelegate> delegate;

/**
 * @brief Returns a new, autoreleased OFSequencedPacketSocket.
 *
 * @return A new, autoreleased OFSequencedPacketSocket
 */
+ (instancetype)socket;

/**
 * @brief Receives a packet and stores it into the specified buffer.
 *
 * If the buffer is too small, the receive operation fails.
 *
 * @param buffer The buffer to write the packet to
 * @param length The length of the buffer
 * @return The length of the received packet
 * @throw OFReadFailedException Receiving failed
 * @throw OFNotOpenException The socket is not open
 */
- (size_t)receiveIntoBuffer: (void *)buffer length: (size_t)length;

/**
 * @brief Asynchronously receives a packet and stores it into the specified
 *	  buffer.
 *
 * If the buffer is too small, the receive operation fails.
 *
 * @param buffer The buffer to write the packet to
 * @param length The length of the buffer
 */
- (void)asyncReceiveIntoBuffer: (void *)buffer length: (size_t)length;

/**
 * @brief Asynchronously receives a packet and stores it into the specified
 *	  buffer.
 *
 * If the buffer is too small, the receive operation fails.
 *
 * @param buffer The buffer to write the packet to
 * @param length The length of the buffer
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      receive
 */
- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
		   runLoopMode: (OFRunLoopMode)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously receives a packet and stores it into the specified
 *	  buffer.
 *
 * If the buffer is too small, the receive operation fails.
 *
 * @param buffer The buffer to write the packet to
 * @param length The length of the buffer
 * @param block The block to call when the packet has been received. If the
 *		block returns true, it will be called again with the same
 *		buffer and maximum length when more packets have been received.
 *		If you want the next method in the queue to handle the packet
 *		received next, you need to return false from the method.
 */
- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
			 block: (OFSequencedPacketSocketAsyncReceiveBlock)block;

/**
 * @brief Asynchronously receives a packet and stores it into the specified
 *	  buffer.
 *
 * If the buffer is too small, the receive operation fails.
 *
 * @param buffer The buffer to write the packet to
 * @param length The length of the buffer
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      receive
 * @param block The block to call when the packet has been received. If the
 *		block returns true, it will be called again with the same
 *		buffer and maximum length when more packets have been received.
 *		If you want the next method in the queue to handle the packet
 *		received next, you need to return false from the method.
 */
- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
		   runLoopMode: (OFRunLoopMode)runLoopMode
			 block: (OFSequencedPacketSocketAsyncReceiveBlock)block;
#endif

/**
 * @brief Sends the specified packet.
 *
 * @param buffer The buffer to send as a packet
 * @param length The length of the buffer
 * @throw OFWriteFailedException Sending failed
 * @throw OFNotOpenException The socket is not open
 */
- (void)sendBuffer: (const void *)buffer length: (size_t)length;

/**
 * @brief Asynchronously sends the specified packet.
 *
 * @param data The data to send as a packet
 */
- (void)asyncSendData: (OFData *)data;

/**
 * @brief Asynchronously sends the specified packet.
 *
 * @param data The data to send as a packet
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      send
 */
- (void)asyncSendData: (OFData *)data runLoopMode: (OFRunLoopMode)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously sends the specified packet.
 *
 * @param data The data to send as a packet
 * @param block The block to call when the packet has been sent. It should
 *		return the data for the next send with the same callback or nil
 *		if it should not repeat.
 */
- (void)asyncSendData: (OFData *)data
		block: (OFSequencedPacketSocketAsyncSendDataBlock)block;

/**
 * @brief Asynchronously sends the specified packet.
 *
 * @param data The data to send as a packet
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      send
 * @param block The block to call when the packet has been sent. It should
 *		return the data for the next send with the same callback or nil
 *		if it should not repeat.
 */
- (void)asyncSendData: (OFData *)data
	  runLoopMode: (OFRunLoopMode)runLoopMode
		block: (OFSequencedPacketSocketAsyncSendDataBlock)block;
#endif

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
 * @return An autoreleased sequenced packet socket for the accepted connection.
 * @throw OFAcceptSocketFailedException Accepting failed
 * @throw OFNotOpenException The socket is not open
 */
- (instancetype)accept;

/**
 * @brief Asynchronously accept an incoming connection.
 */
- (void)asyncAccept;

/**
 * @brief Asynchronously accept an incoming connection.
 *
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      accept
 */
- (void)asyncAcceptWithRunLoopMode: (OFRunLoopMode)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously accept an incoming connection.
 *
 * @param block The block to execute when a new connection has been accepted.
 *		Returns whether the next incoming connection should be accepted
 *		by the specified block as well.
 */
- (void)asyncAcceptWithBlock: (OFSequencedPacketSocketAsyncAcceptBlock)block;

/**
 * @brief Asynchronously accept an incoming connection.
 *
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      accept
 * @param block The block to execute when a new connection has been accepted.
 *		Returns whether the next incoming connection should be accepted
 *		by the specified block as well.
 */
- (void)
    asyncAcceptWithRunLoopMode: (OFRunLoopMode)runLoopMode
			 block: (OFSequencedPacketSocketAsyncAcceptBlock)block;
#endif

/**
 * @brief Cancels all pending asynchronous requests on the socket.
 */
- (void)cancelAsyncRequests;

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

/**
 * @brief Closes the socket so that it can neither receive nor send any more
 *	  datagrams.
 *
 * @throw OFNotOpenException The socket is not open
 */
- (void)close;
@end

OF_ASSUME_NONNULL_END
