/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#include "config.h"

#include <errno.h>

#import "OFMbedTLSTLSStream.h"
#import "OFApplication.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDictionary.h"
#import "OFLocale.h"
#import "OFMbedTLSX509Certificate.h"

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

static OFTLSStreamErrorCode
verifyResultToErrorCode(const mbedtls_ssl_context *SSL)
{
	switch (mbedtls_ssl_get_verify_result(SSL)) {
	case MBEDTLS_X509_BADCERT_NOT_TRUSTED:
		return OFTLSStreamErrorCodeCertificateIssuerUntrusted;
	case MBEDTLS_X509_BADCERT_CN_MISMATCH:
		return OFTLSStreamErrorCodeCertificateNameMismatch;
	case MBEDTLS_X509_BADCERT_EXPIRED:
	case MBEDTLS_X509_BADCERT_FUTURE:
		return OFTLSStreamErrorCodeCertificatedExpired;
	case MBEDTLS_X509_BADCERT_REVOKED:
		return OFTLSStreamErrorCodeCertificateRevoked;
	}

	return OFTLSStreamErrorCodeCertificateVerificationFailed;
}

static OFTLSStreamErrorCode
statusToErrorCode(const mbedtls_ssl_context *SSL, int status)
{
	switch (status) {
	case MBEDTLS_ERR_X509_CERT_VERIFY_FAILED:
		return verifyResultToErrorCode(SSL);
	}

	return OFTLSStreamErrorCodeUnknown;
}

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

		mbedtls_ssl_config_init(&_config);
		mbedtls_x509_crt_init(&_CAChain);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_initialized)
		[self close];

	objc_release(_host);

	mbedtls_ssl_config_free(&_config);
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
	_initialized = _handshakeDone = false;

	objc_release(_host);
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
						      bytesWritten: 0
							     errNo: 0];
	}

	return ret;
}

- (bool)lowlevelHasDataInReadBuffer
{
	return (_underlyingStream.hasDataInReadBuffer ||
	    mbedtls_ssl_get_bytes_avail(&_SSL));
}

- (void)of_asyncPerformHandshakeWithHost: (OFString *)host
				  server: (bool)server
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

	if (mbedtls_ssl_config_defaults(&_config,
	    (server ? MBEDTLS_SSL_IS_SERVER : MBEDTLS_SSL_IS_CLIENT),
	    MBEDTLS_SSL_TRANSPORT_STREAM, MBEDTLS_SSL_PRESET_DEFAULT) != 0)
		@throw [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: host
			      errorCode: initFailedErrorCode];

	mbedtls_ssl_conf_rng(&_config, mbedtls_ctr_drbg_random, &CTRDRBG);

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

	if (!server) {
		mbedtls_ssl_conf_ca_chain(&_config, &_CAChain, NULL);
		mbedtls_ssl_conf_authmode(&_config, (_verifiesCertificates
		    ? MBEDTLS_SSL_VERIFY_REQUIRED : MBEDTLS_SSL_VERIFY_NONE));
	}

	if (_certificateChain.count > 0) {
		/*
		 * MbedTLS does not allow storing the certificates
		 * independently, so the chain has to be kept. This means we
		 * can just get the first certificate and get the entire chain
		 * from it.
		 */
		OFMbedTLSX509CertificateChain *chain =
		    ((OFMbedTLSX509Certificate *)_certificateChain.firstObject)
		    .of_chain;

		if (mbedtls_ssl_conf_own_cert(&_config, chain.certificate,
		    chain.privateKey) != 0)
			@throw [OFTLSHandshakeFailedException
			    exceptionWithStream: self
					   host: host
				      errorCode: initFailedErrorCode];
	}

	mbedtls_ssl_init(&_SSL);
	_initialized = true;

	if (mbedtls_ssl_setup(&_SSL, &_config) != 0)
		@throw [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: host
			      errorCode: initFailedErrorCode];

	mbedtls_ssl_set_bio(&_SSL, self, writeFunc, readFunc, NULL);

	_host = [host copy];
	_server = server;

	if (!server) {
		if (mbedtls_ssl_set_hostname(&_SSL, _host.UTF8String) != 0)
			@throw [OFTLSHandshakeFailedException
			    exceptionWithStream: self
					   host: host
				      errorCode: initFailedErrorCode];
	}

	status = mbedtls_ssl_handshake(&_SSL);

	if (status == MBEDTLS_ERR_SSL_WANT_READ) {
		[_underlyingStream asyncReadIntoBuffer: (void *)""
						length: 0
					   runLoopMode: runLoopMode];
		objc_retain(_delegate);
		objc_autoreleasePoolPop(pool);
		return;
	} else if (status == MBEDTLS_ERR_SSL_WANT_WRITE) {
		[_underlyingStream asyncWriteData: [OFData data]
				      runLoopMode: runLoopMode];
		objc_retain(_delegate);
		objc_autoreleasePoolPop(pool);
		return;
	}

	if (status == 0)
		_handshakeDone = true;
	else
		exception = [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: host
			      errorCode: statusToErrorCode(&_SSL, status)];

	if (server) {
		if ([_delegate respondsToSelector: @selector(
		    streamDidPerformServerHandshake:exception:)])
			[_delegate streamDidPerformServerHandshake: self
							 exception: exception];
	} else {
		if ([_delegate respondsToSelector: @selector(stream:
		    didPerformClientHandshakeWithHost:exception:)])
			[_delegate		       stream: self
			    didPerformClientHandshakeWithHost: host
						    exception: exception];
	}

	objc_autoreleasePoolPop(pool);
}

- (void)asyncPerformClientHandshakeWithHost: (OFString *)host
				runLoopMode: (OFRunLoopMode)runLoopMode
{
	[self of_asyncPerformHandshakeWithHost: host
					server: false
				   runLoopMode: runLoopMode];
}

- (void)asyncPerformServerHandshakeWithRunLoopMode: (OFRunLoopMode)runLoopMode
{
	[self of_asyncPerformHandshakeWithHost: nil
					server: true
				   runLoopMode: runLoopMode];
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
				      errorCode: statusToErrorCode(
						     &_SSL, status)];
	}

	if (_server) {
		if ([_delegate respondsToSelector: @selector(
		    streamDidPerformServerHandshake:exception:)])
			[_delegate streamDidPerformServerHandshake: self
							 exception: exception];
	} else {
		if ([_delegate respondsToSelector: @selector(
		    stream:didPerformClientHandshakeWithHost:exception:)])
			[_delegate		       stream: self
			    didPerformClientHandshakeWithHost: _host
						    exception: exception];
	}

	objc_release(_delegate);

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
				      errorCode: statusToErrorCode(
						     &_SSL, status)];
	}

	if (_server) {
		if ([_delegate respondsToSelector: @selector(
		    streamDidPerformServerHandshake:exception:)])
			[_delegate streamDidPerformServerHandshake: self
							 exception: exception];
	} else {
		if ([_delegate respondsToSelector: @selector(stream:
		    didPerformClientHandshakeWithHost:exception:)])
			[_delegate		       stream: self
			    didPerformClientHandshakeWithHost: _host
						    exception: exception];
	}

	objc_release(_delegate);

	return nil;
}
@end
