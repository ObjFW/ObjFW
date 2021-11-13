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

#import "OFStream.h"
#import "OFRunLoop.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

@class OFTLSStream;

/**
 * @brief An enum representing an error of an OFTLSStream.
 */
typedef enum {
	/** @brief An unknown error. */
	OFTLSStreamErrorCodeUnknown,
	/** @brief Initialization of the TLS context failed. */
	OFTLSStreamErrorCodeInitializationFailed
} OFTLSStreamErrorCode;

/**
 * @protocol OFTLSStreamDelegate OFTLSStream.h ObjFW/OFTLSStream.h
 *
 * A delegate for OFTLSStream.
 */
@protocol OFTLSStreamDelegate <OFStreamDelegate>
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
@end

/**
 * @class OFTLSStream OFTLSStream.h ObjFW/OFTLSStream.h
 *
 * @brief A class that provides Transport Layer Security on top of a stream.
 *
 * This class is a class cluster and returns a suitable OFTLSStream subclass,
 * if available.
 *
 * Subclasses need to override @ref lowlevelReadIntoBuffer:length:,
 * @ref lowlevelWriteBuffer:length: and
 * @ref asyncPerformClientHandshakeWithHost:runLoopMode:. The method
 * @ref hasDataInReadBuffer should be overridden to return `true` if the TLS
 * stream has cached unprocessed data internally, while returning
 * `self.wrappedStream.hasDataInReadBuffer` if it does not have any unprocessed
 * data. In order to get access to the wrapped stream, @ref wrappedStream can
 * be used.
 */
@interface OFTLSStream: OFStream <OFReadyForReadingObserving,
    OFReadyForWritingObserving>
{
	OFStream <OFReadyForReadingObserving, OFReadyForWritingObserving>
	    *_wrappedStream;
	bool _verifiesCertificates;
	OF_RESERVE_IVARS(OFTLSStream, 4)
}

/**
 * @brief The wrapped stream.
 */
@property (readonly, nonatomic) OFStream <OFReadyForReadingObserving,
    OFReadyForWritingObserving> *wrappedStream;

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
 */
- (void)asyncPerformClientHandshakeWithHost: (OFString *)host;

/**
 * @brief Asynchronously performs the TLS client handshake for the specified
 *	  host and calls the delegate afterwards.
 *
 * @param host The host to perform the handshake with
 * @param runLoopMode The run loop mode in which to perform the async handshake
 */
- (void)asyncPerformClientHandshakeWithHost: (OFString *)host
				runLoopMode: (OFRunLoopMode)runLoopMode;

/**
 * @brief Performs the TLS client handshake for the specified host.
 *
 * @param host The host to perform the handshake with
 */
- (void)performClientHandshakeWithHost: (OFString *)host;
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
