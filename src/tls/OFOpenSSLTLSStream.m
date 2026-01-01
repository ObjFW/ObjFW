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

#import "OFOpenSSLTLSStream.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFOpenSSLX509Certificate.h"

#include <openssl/err.h>

#import "OFAlreadyOpenException.h"
#import "OFInitializationFailedException.h"
#import "OFNotOpenException.h"
#import "OFReadFailedException.h"
#import "OFTLSHandshakeFailedException.h"
#import "OFWriteFailedException.h"

#define bufferSize OFOpenSSLTLSStreamBufferSize

int _ObjFWTLS_reference;
static SSL_CTX *clientContext, *serverContext;

#ifdef OF_MORPHOS
struct Library *OpenSSL4Base;

OF_DESTRUCTOR()
{
	if (OpenSSL4Base != NULL)
		CloseLibrary(OpenSSL4Base);
}
#endif

static OFTLSStreamErrorCode
verifyResultToErrorCode(const SSL *SSL_)
{
	switch (SSL_get_verify_result(SSL_)) {
	case X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT:
	case X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY:
	case X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT:
	case X509_V_ERR_SELF_SIGNED_CERT_IN_CHAIN:
	case X509_V_ERR_CERT_UNTRUSTED:
		return OFTLSStreamErrorCodeCertificateIssuerUntrusted;
	case X509_V_ERR_HOSTNAME_MISMATCH:
		return OFTLSStreamErrorCodeCertificateNameMismatch;
	case X509_V_ERR_CERT_NOT_YET_VALID:
	case X509_V_ERR_CERT_HAS_EXPIRED:
		return OFTLSStreamErrorCodeCertificatedExpired;
	case X509_V_ERR_CERT_REVOKED:
		return OFTLSStreamErrorCodeCertificateRevoked;
	}

	return OFTLSStreamErrorCodeCertificateVerificationFailed;
}

static OFTLSStreamErrorCode
errToErrorCode(const SSL *SSL_)
{
	unsigned long err = ERR_get_error();

	switch (ERR_GET_LIB(err)) {
	case ERR_LIB_SSL:
		switch (ERR_GET_REASON(err)) {
		case SSL_R_CERTIFICATE_VERIFY_FAILED:
			return verifyResultToErrorCode(SSL_);
		}
	}

	return OFTLSStreamErrorCodeUnknown;
}

@implementation OFOpenSSLTLSStream
+ (void)load
{
	if (OFTLSStreamImplementation == Nil)
		OFTLSStreamImplementation = self;
}

+ (void)initialize
{
	if (self != [OFOpenSSLTLSStream class])
		return;

#ifdef OF_MORPHOS
	if ((OpenSSL4Base = OpenLibrary("openssl4.library", 0)) == NULL)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
#endif

	SSL_load_error_strings();
	SSL_library_init();

	if ((clientContext = SSL_CTX_new(TLS_client_method())) == NULL ||
	    SSL_CTX_set_default_verify_paths(clientContext) != 1)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];

	if ((serverContext = SSL_CTX_new(TLS_server_method())) == NULL)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

- (instancetype)initWithStream: (OFStream <OFReadyForReadingObserving,
				     OFReadyForWritingObserving> *)stream
{
	self = [super initWithStream: stream];

	@try {
		_underlyingStream.delegate = self;
		/*
		 * Buffer writes so that nothing gets lost if we write more
		 * than the underlying stream can write.
		 */
		_underlyingStream.buffersWrites = true;
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_SSL != NULL)
		[self close];

	objc_release(_host);

	[super dealloc];
}

- (void)close
{
	if (_SSL == NULL)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_handshakeDone) {
		SSL_shutdown(_SSL);

		while (BIO_ctrl_pending(_writeBIO) > 0) {
			int tmp = BIO_read(_writeBIO, _buffer, bufferSize);

			OFEnsure(tmp >= 0);

			@try {
				[_underlyingStream writeBuffer: _buffer
							length: tmp];
				[_underlyingStream flushWriteBuffer];
			} @catch (OFWriteFailedException *e) {
				if (e.errNo != EPIPE && e.errNo != ECONNRESET)
					@throw e;
			}
		}
	}

	SSL_free(_SSL);
	_SSL = NULL;

	_handshakeDone = false;

	objc_release(_host);
	_host = nil;

	[super close];
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	int ret;
	size_t bytesRead;

	if (!_handshakeDone)
		@throw [OFNotOpenException exceptionWithObject: self];

	ERR_clear_error();
	ret = SSL_read_ex(_SSL, buffer, length, &bytesRead);

	while (BIO_ctrl_pending(_writeBIO) > 0) {
		int tmp = BIO_read(_writeBIO, _buffer, bufferSize);

		OFEnsure(tmp >= 0);

		[_underlyingStream writeBuffer: _buffer length: tmp];
		[_underlyingStream flushWriteBuffer];
	}

	if (ret == 1)
		return bytesRead;

	if (SSL_get_error(_SSL, ret) == SSL_ERROR_WANT_READ) {
		if (BIO_ctrl_pending(_readBIO) < 1) {
			@try {
				size_t tmp = [_underlyingStream
				    readIntoBuffer: _buffer
					    length: bufferSize];

				OFEnsure(tmp <= INT_MAX);
				/* Writing to a memory BIO must never fail. */
				OFEnsure(BIO_write(_readBIO, _buffer,
				    (int)tmp) == (int)tmp);
			} @catch (OFReadFailedException *e) {
				if (e.errNo == EWOULDBLOCK || e.errNo != EAGAIN)
					return 0;
			}
		}

		ERR_clear_error();
		ret = SSL_read_ex(_SSL, buffer, length, &bytesRead);

		while (BIO_ctrl_pending(_writeBIO) > 0) {
			int tmp = BIO_read(_writeBIO, _buffer, bufferSize);

			OFEnsure(tmp >= 0);

			[_underlyingStream writeBuffer: _buffer length: tmp];
			[_underlyingStream flushWriteBuffer];
		}

		if (ret == 1)
			return bytesRead;

		if (SSL_get_error(_SSL, ret) == SSL_ERROR_WANT_READ)
			return 0;
	}

	/* FIXME: Translate error to errNo */
	@throw [OFReadFailedException exceptionWithObject: self
					  requestedLength: length
						    errNo: 0];
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
{
	int ret;
	size_t bytesWritten;

	if (!_handshakeDone)
		@throw [OFNotOpenException exceptionWithObject: self];

	ERR_clear_error();

	if ((ret = SSL_write_ex(_SSL, buffer, length, &bytesWritten)) != 1) {
		/* FIXME: Translate error to errNo */
		int errNo = 0;

		if (SSL_get_error(_SSL, ret) == SSL_ERROR_WANT_WRITE)
			return bytesWritten;

		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: bytesWritten
							     errNo: errNo];
	}

	while (BIO_ctrl_pending(_writeBIO) > 0) {
		int tmp = BIO_read(_writeBIO, _buffer, bufferSize);

		OFEnsure(tmp >= 0);

		[_underlyingStream writeBuffer: _buffer length: tmp];
		[_underlyingStream flushWriteBuffer];
	}

	return bytesWritten;
}

- (bool)lowlevelHasDataInReadBuffer
{
	return (_underlyingStream.hasDataInReadBuffer ||
	    SSL_pending(_SSL) > 0 || BIO_ctrl_pending(_readBIO) > 0);
}

- (void)of_asyncPerformHandshakeWithHost: (OFString *)host
				  server: (bool)server
			     runLoopMode: (OFRunLoopMode)runLoopMode
{
	static const OFTLSStreamErrorCode initFailedErrorCode =
	    OFTLSStreamErrorCodeInitializationFailed;
	void *pool = objc_autoreleasePoolPush();
	id exception = nil;
	int status;

	if (_SSL != NULL)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	if ((_readBIO = BIO_new(BIO_s_mem())) == NULL)
		@throw [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: host
			      errorCode: initFailedErrorCode];

	if ((_writeBIO = BIO_new(BIO_s_mem())) == NULL) {
		BIO_free(_readBIO);
		@throw [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: host
			      errorCode: initFailedErrorCode];
	}

	BIO_set_mem_eof_return(_readBIO, -1);
	BIO_set_mem_eof_return(_writeBIO, -1);

	if ((_SSL = SSL_new(server ? serverContext : clientContext)) == NULL) {
		BIO_free(_readBIO);
		BIO_free(_writeBIO);
		@throw [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: host
			      errorCode: initFailedErrorCode];
	}

	SSL_set_bio(_SSL, _readBIO, _writeBIO);

	if (server)
		SSL_set_accept_state(_SSL);
	else
		SSL_set_connect_state(_SSL);

	_host = [host copy];
	_server = server;

	if (!server) {
		if (SSL_set_tlsext_host_name(_SSL, _host.UTF8String) != 1)
			@throw [OFTLSHandshakeFailedException
			    exceptionWithStream: self
					   host: host
				      errorCode: initFailedErrorCode];

		if (_verifiesCertificates) {
			SSL_set_verify(_SSL, SSL_VERIFY_PEER, NULL);

			if (SSL_set1_host(_SSL, _host.UTF8String) != 1)
				@throw [OFTLSHandshakeFailedException
				    exceptionWithStream: self
						   host: host
					      errorCode: initFailedErrorCode];
		}
	}

	if (_certificateChain.count > 0) {
		OFOpenSSLX509Certificate *certificate =
		    (OFOpenSSLX509Certificate *)_certificateChain.firstObject;
		bool first = true;

		if (SSL_use_certificate(_SSL,
		    certificate.of_certificate) != 1 ||
		    SSL_use_PrivateKey(_SSL, certificate.of_privateKey) != 1)
			@throw [OFTLSHandshakeFailedException
			    exceptionWithStream: self
					   host: host
				      errorCode: initFailedErrorCode];

		for (OFOpenSSLX509Certificate *iter in _certificateChain) {
			if (first) {
				first = false;
				continue;
			}

			if (SSL_add1_chain_cert(_SSL, iter.of_certificate) != 1)
				@throw [OFTLSHandshakeFailedException
				    exceptionWithStream: self
						   host: host
					      errorCode: initFailedErrorCode];
		}
	}

	ERR_clear_error();
	status = SSL_do_handshake(_SSL);

	while (BIO_ctrl_pending(_writeBIO) > 0) {
		int tmp = BIO_read(_writeBIO, _buffer, bufferSize);

		OFEnsure(tmp >= 0);

		@try {
			[_underlyingStream writeBuffer: _buffer
						length: tmp];
			[_underlyingStream flushWriteBuffer];
		} @catch (OFWriteFailedException *e) {
			exception = e;
			goto inform_delegate;
		}
	}

	if (status == 1)
		_handshakeDone = true;
	else {
		switch (SSL_get_error(_SSL, status)) {
		case SSL_ERROR_WANT_READ:
			if (!_underlyingStream.atEndOfStream) {
				[_underlyingStream
				    asyncReadIntoBuffer: _buffer
						 length: bufferSize
					    runLoopMode: runLoopMode];
				objc_retain(_delegate);
				objc_autoreleasePoolPop(pool);
				return;
			}

			exception = [OFTLSHandshakeFailedException
			    exceptionWithStream: self
					   host: host
				      errorCode: OFTLSStreamErrorCodeUnknown];
			break;
		case SSL_ERROR_WANT_WRITE:
			[_underlyingStream asyncWriteData: [OFData data]
					      runLoopMode: runLoopMode];
			objc_retain(_delegate);
			objc_autoreleasePoolPop(pool);
			return;
		case SSL_ERROR_SSL:
			exception = [OFTLSHandshakeFailedException
			    exceptionWithStream: self
					   host: host
				      errorCode: errToErrorCode(_SSL)];
			break;
		default:
			exception = [OFTLSHandshakeFailedException
			    exceptionWithStream: self
					   host: host
				      errorCode: OFTLSStreamErrorCodeUnknown];
			break;
		}
	}

inform_delegate:
	if (server) {
		if ([_delegate respondsToSelector: @selector(
		    streamDidPerformServerHandshake:exception:)])
			[_delegate streamDidPerformServerHandshake: self
							 exception: exception];
	} else {
		if ([_delegate respondsToSelector: @selector(
		    stream:didPerformClientHandshakeWithHost:exception:)])
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
		static const OFTLSStreamErrorCode unknownErrorCode =
		    OFTLSStreamErrorCodeUnknown;
		int status;

		OFEnsure(length <= INT_MAX);
		OFEnsure(BIO_write(_readBIO, buffer, (int)length) ==
		    (int)length);

		ERR_clear_error();
		status = SSL_do_handshake(_SSL);

		while (BIO_ctrl_pending(_writeBIO) > 0) {
			int tmp = BIO_read(_writeBIO, buffer, bufferSize);

			OFEnsure(tmp >= 0);

			@try {
				[_underlyingStream writeBuffer: _buffer
							length: tmp];
				[_underlyingStream flushWriteBuffer];
			} @catch (OFWriteFailedException *e) {
				exception = e;
				goto inform_delegate;
			}
		}

		if (status == 1)
			_handshakeDone = true;
		else {
			switch (SSL_get_error(_SSL, status)) {
			case SSL_ERROR_WANT_READ:
				if (!_underlyingStream.atEndOfStream)
					return true;

				exception = [OFTLSHandshakeFailedException
				    exceptionWithStream: self
						   host: _host
					      errorCode: unknownErrorCode];
				break;
			case SSL_ERROR_WANT_WRITE:;
				OFRunLoopMode runLoopMode =
				    [OFRunLoop currentRunLoop].currentMode;
				[_underlyingStream asyncWriteData: [OFData data]
						      runLoopMode: runLoopMode];
				return false;
			case SSL_ERROR_SSL:
				exception = [OFTLSHandshakeFailedException
				    exceptionWithStream: self
						   host: _host
					      errorCode: errToErrorCode(_SSL)];
				break;
			default:
				exception = [OFTLSHandshakeFailedException
				    exceptionWithStream: self
						   host: _host
					      errorCode: unknownErrorCode];
				break;
			}
		}
	}

inform_delegate:
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
		static const OFTLSStreamErrorCode unknownErrorCode =
		    OFTLSStreamErrorCodeUnknown;
		int status;
		OFRunLoopMode runLoopMode;

		while (BIO_ctrl_pending(_writeBIO) > 0) {
			int tmp = BIO_read(_writeBIO, _buffer, bufferSize);

			OFEnsure(tmp >= 0);

			@try {
				[_underlyingStream writeBuffer: _buffer
							length: tmp];
				[_underlyingStream flushWriteBuffer];
			} @catch (OFWriteFailedException *e) {
				exception = e;
				goto inform_delegate;
			}
		}

		ERR_clear_error();
		status = SSL_do_handshake(_SSL);

		while (BIO_ctrl_pending(_writeBIO) > 0) {
			int tmp = BIO_read(_writeBIO, _buffer, bufferSize);

			OFEnsure(tmp >= 0);

			@try {
				[_underlyingStream writeBuffer: _buffer
							length: tmp];
				[_underlyingStream flushWriteBuffer];
			} @catch (OFWriteFailedException *e) {
				exception = e;
				goto inform_delegate;
			}
		}

		if (status == 1)
			_handshakeDone = true;
		else {
			switch (SSL_get_error(_SSL, status)) {
			case SSL_ERROR_WANT_READ:
				runLoopMode =
				    [OFRunLoop currentRunLoop].currentMode;
				[_underlyingStream
				    asyncReadIntoBuffer: _buffer
						 length: bufferSize
					    runLoopMode: runLoopMode];
				return nil;
			case SSL_ERROR_WANT_WRITE:
				return data;
			case SSL_ERROR_SSL:
				exception = [OFTLSHandshakeFailedException
				    exceptionWithStream: self
						   host: _host
					      errorCode: errToErrorCode(_SSL)];
				break;
			default:
				exception = [OFTLSHandshakeFailedException
				    exceptionWithStream: self
						   host: _host
					      errorCode: unknownErrorCode];
				break;
			}
		}
	}

inform_delegate:
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

	return nil;
}
@end
