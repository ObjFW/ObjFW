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

#include "config.h"

#include <errno.h>

#import "OFGnuTLSTLSStream.h"
#import "OFData.h"

#import "OFAlreadyOpenException.h"
#import "OFInitializationFailedException.h"
#import "OFNotOpenException.h"
#import "OFReadFailedException.h"
#import "OFTLSHandshakeFailedException.h"
#import "OFWriteFailedException.h"

int _ObjFWTLS_reference;
static gnutls_certificate_credentials_t systemTrustCreds;

#ifndef GNUTLS_SAFE_PADDING_CHECK
/* Some older versions don't have it. */
# define GNUTLS_SAFE_PADDING_CHECK 0
#endif

static OFTLSStreamErrorCode
certificateStatusToErrorCode(gnutls_certificate_status_t status)
{
	if (status & GNUTLS_CERT_UNEXPECTED_OWNER)
		return OFTLSStreamErrorCodeCertificateNameMismatch;
	if (status & GNUTLS_CERT_REVOKED)
		return OFTLSStreamErrorCodeCertificateRevoked;
	if (status & (GNUTLS_CERT_EXPIRED | GNUTLS_CERT_NOT_ACTIVATED))
		return OFTLSStreamErrorCodeCertificatedExpired;
	if (status & GNUTLS_CERT_SIGNER_NOT_FOUND)
		return OFTLSStreamErrorCodeCertificateIssuerUntrusted;

	return OFTLSStreamErrorCodeCertificateVerificationFailed;
}

@implementation OFGnuTLSTLSStream
static ssize_t
readFunc(gnutls_transport_ptr_t transport, void *buffer, size_t length)
{
	OFGnuTLSTLSStream *stream = (OFGnuTLSTLSStream *)transport;

	@try {
		length = [stream.underlyingStream readIntoBuffer: buffer
							  length: length];
	} @catch (OFReadFailedException *e) {
		gnutls_transport_set_errno(stream->_session, e.errNo);
		return -1;
	}

	if (length == 0 && !stream.underlyingStream.atEndOfStream) {
		gnutls_transport_set_errno(stream->_session, EAGAIN);
		return -1;
	}

	return length;
}

static ssize_t
writeFunc(gnutls_transport_ptr_t transport, const void *buffer, size_t length)
{
	OFGnuTLSTLSStream *stream = (OFGnuTLSTLSStream *)transport;

	@try {
		[stream.underlyingStream writeBuffer: buffer length: length];
	} @catch (OFWriteFailedException *e) {
		gnutls_transport_set_errno(stream->_session, e.errNo);

		if (e.errNo == EWOULDBLOCK || e.errNo == EAGAIN)
			return e.bytesWritten;

		return -1;
	}

	return length;
}

+ (void)load
{
	if (OFTLSStreamImplementation == Nil)
		OFTLSStreamImplementation = self;
}

+ (void)initialize
{
	if (self != [OFGnuTLSTLSStream class])
		return;

	if (gnutls_certificate_allocate_credentials(&systemTrustCreds) !=
	    GNUTLS_E_SUCCESS ||
	    gnutls_certificate_set_x509_system_trust(systemTrustCreds) < 0)
		@throw [OFInitializationFailedException exception];
}

- (instancetype)initWithStream: (OFStream <OFReadyForReadingObserving,
				     OFReadyForWritingObserving> *)stream
{
	self = [super initWithStream: stream];

	@try {
		_underlyingStream.delegate = self;
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

	[super dealloc];
}

- (void)close
{
	if (!_initialized)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_handshakeDone)
		gnutls_bye(_session, GNUTLS_SHUT_WR);

	gnutls_deinit(_session);
	_initialized = _handshakeDone = false;

	[_host release];
	_host = nil;

	[super close];
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	ssize_t ret;

	if (!_handshakeDone)
		@throw [OFNotOpenException exceptionWithObject: self];

	if ((ret = gnutls_record_recv(_session, buffer, length)) < 0) {
		/*
		 * The underlying stream might have had data ready, but not
		 * enough for GnuTLS to return decrypted data. This means the
		 * caller might have observed the TLS stream for reading, got a
		 * ready signal and read - and expects the read to succeed, not
		 * to fail with EWOULDBLOCK/EAGAIN, as it was signaled ready.
		 * Therefore, return 0, as we could read 0 decrypted bytes, but
		 * cleared the ready signal of the underlying stream.
		 */
		if (ret == GNUTLS_E_INTERRUPTED || ret == GNUTLS_E_AGAIN)
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
	ssize_t ret;

	if (!_handshakeDone)
		@throw [OFNotOpenException exceptionWithObject: self];

	if ((ret = gnutls_record_send(_session, buffer, length)) < 0) {
		if (ret == GNUTLS_E_INTERRUPTED || ret == GNUTLS_E_AGAIN)
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
	    gnutls_record_check_pending(_session) > 0);
}

- (void)asyncPerformClientHandshakeWithHost: (OFString *)host
				runLoopMode: (OFRunLoopMode)runLoopMode
{
	static const OFTLSStreamErrorCode initFailedErrorCode =
	    OFTLSStreamErrorCodeInitializationFailed;
	void *pool = objc_autoreleasePoolPush();
	id exception = nil;
	int status;

	if (_initialized)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

	if (gnutls_init(&_session, GNUTLS_CLIENT | GNUTLS_NONBLOCK |
	    GNUTLS_SAFE_PADDING_CHECK) != GNUTLS_E_SUCCESS)
		@throw [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: host
			      errorCode: initFailedErrorCode];

	_initialized = true;

	gnutls_transport_set_ptr(_session, self);
	gnutls_transport_set_pull_function(_session, readFunc);
	gnutls_transport_set_push_function(_session, writeFunc);

	if (gnutls_set_default_priority(_session) != GNUTLS_E_SUCCESS ||
	    gnutls_credentials_set(_session, GNUTLS_CRD_CERTIFICATE,
	    systemTrustCreds) != GNUTLS_E_SUCCESS)
		@throw [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: host
			      errorCode: initFailedErrorCode];

	_host = [host copy];

	if (gnutls_server_name_set(_session, GNUTLS_NAME_DNS,
	    _host.UTF8String, _host.UTF8StringLength) != GNUTLS_E_SUCCESS)
		@throw [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: host
			      errorCode: initFailedErrorCode];

	if (_verifiesCertificates)
		gnutls_session_set_verify_cert(_session, _host.UTF8String, 0);

	status = gnutls_handshake(_session);

	if (status == GNUTLS_E_INTERRUPTED || status == GNUTLS_E_AGAIN) {
		if (gnutls_record_get_direction(_session) == 1)
			[_underlyingStream asyncWriteData: [OFData data]
					      runLoopMode: runLoopMode];
		else
			[_underlyingStream asyncReadIntoBuffer: (void *)""
							length: 0
						   runLoopMode: runLoopMode];

		[_delegate retain];
		objc_autoreleasePoolPop(pool);
		return;
	}

	if (status == GNUTLS_E_SUCCESS)
		_handshakeDone = true;
	else {
		OFTLSStreamErrorCode errorCode = OFTLSStreamErrorCodeUnknown;

		if (status == GNUTLS_E_CERTIFICATE_VERIFICATION_ERROR)
			errorCode = certificateStatusToErrorCode(
			    gnutls_session_get_verify_cert_status(_session));

		/* FIXME: Map to better errors */
		exception = [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: host
			      errorCode: errorCode];
	}

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
		int status = gnutls_handshake(_session);

		if (status == GNUTLS_E_INTERRUPTED ||
		    status == GNUTLS_E_AGAIN) {
			if (gnutls_record_get_direction(_session) == 1) {
				OFRunLoopMode runLoopMode =
				    [OFRunLoop currentRunLoop].currentMode;
				[_underlyingStream asyncWriteData: [OFData data]
						      runLoopMode: runLoopMode];
				return false;
			} else
				return true;
		}

		if (status == GNUTLS_E_SUCCESS)
			_handshakeDone = true;
		else {
			OFTLSStreamErrorCode errorCode =
			    OFTLSStreamErrorCodeUnknown;

			if (status == GNUTLS_E_CERTIFICATE_VERIFICATION_ERROR)
				errorCode = certificateStatusToErrorCode(
				    gnutls_session_get_verify_cert_status(
				    _session));

			/* FIXME: Map to better errors */
			exception = [OFTLSHandshakeFailedException
			    exceptionWithStream: self
					   host: _host
				      errorCode: errorCode];
		}
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
		int status = gnutls_handshake(_session);

		if (status == GNUTLS_E_INTERRUPTED ||
		    status == GNUTLS_E_AGAIN) {
			if (gnutls_record_get_direction(_session) == 1)
				return data;
			else {
				OFRunLoopMode runLoopMode =
				    [OFRunLoop currentRunLoop].currentMode;
				[_underlyingStream
				    asyncReadIntoBuffer: (void *)""
						 length: 0
					    runLoopMode: runLoopMode];
				return nil;
			}
		}

		if (status == GNUTLS_E_SUCCESS)
			_handshakeDone = true;
		else {
			OFTLSStreamErrorCode errorCode =
			    OFTLSStreamErrorCodeUnknown;

			if (status == GNUTLS_E_CERTIFICATE_VERIFICATION_ERROR)
				errorCode = certificateStatusToErrorCode(
				    gnutls_session_get_verify_cert_status(
				    _session));

			/* FIXME: Map to better errors */
			exception = [OFTLSHandshakeFailedException
			    exceptionWithStream: self
					   host: _host
				      errorCode: errorCode];
		}
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
