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

#include "config.h"

#include <errno.h>

#import "OFMbedTLSTLSStream.h"
#import "OFApplication.h"
#import "OFData.h"
#import "OFDictionary.h"
#import "OFLocale.h"

#import "OFAlreadyOpenException.h"
#import "OFInitializationFailedException.h"
#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFTLSHandshakeFailedException.h"
#import "OFWriteFailedException.h"

#include <mbedtls/ctr_drbg.h>
#include <mbedtls/entropy.h>

int _ObjFWTLS_reference;
static mbedtls_entropy_context entropy;
static mbedtls_ctr_drbg_context CTRDRBG;

@implementation OFMbedTLSTLSStream
static int
readFunc(void *ctx, unsigned char *buffer, size_t length)
{
	OFMbedTLSTLSStream *stream = (OFMbedTLSTLSStream *)ctx;

	@try {
		length = [stream.underlyingStream readIntoBuffer: buffer
							  length: length];
	} @catch (OFReadFailedException *e) {
		return -1;
	}

	if (length == 0 && !stream.underlyingStream.atEndOfStream)
		return MBEDTLS_ERR_SSL_WANT_READ;

	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	return (int)length;
}

static int
writeFunc(void *ctx, const unsigned char *buffer, size_t length)
{
	OFMbedTLSTLSStream *stream = (OFMbedTLSTLSStream *)ctx;

	@try {
		[stream.underlyingStream writeBuffer: buffer length: length];
	} @catch (OFWriteFailedException *e) {
		if (e.errNo == EWOULDBLOCK || e.errNo == EAGAIN) {
			size_t bytesWritten = e.bytesWritten;

			if (bytesWritten > INT_MAX)
				@throw [OFOutOfRangeException exception];

			return (bytesWritten > 0
			    ? (int)bytesWritten : MBEDTLS_ERR_SSL_WANT_WRITE);
		}

		return -1;
	}

	if (length > INT_MAX)
		@throw [OFOutOfRangeException exception];

	return (int)length;
}

+ (void)load
{
	if (OFTLSStreamImplementation == Nil)
		OFTLSStreamImplementation = self;
}

+ (void)initialize
{
	if (self != [OFMbedTLSTLSStream class])
		return;

	mbedtls_entropy_init(&entropy);
	if (mbedtls_ctr_drbg_seed(&CTRDRBG, mbedtls_entropy_func, &entropy,
	    NULL, 0) != 0)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

- (instancetype)initWithStream: (OFStream <OFReadyForReadingObserving,
				     OFReadyForWritingObserving> *)stream
{
	self = [super initWithStream: stream];

	@try {
		_underlyingStream.delegate = self;

		mbedtls_x509_crt_init(&_CAChain);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_initialized)
		[self close];

	[_host release];

	mbedtls_x509_crt_free(&_CAChain);

	[super dealloc];
}

- (void)close
{
	if (!_initialized)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_handshakeDone)
		mbedtls_ssl_close_notify(&_SSL);

	mbedtls_ssl_free(&_SSL);
	mbedtls_ssl_config_free(&_config);
	_initialized = _handshakeDone = false;

	[_host release];
	_host = nil;

	[super close];
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	int ret;

	if (!_handshakeDone)
		@throw [OFNotOpenException exceptionWithObject: self];

	if ((ret = mbedtls_ssl_read(&_SSL, buffer, length)) < 0) {
		/*
		 * The underlying stream might have had data ready, but not
		 * enough for MbedTLS to return decrypted data. This means the
		 * caller might have observed the TLS stream for reading, got a
		 * ready signal and read - and expects the read to succeed, not
		 * to fail with EWOULDBLOCK/EAGAIN, as it was signaled ready.
		 * Therefore, return 0, as we could read 0 decrypted bytes, but
		 * cleared the ready signal of the underlying stream.
		 */
		if (ret == MBEDTLS_ERR_SSL_WANT_READ ||
		    ret == MBEDTLS_ERR_SSL_WANT_WRITE)
			return 0;

		/* FIXME: Translate error to errNo */
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: 0];
	}

	return ret;
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
{
	int ret;

	if (!_handshakeDone)
		@throw [OFNotOpenException exceptionWithObject: self];

	if ((ret = mbedtls_ssl_write(&_SSL, buffer, length)) < 0) {
		if (ret == MBEDTLS_ERR_SSL_WANT_READ ||
		    ret == MBEDTLS_ERR_SSL_WANT_WRITE)
			return 0;

		/* FIXME: Translate error to errNo */
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: ret
							     errNo: 0];
	}

	return ret;
}

- (bool)lowlevelHasDataInReadBuffer
{
	return (_underlyingStream.hasDataInReadBuffer ||
	    mbedtls_ssl_get_bytes_avail(&_SSL));
}

- (void)asyncPerformClientHandshakeWithHost: (OFString *)host
				runLoopMode: (OFRunLoopMode)runLoopMode
{
	static const OFTLSStreamErrorCode initFailedErrorCode =
	    OFTLSStreamErrorCodeInitializationFailed;
	void *pool = objc_autoreleasePoolPush();
	OFString *CAFilePath;
	id exception = nil;
	int status;

	if (_initialized)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	if (mbedtls_ssl_config_defaults(&_config, MBEDTLS_SSL_IS_CLIENT,
	    MBEDTLS_SSL_TRANSPORT_STREAM, MBEDTLS_SSL_PRESET_DEFAULT) != 0)
		@throw [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: host
			      errorCode: initFailedErrorCode];

	mbedtls_ssl_conf_rng(&_config, mbedtls_ctr_drbg_random, &CTRDRBG);
	mbedtls_ssl_conf_authmode(&_config, (_verifiesCertificates
	    ? MBEDTLS_SSL_VERIFY_REQUIRED : MBEDTLS_SSL_VERIFY_NONE));

	/* TODO: Add other ways to add a CA chain */
	CAFilePath = [[OFApplication environment]
	    objectForKey: @"OBJFW_MBEDTLS_CA_PATH"];
	if (CAFilePath != nil) {
		if (mbedtls_x509_crt_parse_file(&_CAChain,
		    [CAFilePath cStringWithEncoding: [OFLocale encoding]]) != 0)
			@throw [OFTLSHandshakeFailedException
			    exceptionWithStream: self
					   host: host
				      errorCode: initFailedErrorCode];
	}

	mbedtls_ssl_conf_ca_chain(&_config, &_CAChain, NULL);

	mbedtls_ssl_init(&_SSL);
	if (mbedtls_ssl_setup(&_SSL, &_config) != 0)
		@throw [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: host
			      errorCode: initFailedErrorCode];

	mbedtls_ssl_set_bio(&_SSL, self, writeFunc, readFunc, NULL);

	_host = [host copy];

	if (mbedtls_ssl_set_hostname(&_SSL, _host.UTF8String) != 0)
		@throw [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: host
			      errorCode: initFailedErrorCode];

	status = mbedtls_ssl_handshake(&_SSL);

	if (status == MBEDTLS_ERR_SSL_WANT_READ) {
		[_underlyingStream asyncReadIntoBuffer: (void *)""
						length: 0
					   runLoopMode: runLoopMode];
		[_delegate retain];
		objc_autoreleasePoolPop(pool);
		return;
	} else if (status == MBEDTLS_ERR_SSL_WANT_WRITE) {
		[_underlyingStream asyncWriteData: [OFData data]
				      runLoopMode: runLoopMode];
		[_delegate retain];
		objc_autoreleasePoolPop(pool);
		return;
	}

	if (status == 0)
		_handshakeDone = true;
	else
		/* FIXME: Map to better errors */
		exception = [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: host
			      errorCode: OFTLSStreamErrorCodeUnknown];

	if ([_delegate respondsToSelector:
	    @selector(stream:didPerformClientHandshakeWithHost:exception:)])
		[_delegate		       stream: self
		    didPerformClientHandshakeWithHost: host
					    exception: exception];

	objc_autoreleasePoolPop(pool);
}

-      (bool)stream: (OFStream *)stream
  didReadIntoBuffer: (void *)buffer
	     length: (size_t)length
	  exception: (id)exception
{
	if (exception == nil) {
		int status = mbedtls_ssl_handshake_step(&_SSL);

		if (status == MBEDTLS_ERR_SSL_WANT_READ)
			return true;
		else if (status == MBEDTLS_ERR_SSL_WANT_WRITE) {
			OFRunLoopMode runLoopMode =
			    [OFRunLoop currentRunLoop].currentMode;
			[_underlyingStream asyncWriteData: [OFData data]
					      runLoopMode: runLoopMode];
			return false;
		}

		if (status == 0)
			_handshakeDone = true;
		else
			exception = [OFTLSHandshakeFailedException
			    exceptionWithStream: self
					   host: _host
				      errorCode: OFTLSStreamErrorCodeUnknown];
	}

	if ([_delegate respondsToSelector:
	    @selector(stream:didPerformClientHandshakeWithHost:exception:)])
		[_delegate		       stream: self
		    didPerformClientHandshakeWithHost: _host
					    exception: exception];

	[_delegate release];

	return false;
}

- (OFData *)stream: (OFStream *)stream
      didWriteData: (OFData *)data
      bytesWritten: (size_t)bytesWritten
	 exception: (id)exception
{
	if (exception == nil) {
		int status = mbedtls_ssl_handshake_step(&_SSL);

		if (status == MBEDTLS_ERR_SSL_WANT_WRITE)
			return data;
		else if (status == MBEDTLS_ERR_SSL_WANT_READ) {
			OFRunLoopMode runLoopMode =
			    [OFRunLoop currentRunLoop].currentMode;
			[_underlyingStream asyncReadIntoBuffer: (void *)""
							length: 0
						   runLoopMode: runLoopMode];
			return nil;
		}

		if (status == 0)
			_handshakeDone = true;
		else
			exception = [OFTLSHandshakeFailedException
			    exceptionWithStream: self
					   host: _host
				      errorCode: OFTLSStreamErrorCodeUnknown];
	}

	if ([_delegate respondsToSelector:
	    @selector(stream:didPerformClientHandshakeWithHost:exception:)])
		[_delegate		       stream: self
		    didPerformClientHandshakeWithHost: _host
					    exception: exception];

	[_delegate release];

	return nil;
}
@end
