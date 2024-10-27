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

#import "OFSequencedPacketSocket.h"
#import "OFRunLoop.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFDictionary OF_GENERIC(KeyType, ObjectType);
@class OFSCTPSocket;
@class OFString;

/**
 * @brief A key for the SCTP message info.
 *
 * Possible values are:
 *
 *   * @ref OFSCTPStreamID
 *   * @ref OFSCTPPPID
 *   * @ref OFSCTPUnordered
 */
typedef OFConstantString *OFSCTPMessageInfoKey;

/**
 * @brief A dictionary mapping keys of type @ref OFSCTPMessageInfoKey to their
 *	  values.
 */
typedef OFDictionary OF_GENERIC(OFSCTPMessageInfoKey, id) *OFSCTPMessageInfo;

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief The SCTP stream ID for which the message was send / received.
 *
 * This is an `uint16_t` wrapped in an @ref OFNumber.
 */
extern const OFSCTPMessageInfoKey OFSCTPStreamID;

/**
 * @brief The Payload Protocol Identifier for the message.
 *
 * This is an `uint32_t` wrapped in an @ref OFNumber.
 */
extern const OFSCTPMessageInfoKey OFSCTPPPID;

/**
 * @brief Whether the message is send / received out of order.
 *
 * Possible values are an @ref OFNumber with either `true` or `false`.
 */
extern const OFSCTPMessageInfoKey OFSCTPUnordered;
#ifdef __cplusplus
}
#endif

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A handler which is called when the socket connected.
 *
 * @param socket The socket which connected
 * @param host The host connected to
 * @param port The port on the host connected to
 * @param exception An exception which occurred while connecting the socket or
 *		    `nil` on success
 */
typedef void (^OFSCTPSocketConnectedHandler)(OFSCTPSocket *socket,
    OFString *host, uint16_t port, id _Nullable exception);

/**
 * @brief A handler which is called when a message has been received.
 *
 * @param socket The SCTP socket which received a message
 * @param buffer The buffer the message has been written to
 * @param length The length of the message
 * @param info Information about the message, see @ref OFSCTPMessageInfo
 * @param exception An exception which occurred while receiving or `nil` on
 *		    success
 * @return A bool whether the same handler should be used for the next receive
 */
typedef bool (^OFSCTPSocketMessageReceivedHandler)(OFSCTPSocket *socket,
    void *buffer, size_t length, OFSCTPMessageInfo _Nullable info,
    id _Nullable exception);

/**
 * @brief A handler which is called when a message has been sent.
 *
 * @param socket The SCTP socket which sent a message
 * @param data The data which was sent
 * @param info Information about the message, see @ref OFSCTPMessageInfo
 * @param exception An exception which occurred while reading or `nil` on
 *		    success
 * @return The data to repeat the send with or nil if it should not repeat
 */
typedef OFData *_Nullable (^OFSCTPSocketDataSentHandler)(OFSCTPSocket *socket,
    OFData *data, OFSCTPMessageInfo _Nullable info, id _Nullable exception);
#endif

/**
 * @protocol OFSCTPSocketDelegate OFSCTPSocket.h ObjFW/ObjFW.h
 *
 * A delegate for OFSCTPSocket.
 */
@protocol OFSCTPSocketDelegate <OFSequencedPacketSocketDelegate>
@optional
/**
 * @brief A method which is called when a socket connected.
 *
 * @param socket The socket which connected
 * @param host The host connected to
 * @param port The port on the host connected to
 * @param exception An exception that occurred while connecting, or nil on
 *		    success
 */
-     (void)socket: (OFSCTPSocket *)socket
  didConnectToHost: (OFString *)host
	      port: (uint16_t)port
	 exception: (nullable id)exception;

/**
 * @brief This method is called when a message has been received.
 *
 * @param socket The SCTP socket which received a message
 * @param buffer The buffer the message has been written to
 * @param length The length of the message
 * @param info Information about the message, see @ref OFSCTPMessageInfo
 * @param exception An exception that occurred while receiving, or nil on
 *		    success
 * @return A bool whether the same handler should be used for the next receive
 */
-	  (bool)socket: (OFSCTPSocket *)socket
  didReceiveIntoBuffer: (void *)buffer
		length: (size_t)length
		  info: (nullable OFSCTPMessageInfo)info
	     exception: (nullable id)exception;

/**
 * @brief This method is called when a message has been sent.
 *
 * @param socket The SCTP socket which sent a message
 * @param data The data which was sent
 * @param info Information about the message, see @ref OFSCTPMessageInfo
 * @param exception An exception that occurred while sending, or nil on success
 * @return The data to repeat the send with or nil if it should not repeat
 */
- (nullable OFData *)socket: (OFSCTPSocket *)socket
		didSendData: (OFData *)data
		       info: (nullable OFSCTPMessageInfo)info
		  exception: (nullable id)exception;
@end

/**
 * @class OFSCTPSocket OFSCTPSocket.h ObjFW/ObjFW.h
 *
 * @brief A class which provides methods to create and use SCTP sockets in
 *	  one-to-one mode.
 *
 * To connect to a server, create a socket and connect it.
 * To create a server, create a socket, bind it and listen on it.
 */
@interface OFSCTPSocket: OFSequencedPacketSocket
{
	OF_RESERVE_IVARS(OFSCTPSocket, 4)
}

/**
 * @brief Whether sending messages can be delayed. Setting this to NO sets
 *        SCTP_NODELAY on the socket.
 *
 * @throw OFGetOptionFailedException The option could not be retrieved
 * @throw OFSetOptionFailedException The option could not be set
 */
@property (nonatomic) bool canDelaySendingMessages;

/**
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFSCTPSocketDelegate> delegate;

/**
 * @brief Connect the OFSCTPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @throw OFConnectIPSocketFailedException Connecting failed
 * @throw OFAlreadyOpenException The socket is already connected or bound
 */
- (void)connectToHost: (OFString *)host port: (uint16_t)port;

/**
 * @brief Asynchronously connect the OFSCTPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 */
- (void)asyncConnectToHost: (OFString *)host port: (uint16_t)port;

/**
 * @brief Asynchronously connect the OFSCTPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @param runLoopMode The run loop mode in which to perform the async connect
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously connect the OFSCTPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @param handler The handler to execute once the connection has been
 *		  established
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
		   handler: (OFSCTPSocketConnectedHandler)handler;

/**
 * @brief Asynchronously connect the OFSCTPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @param runLoopMode The run loop mode in which to perform the async connect
 * @param handler The handler to execute once the connection has been
 *		  established
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode
		   handler: (OFSCTPSocketConnectedHandler)handler;
#endif

/**
 * @brief Bind the socket to the specified host and port.
 *
 * @param host The host to bind to. Use `@"0.0.0.0"` for IPv4 or `@"::"` for
 *	       IPv6 to bind to all.
 * @param port The port to bind to. If the port is 0, an unused port will be
 *	       chosen, which can be obtained using the return value.
 * @return The address the socket was bound to
 * @throw OFBindIPSocketFailedException Binding failed
 * @throw OFAlreadyOpenException The socket is already connected or bound
 */
- (OFSocketAddress)bindToHost: (OFString *)host port: (uint16_t)port;

/**
 * @brief Receives a message for the specified stream ID and stores it into the
 *	  specified buffer.
 *
 * If the buffer is too small, the message is truncated.
 *
 * @param buffer The buffer to write the message to
 * @param length The length of the buffer
 * @param info Information about the message, see @ref OFSCTPMessageInfo
 * @return The length of the received message
 * @throw OFReadFailedException Receiving failed
 * @throw OFNotOpenException The socket is not open
 */
- (size_t)receiveIntoBuffer: (void *)buffer
		     length: (size_t)length
		       info: (__autoreleasing _Nullable OFSCTPMessageInfo
				 *_Nullable)info;

/**
 * @brief Asynchronously receives a message and stores it into the specified
 *	  buffer.
 *
 * If the buffer is too small, the message is truncated.
 *
 * @param buffer The buffer to write the message to
 * @param length The length of the buffer
 */
- (void)asyncReceiveWithInfoIntoBuffer: (void *)buffer
				length: (size_t)length;

/**
 * @brief Asynchronously receives a message and stores it into the specified
 *	  buffer.
 *
 * If the buffer is too small, the message is truncated.
 *
 * @param buffer The buffer to write the message to
 * @param length The length of the buffer
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      receive
 */
- (void)asyncReceiveWithInfoIntoBuffer: (void *)buffer
				length: (size_t)length
			   runLoopMode: (OFRunLoopMode)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously receives a message and stores it into the specified
 *	  buffer.
 *
 * If the buffer is too small, the message is truncated.
 *
 * @param buffer The buffer to write the message to
 * @param length The length of the buffer
 * @param handler The handler to call when the message has been received. If the
 *		  handler returns true, it will be called again with the same
 *		  buffer and maximum length when more messages have been
 *		  received. If you want the next method in the queue to handle
 *		  the message received next, you need to return false from the
 *		  method.
 */
- (void)
    asyncReceiveWithInfoIntoBuffer: (void *)buffer
			    length: (size_t)length
			   handler: (OFSCTPSocketMessageReceivedHandler)handler;

/**
 * @brief Asynchronously receives a message and stores it into the specified
 *	  buffer.
 *
 * If the buffer is too small, the message is truncated.
 *
 * @param buffer The buffer to write the message to
 * @param length The length of the buffer
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      receive
 * @param handler The handler to call when the message has been received. If the
 *		  handler returns true, it will be called again with the same
 *		  buffer and maximum length when more messages have been
 *		  received. If you want the next method in the queue to handle
 *		  the message received next, you need to return false from the
 *		  method.
 */
- (void)
    asyncReceiveWithInfoIntoBuffer: (void *)buffer
			    length: (size_t)length
		       runLoopMode: (OFRunLoopMode)runLoopMode
			   handler: (OFSCTPSocketMessageReceivedHandler)handler;
#endif

/**
 * @brief Sends the specified message on the specified stream.
 *
 * @param buffer The buffer to send as a message
 * @param length The length of the buffer
 * @param info Information about the message, see @ref OFSCTPMessageInfo
 * @throw OFWriteFailedException Sending failed
 * @throw OFNotOpenException The socket is not open
 */
- (void)sendBuffer: (const void *)buffer
	    length: (size_t)length
	      info: (nullable OFSCTPMessageInfo)info;

/**
 * @brief Asynchronously sends the specified message on the specified stream.
 *
 * @param data The data to send as a message
 * @param info Information about the message, see @ref OFSCTPMessageInfo
 */
- (void)asyncSendData: (OFData *)data info: (nullable OFSCTPMessageInfo)info;

/**
 * @brief Asynchronously sends the specified message on the specified stream.
 *
 * @param data The data to send as a message
 * @param info Information about the message, see @ref OFSCTPMessageInfo
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      send
 */
- (void)asyncSendData: (OFData *)data
		 info: (nullable OFSCTPMessageInfo)info
	  runLoopMode: (OFRunLoopMode)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously sends the specified message on the specified stream.
 *
 * @param data The data to send as a message
 * @param info Information about the message, see @ref OFSCTPMessageInfo
 * @param handler The handler to call when the message has been sent. It should
 *		  return the data for the next send with the same callback or
 *		  nil if it should not repeat.
 */
- (void)asyncSendData: (OFData *)data
		 info: (nullable OFSCTPMessageInfo)info
	      handler: (OFSCTPSocketDataSentHandler)handler;

/**
 * @brief Asynchronously sends the specified message on the specified stream.
 *
 * @param data The data to send as a message
 * @param info Information about the message, see @ref OFSCTPMessageInfo
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      send
 * @param handler The handler to call when the message has been sent. It should
 *		  return the data for the next send with the same callback or
 *		  nil if it should not repeat.
 */
- (void)asyncSendData: (OFData *)data
		 info: (nullable OFSCTPMessageInfo)info
	  runLoopMode: (OFRunLoopMode)runLoopMode
	      handler: (OFSCTPSocketDataSentHandler)handler;
#endif
@end

OF_ASSUME_NONNULL_END
