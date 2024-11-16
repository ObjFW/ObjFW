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

#import "OFStream.h"
#import "OFRunLoop.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFArray OF_GENERIC(ObjectType);
@class OFTLSStream;
@class OFX509Certificate;

/**
 * @brief An enum representing an error of an OFTLSStream.
 */
typedef enum {
	/** @brief An unknown error. */
	OFTLSStreamErrorCodeUnknown,
	/** @brief Initialization of the TLS context failed. */
	OFTLSStreamErrorCodeInitializationFailed,
	/** @brief Failed to verify certificate. */
	OFTLSStreamErrorCodeCertificateVerificationFailed,
	/** @brief The certificate has an untrusted or unknown issuer. */
	OFTLSStreamErrorCodeCertificateIssuerUntrusted,
	/** @brief The certificate is for a different name. */
	OFTLSStreamErrorCodeCertificateNameMismatch,
	/** @brief The certificate has expired or is not yet valid. */
	OFTLSStreamErrorCodeCertificatedExpired,
	/** @brief The certificate has been revoked. */
	OFTLSStreamErrorCodeCertificateRevoked
} OFTLSStreamErrorCode;

/**
 * @protocol OFTLSStreamDelegate OFTLSStream.h ObjFW/ObjFW.h
 *
 * A delegate for OFTLSStream.
 */
@protocol OFTLSStreamDelegate <OFStreamDelegate>
@optional
/**
 * @brief A method which is called when a TLS stream performed the client
 *	  handshake.
 *
 * @param stream The TLS stream which performed the handshake
 * @param host The host for which the handshake was performed
 * @param exception An exception that occurred during the handshake, or nil on
 *		    success
 */
-		       (void)stream: (OFTLSStream *)stream
  didPerformClientHandshakeWithHost: (OFString *)host
			  exception: (nullable id)exception;

/**
 * @brief A method which is called when a TLS stream performed the server
 *	  handshake.
 *
 * @param stream The TLS stream which performed the handshake
 * @param exception An exception that occurred during the handshake, or nil on
 *		    success
 */
- (void)streamDidPerformServerHandshake: (OFTLSStream *)stream
			      exception: (nullable id)exception;
@end

/**
 * @class OFTLSStream OFTLSStream.h ObjFW/ObjFW.h
 *
 * @brief A class that provides Transport Layer Security on top of a stream.
 *
 * This class is a class cluster and returns a suitable OFTLSStream subclass,
 * if available.
 *
 * Subclasses need to override @ref lowlevelReadIntoBuffer:length:,
 * @ref lowlevelWriteBuffer:length:,
 * @ref lowlevelHasDataInReadBuffer and
 * @ref asyncPerformClientHandshakeWithHost:runLoopMode:.
 *
 * In order to get access to the underlying stream, @ref underlyingStream can
 * be used.
 */
@interface OFTLSStream: OFStream <OFReadyForReadingObserving,
    OFReadyForWritingObserving>
{
	OFStream <OFReadyForReadingObserving, OFReadyForWritingObserving>
	    *_underlyingStream;
	bool _verifiesCertificates;
	OFArray OF_GENERIC(OFX509Certificate *) *_Nullable _certificateChain;
	OF_RESERVE_IVARS(OFTLSStream, 3)
}

/**
 * @brief The underlying stream.
 */
@property (readonly, nonatomic) OFStream <OFReadyForReadingObserving,
    OFReadyForWritingObserving> *underlyingStream;

/**
 * @brief The delegate for asynchronous operations on the stream.
 *
 * @note The delegate is retained for as long as asynchronous operations are
 *	 still ongoing.
 */
@property OF_NULLABLE_PROPERTY (assign, nonatomic)
    id <OFTLSStreamDelegate> delegate;

/**
 * @brief Whether certificates are verified. Default is true.
 */
@property (nonatomic) bool verifiesCertificates;

/**
 * @brief The certificate chain to use.
 */
@property OF_NULLABLE_PROPERTY (copy, nonatomic)
    OFArray OF_GENERIC(OFX509Certificate *) *certificateChain;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Creates a new TLS stream with the specified stream as its underlying
 *	  stream.
 *
 * @param stream The stream to use as underlying stream. Must not be closed
 *		 before the TLS stream is closed.
 * @return A new, autoreleased TLS stream
 */
+ (instancetype)streamWithStream: (OFStream <OFReadyForReadingObserving,
				      OFReadyForWritingObserving> *)stream;

/**
 * @brief Initializes the TLS stream with the specified stream as its
 *	  underlying stream.
 *
 * @note The delegate of the specified stream will be changed to the TLS
 *	 stream. You must not change this before the TLS session is completed.
 *
 * @param stream The stream to use as underlying stream. Must not be closed
 *		 before the TLS stream is closed.
 * @return An initialized TLS stream
 */
- (instancetype)initWithStream: (OFStream <OFReadyForReadingObserving,
				    OFReadyForWritingObserving> *)stream
    OF_DESIGNATED_INITIALIZER;

/**
 * @brief Asynchronously performs the TLS client handshake for the specified
 *	  host and calls the delegate afterwards.
 *
 * @param host The host to perform the handshake with
 * @throw OFTLSHandshakeFailedException The TLS handshake failed
 * @throw OFAlreadyOpenException The handshake was already performed
 */
- (void)asyncPerformClientHandshakeWithHost: (OFString *)host;

/**
 * @brief Asynchronously performs the TLS client handshake for the specified
 *	  host and calls the delegate afterwards.
 *
 * @param host The host to perform the handshake with
 * @param runLoopMode The run loop mode in which to perform the async handshake
 * @throw OFTLSHandshakeFailedException The TLS handshake failed
 * @throw OFAlreadyOpenException The handshake was already performed
 */
- (void)asyncPerformClientHandshakeWithHost: (OFString *)host
				runLoopMode: (OFRunLoopMode)runLoopMode;

/**
 * @brief Performs the TLS client handshake for the specified host.
 *
 * @param host The host to perform the handshake with
 * @throw OFTLSHandshakeFailedException The TLS handshake failed
 * @throw OFAlreadyOpenException The handshake was already performed
 */
- (void)performClientHandshakeWithHost: (OFString *)host;

/**
 * @brief Asynchronously performs the TLS server handshake and calls the
 *	  delegate afterwards.
 *
 * @throw OFTLSHandshakeFailedException The TLS handshake failed
 * @throw OFAlreadyOpenException The handshake was already performed
 */
- (void)asyncPerformServerHandshake;

/**
 * @brief Asynchronously performs the TLS server handshake and calls the
 *	  delegate afterwards.
 *
 * @param runLoopMode The run loop mode in which to perform the async handshake
 *
 * @throw OFTLSHandshakeFailedException The TLS handshake failed
 * @throw OFAlreadyOpenException The handshake was already performed
 */
- (void)asyncPerformServerHandshakeWithRunLoopMode: (OFRunLoopMode)runLoopMode;

/**
 * @brief Performs the TLS server handshake.
 *
 * @throw OFTLSHandshakeFailedException The TLS handshake failed
 * @throw OFAlreadyOpenException The handshake was already performed
 */
- (void)performServerHandshake;
@end

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @brief The implementation for OFTLSStream to use.
 *
 * This can be set to a class that is always used for OFTLSStream. This is
 * useful to either force a specific implementation or use one that ObjFW does
 * not know about.
 */
extern Class OFTLSStreamImplementation;

/**
 * @brief Returns a string description for the TLS stream error code.
 *
 * @param errorCode The error code to return the description for
 * @return A string description for the TLS stream error code
 */
extern OFString *OFTLSStreamErrorCodeDescription(
    OFTLSStreamErrorCode errorCode);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
