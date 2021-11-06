/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "OFTCPSocket.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @protocol OFTLSSocketDelegate OFTLSSocket.h ObjFW/OFTLSSocket.h
 *
 * A delegate for OFTLSSocket.
 */
@protocol OFTLSSocketDelegate <OFTCPSocketDelegate>
@end

/**
 * @class OFTLSSocket OFTLSSocket.h ObjFW/OFTLSSocket.h
 *
 * @brief A class that provides Transport Layer Security on top of a TCP socket.
 *
 * This class is a class cluster and returns a suitable OFTLSSocket subclass,
 * if available.
 *
 * Subclasses need to override @ref accept, @ref lowlevelReadIntoBuffer:length:,
 * @ref lowlevelWriteBuffer:length:, @ref lowlevelIsAtEndOfStream and
 * @ref startTLSForHost:port:. In order to get access to the lowlevel TCP
 * methods (you cannot call `super`, as the class is abstract), the private
 * methods @ref TCPAccept, @ref lowlevelTCPReadIntoBuffer:length:,
 * @ref lowlevelTCPWriteBuffer:length: and @ref lowlevelTCPIsAtEndOfStream are
 * provided.
 */
@interface OFTLSSocket: OFTCPSocket
{
	bool _verifiesCertificates;
	OF_RESERVE_IVARS(OFTLSSocket, 4)
}

/**
 * @brief The delegate for asynchronous operations on the socket.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFTLSSocketDelegate> delegate;

/**
 * @brief Whether certificates are verified.
 *
 * The default is enabled.
 */
@property (nonatomic) bool verifiesCertificates;

/**
 * @brief Initializes the TLS socket with the specified TCP socket as its
 *	  underlying socket.
 *
 * The passed socket will become invalid, as the internal socket handle gets
 * moved from the specified socket to the OFTLSSocket.
 *
 * @param socket The TCP socket to use as underlying socket
 */
- (instancetype)initWithSocket: (OFTCPSocket *)socket;

/**
 * @brief Start TLS on the underlying socket with the assumption that it is
 *	  connected to the specified host and port.
 *
 * @param host The host the socket is connected to, which is also used for
 *	       verification
 * @param port The port the socket is connected to
 */
- (void)startTLSForHost: (OFString *)host port: (uint16_t)port;

/**
 * @brief This method should never be called directly. Only subclasses of
 *	  @ref OFTLSSocket are allowed to call it.
 */
- (instancetype)TCPAccept;

/**
 * @brief This method should never be called directly. Only subclasses of
 *	  @ref OFTLSSocket are allowed to call it.
 */
- (size_t)lowlevelTCPReadIntoBuffer: (void *)buffer length: (size_t)length;

/**
 * @brief This method should never be called directly. Only subclasses of
 *	  @ref OFTLSSocket are allowed to call it.
 */
- (size_t)lowlevelTCPWriteBuffer: (const void *)buffer length: (size_t)length;

/**
 * @brief This method should never be called directly. Only subclasses of
 *	  @ref OFTLSSocket are allowed to call it.
 */
- (bool)lowlevelTCPIsAtEndOfStream;
@end

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief The concrete subclass of OFTLSSocket that should be used.
 */
extern Class _Nullable OFTLSSocketImplementation;
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
