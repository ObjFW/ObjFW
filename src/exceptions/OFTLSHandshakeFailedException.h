/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFException.h"

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

#import "OFTLSStream.h"

OF_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFTLSHandshakeFailedException_reference;
#ifdef __cplusplus
}
#endif

/**
 * @class OFTLSHandshakeFailedException \
 *	  OFTLSHandshakeFailedException.h ObjFW/OFTLSHandshakeFailedException.h
 *
 * @brief An exception indicating that a TLS handshake.
 */
@interface OFTLSHandshakeFailedException: OFException
{
	OFTLSStream *_stream;
	OFString *_Nullable _host;
	OFTLSStreamErrorCode _errorCode;
	OF_RESERVE_IVARS(OFTLSHandshakeFailedException, 4)
}

/**
 * @brief The TLS stream which failed the handshake.
 */
@property (readonly, nonatomic) OFTLSStream *stream;

/**
 * @brief The host for the handshake.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFString *host;

/**
 * @brief The error code from the TLS stream.
 */
@property (readonly, nonatomic) OFTLSStreamErrorCode errorCode;

/**
 * @brief Creates a new, autoreleased TLS handshake failed exception.
 *
 * @param stream The TLS stream which failed the handshake
 * @param host The host for the handshake
 * @param errorCode The error code from the TLS stream
 * @return A new, autoreleased TLS handshake failed exception
 */
+ (instancetype)exceptionWithStream: (OFTLSStream *)stream
			       host: (nullable OFString *)host
			  errorCode: (OFTLSStreamErrorCode)errorCode;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated TLS handshake failed exception.
 *
 * @param stream The TLS stream which failed the handshake
 * @param host The host for the handshake
 * @param errorCode The error code from the TLS stream
 * @return An initialized TLS handshake failed exception
 */
- (instancetype)initWithStream: (OFTLSStream *)stream
			  host: (nullable OFString *)host
		     errorCode: (OFTLSStreamErrorCode)errorCode
    OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
