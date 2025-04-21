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

#import "OFException.h"

#ifndef OF_HAVE_SOCKETS
# error No sockets available!
#endif

#import "OFTLSStream.h"

OF_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFTLSHandshakeFailedException_reference OF_VISIBILITY_INTERNAL;
#ifdef __cplusplus
}
#endif

/**
 * @class OFTLSHandshakeFailedException OFTLSHandshakeFailedException.h
 *	  ObjFW/ObjFW.h
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
