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

#import "OFObject.h"
#import "OFKernelEventObserver.h"
#import "OFRunLoop.h"
#import "OFSocket.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFData;
@class OFDatagramSocket;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A block which is called when a packet has been received.
 *
 * @deprecated Use @ref OFDatagramSocketPacketReceivedHandler instead.
 *
 * @param length The length of the packet
 * @param sender The address of the sender of the packet
 * @param exception An exception which occurred while receiving or `nil` on
 *		    success
 * @return A bool whether the same block should be used for the next receive
 */
typedef bool (^OFDatagramSocketAsyncReceiveBlock)(size_t length,
    const OFSocketAddress *_Nonnull sender, id _Nullable exception)
    OF_DEPRECATED(ObjFW, 1, 2,
	"Use OFDatagramSocketPacketReceivedHandler instead");

/**
 * @brief A handler which is called when a packet has been received.
 *
 * @param socket The socket that received a packet
 * @param buffer The buffer the packet was stored in
 * @param length The length of the packet
 * @param sender The address of the sender of the packet
 * @param exception An exception which occurred while receiving or `nil` on
 *		    success
 * @return A bool whether the same handler should be used for the next receive
 */
typedef bool (^OFDatagramSocketPacketReceivedHandler)(OFDatagramSocket *socket,
    void *buffer, size_t length, const OFSocketAddress *_Nonnull sender,
    id _Nullable exception);

/**
 * @brief A block which is called when a packet has been sent.
 *
 * @deprecated Use @ref OFDatagramSocketDataSentHandler instead.
 *
 * @param exception An exception which occurred while reading or `nil` on
 *		    success
 * @return The data to repeat the send with or nil if it should not repeat
 */
typedef OFData *_Nullable (^OFDatagramSocketAsyncSendDataBlock)(
    id _Nullable exception)
    OF_DEPRECATED(ObjFW, 1, 2,
	"Use OFDatagramSocketDataSentHandler instead");

/**
 * @brief A handler which is called when a packet has been sent.
 *
 * @param socket The datagram socket which sent a packet
 * @param data The data which was sent
 * @param receiver The receiver for the packet
 * @param exception An exception which occurred while reading or `nil` on
 *		    success
 * @return The data to repeat the send with or nil if it should not repeat
 */
typedef OFData *_Nullable (^OFDatagramSocketDataSentHandler)(
    OFDatagramSocket *socket, OFData *data,
    const OFSocketAddress *_Nonnull receiver, id _Nullable exception);
#endif

/**
 * @protocol OFDatagramSocketDelegate OFDatagramSocket.h ObjFW/ObjFW.h
 *
 * @brief A delegate for OFDatagramSocket.
 */
@protocol OFDatagramSocketDelegate <OFObject>
@optional
/**
 * @brief This method is called when a packet has been received.
 *
 * @param socket The datagram socket which received a packet
 * @param buffer The buffer the packet has been written to
 * @param length The length of the packet
 * @param sender The address of the sender of the packet
 * @param exception An exception that occurred while receiving, or nil on
 *		    success
 * @return A bool whether the same handler should be used for the next receive
 */
-	  (bool)socket: (OFDatagramSocket *)socket
  didReceiveIntoBuffer: (void *)buffer
		length: (size_t)length
		sender: (const OFSocketAddress *_Nonnull)sender
	     exception: (nullable id)exception;

/**
 * @brief This method is called when a packet has been sent.
 *
 * @param socket The datagram socket which sent a packet
 * @param data The data which was sent
 * @param receiver The receiver for the packet
 * @param exception An exception that occurred while sending, or nil on success
 * @return The data to repeat the send with or nil if it should not repeat
 */
- (nullable OFData *)socket: (OFDatagramSocket *)socket
		didSendData: (OFData *)data
		   receiver: (const OFSocketAddress *_Nonnull)receiver
		  exception: (nullable id)exception;
@end

/**
 * @class OFDatagramSocket OFDatagramSocket.h ObjFW/ObjFW.h
 *
 * @brief A base class for datagram sockets.
 *
 * @warning Even though the OFCopying protocol is implemented, it does *not*
 *	    return an independent copy of the socket, but instead retains it.
 *	    This is so that the socket can be used as a key for a dictionary,
 *	    so context can be associated with a socket. Using a socket in more
 *	    than one thread at the same time is not thread-safe, even if copy
 *	    was called to create one "instance" for every thread!
 */
@interface OFDatagramSocket: OFObject <OFCopying, OFReadyForReadingObserving,
    OFReadyForWritingObserving>
{
	OFSocketHandle _socket;
#ifdef OF_AMIGAOS
	LONG _socketID;
	int _family;	/* unused, reserved for ABI stability */
#endif
	bool _canBlock;
#ifdef OF_WII
	bool _canSendToBroadcastAddresses;
#endif
	id <OFDatagramSocketDelegate> _Nullable _delegate;
	OF_RESERVE_IVARS(OFDatagramSocket, 4)
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
 * @brief Whether the socket can send to broadcast addresses.
 *
 * @throw OFGetOptionFailedException The option could not be retrieved
 * @throw OFSetOptionFailedException The option could not be set
 */
@property (nonatomic) bool canSendToBroadcastAddresses;

/**
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFDatagramSocketDelegate> delegate;

/**
 * @brief Returns a new, autoreleased OFDatagramSocket.
 *
 * @return A new, autoreleased OFDatagramSocket
 */
+ (instancetype)socket;

/**
 * @brief Receives a datagram and stores it into the specified buffer.
 *
 * If the buffer is too small, the datagram is truncated.
 *
 * @param buffer The buffer to write the datagram to
 * @param length The length of the buffer
 * @param sender A pointer to an @ref OFSocketAddress, which will be set to the
 *		 address of the sender
 * @return The length of the received datagram
 * @throw OFReadFailedException Receiving failed
 * @throw OFNotOpenException The socket is not open
 */
- (size_t)receiveIntoBuffer: (void *)buffer
		     length: (size_t)length
		     sender: (nullable OFSocketAddress *)sender;

/**
 * @brief Asynchronously receives a datagram and stores it into the specified
 *	  buffer.
 *
 * If the buffer is too small, the datagram is truncated.
 *
 * @param buffer The buffer to write the datagram to
 * @param length The length of the buffer
 */
- (void)asyncReceiveIntoBuffer: (void *)buffer length: (size_t)length;

/**
 * @brief Asynchronously receives a datagram and stores it into the specified
 *	  buffer.
 *
 * If the buffer is too small, the datagram is truncated.
 *
 * @param buffer The buffer to write the datagram to
 * @param length The length of the buffer
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      receive
 */
- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
		   runLoopMode: (OFRunLoopMode)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously receives a datagram and stores it into the specified
 *	  buffer.
 *
 * @deprecated Use @ref asyncReceiveIntoBuffer:length:handler: instead.
 *
 * If the buffer is too small, the datagram is truncated.
 *
 * @param buffer The buffer to write the datagram to
 * @param length The length of the buffer
 * @param block The block to call when the datagram has been received. If the
 *		block returns true, it will be called again with the same
 *		buffer and maximum length when more datagrams have been
 *		received. If you want the next method in the queue to handle
 *		the datagram received next, you need to return false from the
 *		method.
 */
- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
			 block: (OFDatagramSocketAsyncReceiveBlock)block
    OF_DEPRECATED(ObjFW, 1, 2,
	"Use -[asyncReceiveIntoBuffer:length:handler:] instead");

/**
 * @brief Asynchronously receives a datagram and stores it into the specified
 *	  buffer.
 *
 * If the buffer is too small, the datagram is truncated.
 *
 * @param buffer The buffer to write the datagram to
 * @param length The length of the buffer
 * @param handler The handler to call when the datagram has been received. If
 *		  the handler returns true, it will be called again with the
 *		  same buffer and maximum length when more datagrams have been
 *		  received. If you want the next method in the queue to handle
 *		  the datagram received next, you need to return false from the
 *		  method.
 */
- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
		       handler: (OFDatagramSocketPacketReceivedHandler)handler;

/**
 * @brief Asynchronously receives a datagram and stores it into the specified
 *	  buffer.
 *
 * @deprecated Use @ref asyncReceiveIntoBuffer:length:runLoopMode:handler:
 *	       instead.
 *
 * If the buffer is too small, the datagram is truncated.
 *
 * @param buffer The buffer to write the datagram to
 * @param length The length of the buffer
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      receive
 * @param block The block to call when the datagram has been received. If the
 *		block returns true, it will be called again with the same
 *		buffer and maximum length when more datagrams have been
 *		received. If you want the next method in the queue to handle
 *		the datagram received next, you need to return false from the
 *		method.
 */
- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
		   runLoopMode: (OFRunLoopMode)runLoopMode
			 block: (OFDatagramSocketAsyncReceiveBlock)block
    OF_DEPRECATED(ObjFW, 1, 2,
	"Use -[asyncReceiveIntoBuffer:length:runLoopMode:handler:] instead");

/**
 * @brief Asynchronously receives a datagram and stores it into the specified
 *	  buffer.
 *
 * If the buffer is too small, the datagram is truncated.
 *
 * @param buffer The buffer to write the datagram to
 * @param length The length of the buffer
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      receive
 * @param handler The handler to call when the datagram has been received. If
 *		the handler returns true, it will be called again with the same
 *		buffer and maximum length when more datagrams have been
 *		received. If you want the next method in the queue to handle
 *		the datagram received next, you need to return false from the
 *		method.
 */
- (void)asyncReceiveIntoBuffer: (void *)buffer
			length: (size_t)length
		   runLoopMode: (OFRunLoopMode)runLoopMode
		       handler: (OFDatagramSocketPacketReceivedHandler)handler;
#endif

/**
 * @brief Sends the specified datagram to the specified address.
 *
 * @param buffer The buffer to send as a datagram
 * @param length The length of the buffer
 * @param receiver A pointer to an @ref OFSocketAddress to which the datagram
 *		   should be sent
 * @throw OFWriteFailedException Sending failed
 * @throw OFNotOpenException The socket is not open
 */
- (void)sendBuffer: (const void *)buffer
	    length: (size_t)length
	  receiver: (const OFSocketAddress *)receiver;

/**
 * @brief Asynchronously sends the specified datagram to the specified address.
 *
 * @param data The data to send as a datagram
 * @param receiver A pointer to an @ref OFSocketAddress to which the datagram
 *		   should be sent. The receiver is copied.
 */
- (void)asyncSendData: (OFData *)data
	     receiver: (const OFSocketAddress *)receiver;

/**
 * @brief Asynchronously sends the specified datagram to the specified address.
 *
 * @param data The data to send as a datagram
 * @param receiver A pointer to an @ref OFSocketAddress to which the datagram
 *		   should be sent. The receiver is copied.
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      send
 */
- (void)asyncSendData: (OFData *)data
	     receiver: (const OFSocketAddress *)receiver
	  runLoopMode: (OFRunLoopMode)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously sends the specified datagram to the specified address.
 *
 * @deprecated Use @ref asyncSendData:receiver:handler: instead.
 *
 * @param data The data to send as a datagram
 * @param receiver A pointer to an @ref OFSocketAddress to which the datagram
 *		   should be sent. The receiver is copied.
 * @param block The block to call when the packet has been sent. It should
 *		return the data for the next send with the same callback or nil
 *		if it should not repeat.
 */
- (void)asyncSendData: (OFData *)data
	     receiver: (const OFSocketAddress *)receiver
		block: (OFDatagramSocketAsyncSendDataBlock)block
    OF_DEPRECATED(ObjFW, 1, 2,
	"Use -[asyncSendData:receiver:handler:] instead");

/**
 * @brief Asynchronously sends the specified datagram to the specified address.
 *
 * @param data The data to send as a datagram
 * @param receiver A pointer to an @ref OFSocketAddress to which the datagram
 *		   should be sent. The receiver is copied.
 * @param handler The handler to call when the packet has been sent. It should
 *		  return the data for the next send with the same callback or
 *		  `nil` if it should not repeat.
 */
- (void)asyncSendData: (OFData *)data
	     receiver: (const OFSocketAddress *)receiver
	      handler: (OFDatagramSocketDataSentHandler)handler;

/**
 * @brief Asynchronously sends the specified datagram to the specified address.
 *
 * @deprecated Use @ref asyncSendData:receiver:runLoopMode:handler: instead.
 *
 * @param data The data to send as a datagram
 * @param receiver A pointer to an @ref OFSocketAddress to which the datagram
 *		   should be sent. The receiver is copied.
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      send
 * @param block The block to call when the packet has been sent. It should
 *		return the data for the next send with the same callback or nil
 *		if it should not repeat.
 */
- (void)asyncSendData: (OFData *)data
	     receiver: (const OFSocketAddress *)receiver
	  runLoopMode: (OFRunLoopMode)runLoopMode
		block: (OFDatagramSocketAsyncSendDataBlock)block
    OF_DEPRECATED(ObjFW, 1, 2,
	"Use -[asyncSendData:receiver:runLoopMode:handler:] instead");

/**
 * @brief Asynchronously sends the specified datagram to the specified address.
 *
 * @param data The data to send as a datagram
 * @param receiver A pointer to an @ref OFSocketAddress to which the datagram
 *		   should be sent. The receiver is copied.
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      send
 * @param handler The handler to call when the packet has been sent. It should
 *		  return the data for the next send with the same callback or
 *		  `nil` if it should not repeat.
 */
- (void)asyncSendData: (OFData *)data
	     receiver: (const OFSocketAddress *)receiver
	  runLoopMode: (OFRunLoopMode)runLoopMode
	      handler: (OFDatagramSocketDataSentHandler)handler;
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

/**
 * @brief Cancels all pending asynchronous requests on the socket.
 */
- (void)cancelAsyncRequests;

/**
 * @brief Closes the socket so that it can neither receive nor send any more
 *	  datagrams.
 *
 * @throw OFNotOpenException The socket is not open
 */
- (void)close;
@end

OF_ASSUME_NONNULL_END
