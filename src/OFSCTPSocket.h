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

@class OFSCTPSocket;
@class OFString;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief A block which is called when the socket connected.
 *
 * @param exception An exception which occurred while connecting the socket or
 *		    `nil` on success
 */
typedef void (^OFSCTPSocketAsyncConnectBlock)(id _Nullable exception);

/**
 * @brief A block which is called when a packet has been received.
 *
 * @param length The length of the packet
 * @param streamID The stream ID for the message
 * @param PPID The Payload Protocol Identifier for the message
 * @param exception An exception which occurred while receiving or `nil` on
 *		    success
 * @return A bool whether the same block should be used for the next receive
 */
typedef bool (^OFSCTPSocketAsyncReceiveBlock)(size_t length, uint16_t streamID,
    uint32_t PPID, id _Nullable exception);

/**
 * @brief A block which is called when a packet has been sent.
 *
 * @param exception An exception which occurred while reading or `nil` on
 *		    success
 * @return The data to repeat the send with or nil if it should not repeat
 */
typedef OFData *_Nullable (^OFSCTPSocketAsyncSendDataBlock)(
    id _Nullable exception);
#endif

/**
 * @protocol OFSCTPSocketDelegate OFSCTPSocket.h ObjFW/OFSCTPSocket.h
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
 * @brief This method is called when a packet has been received.
 *
 * @param socket The sequenced packet socket which received a packet
 * @param buffer The buffer the packet has been written to
 * @param length The length of the packet
 * @param streamID The stream ID for the message
 * @param PPID The Payload Protocol Identifier for the message
 * @param exception An exception that occurred while receiving, or nil on
 *		    success
 * @return A bool whether the same block should be used for the next receive
 */
-	  (bool)socket: (OFSCTPSocket *)socket
  didReceiveIntoBuffer: (void *)buffer
		length: (size_t)length
	      streamID: (uint16_t)streamID
		  PPID: (uint32_t)PPID
	     exception: (nullable id)exception;

/**
 * @brief This method is called when a packet has been sent.
 *
 * @param socket The sequenced packet socket which sent a packet
 * @param data The data which was sent
 * @param streamID The stream ID for the message
 * @param PPID The Payload Protocol Identifier for the message
 * @param exception An exception that occurred while sending, or nil on success
 * @return The data to repeat the send with or nil if it should not repeat
 */
- (nullable OFData *)socket: (OFSCTPSocket *)socket
		didSendData: (OFData *)data
		   streamID: (uint16_t)streamID
		       PPID: (uint32_t)PPID
		  exception: (nullable id)exception;
@end

/**
 * @class OFSCTPSocket OFSCTPSocket.h ObjFW/OFSCTPSocket.h
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
 * @brief Whether sending packets can be delayed. Setting this to NO sets
 *        SCTP_NODELAY on the socket.
 *
 * @throw OFGetOptionFailedException The option could not be retrieved
 * @throw OFSetOptionFailedException The option could not be set
 */
@property (nonatomic) bool canDelaySendingPackets;

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
 * @param block The block to execute once the connection has been established
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
		     block: (OFSCTPSocketAsyncConnectBlock)block;

/**
 * @brief Asynchronously connect the OFSCTPSocket to the specified destination.
 *
 * @param host The host to connect to
 * @param port The port on the host to connect to
 * @param runLoopMode The run loop mode in which to perform the async connect
 * @param block The block to execute once the connection has been established
 */
- (void)asyncConnectToHost: (OFString *)host
		      port: (uint16_t)port
	       runLoopMode: (OFRunLoopMode)runLoopMode
		     block: (OFSCTPSocketAsyncConnectBlock)block;
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
 * @brief Receives a packet for the specified stream and stores it into the
 *	  specified buffer.
 *
 * If the buffer is too small, the packet is truncated.
 *
 * @param buffer The buffer to write the packet to
 * @param length The length of the buffer
 * @param streamID The stream ID for the message
 * @param PPID The Payload Protocol Identifier for the message
 * @return The length of the received packet
 * @throw OFReadFailedException Receiving failed
 * @throw OFNotOpenException The socket is not open
 */
- (size_t)receiveIntoBuffer: (void *)buffer
		     length: (size_t)length
		   streamID: (nullable uint16_t *)streamID
		       PPID: (nullable uint32_t *)PPID;

/**
 * @brief Asynchronously receives a packet with stream ID and PPID and stores
 *	  it into the specified buffer.
 *
 * If the buffer is too small, the packet is truncated.
 *
 * @param buffer The buffer to write the packet to
 * @param length The length of the buffer
 */
- (void)asyncReceiveWithInfoIntoBuffer: (void *)buffer
				length: (size_t)length;

/**
 * @brief Asynchronously receives a packet with stream ID and PPID and stores
 *	  it into the specified buffer.
 *
 * If the buffer is too small, the packet is truncated.
 *
 * @param buffer The buffer to write the packet to
 * @param length The length of the buffer
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      receive
 */
- (void)asyncReceiveWithInfoIntoBuffer: (void *)buffer
				length: (size_t)length
			   runLoopMode: (OFRunLoopMode)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously receives a packet with stream ID and PPID and stores
 *	  it into the specified buffer.
 *
 * If the buffer is too small, the packet is truncated.
 *
 * @param buffer The buffer to write the packet to
 * @param length The length of the buffer
 * @param block The block to call when the packet has been received. If the
 *		block returns true, it will be called again with the same
 *		buffer and maximum length when more packets have been received.
 *		If you want the next method in the queue to handle the packet
 *		received next, you need to return false from the method.
 */
- (void)asyncReceiveWithInfoIntoBuffer: (void *)buffer
				length: (size_t)length
				 block: (OFSCTPSocketAsyncReceiveBlock)block;

/**
 * @brief Asynchronously receives a packet with stream ID and PPID and stores
 *	  it into the specified buffer.
 *
 * If the buffer is too small, the packet is truncated.
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
- (void)asyncReceiveWithInfoIntoBuffer: (void *)buffer
				length: (size_t)length
			   runLoopMode: (OFRunLoopMode)runLoopMode
				 block: (OFSCTPSocketAsyncReceiveBlock)block;
#endif

/**
 * @brief Sends the specified packet on the specified stream.
 *
 * @param buffer The buffer to send as a packet
 * @param length The length of the buffer
 * @param streamID The stream ID for the message
 * @param PPID The Payload Protocol Identifier for the message
 * @throw OFWriteFailedException Sending failed
 * @throw OFNotOpenException The socket is not open
 */
- (void)sendBuffer: (const void *)buffer
	    length: (size_t)length
	  streamID: (uint16_t)streamID
	      PPID: (uint32_t)PPID;

/**
 * @brief Asynchronously sends the specified packet on the specified stream.
 *
 * @param data The data to send as a packet
 * @param streamID The stream ID for the message
 * @param PPID The Payload Protocol Identifier for the message
 */
- (void)asyncSendData: (OFData *)data
	     streamID: (uint16_t)streamID
		 PPID: (uint32_t)PPID;

/**
 * @brief Asynchronously sends the specified packet on the specified stream.
 *
 * @param data The data to send as a packet
 * @param streamID The stream ID for the message
 * @param PPID The Payload Protocol Identifier for the message
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      send
 */
- (void)asyncSendData: (OFData *)data
	     streamID: (uint16_t)streamID
		 PPID: (uint32_t)PPID
	  runLoopMode: (OFRunLoopMode)runLoopMode;

#ifdef OF_HAVE_BLOCKS
/**
 * @brief Asynchronously sends the specified packet on the specified stream.
 *
 * @param data The data to send as a packet
 * @param streamID The stream ID for the message
 * @param PPID The Payload Protocol Identifier for the message
 * @param block The block to call when the packet has been sent. It should
 *		return the data for the next send with the same callback or nil
 *		if it should not repeat.
 */
- (void)asyncSendData: (OFData *)data
	     streamID: (uint16_t)streamID
		 PPID: (uint32_t)PPID
		block: (OFSCTPSocketAsyncSendDataBlock)block;

/**
 * @brief Asynchronously sends the specified packet on the specified stream.
 *
 * @param data The data to send as a packet
 * @param streamID The stream ID for the message
 * @param PPID The Payload Protocol Identifier for the message
 * @param runLoopMode The run loop mode in which to perform the asynchronous
 *		      send
 * @param block The block to call when the packet has been sent. It should
 *		return the data for the next send with the same callback or nil
 *		if it should not repeat.
 */
- (void)asyncSendData: (OFData *)data
	     streamID: (uint16_t)streamID
		 PPID: (uint32_t)PPID
	  runLoopMode: (OFRunLoopMode)runLoopMode
		block: (OFSCTPSocketAsyncSendDataBlock)block;
#endif
@end

OF_ASSUME_NONNULL_END
