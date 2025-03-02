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

#include "config.h"

#include <errno.h>

#import "OFOpenSSLTLSStream.h"
#import "OFData.h"

#import "OFAlreadyOpenException.h"
#import "OFInitializationFailedException.h"
#import "OFNotOpenException.h"
#import "OFReadFailedException.h"
#import "OFTLSHandshakeFailedException.h"
#import "OFWriteFailedException.h"

#define bufferSize OFOpenSSLTLSStreamBufferSize

int _ObjFWTLS_reference;
static SSL_CTX *clientContext;

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

	SSL_load_error_strings();
	SSL_library_init();

	if ((clientContext = SSL_CTX_new(TLS_client_method())) == NULL ||
	    SSL_CTX_set_default_verify_paths(clientContext) != 1)
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
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_SSL != NULL)
		[self close];

	[_host release];

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

			[_underlyingStream writeBuffer: _buffer length: tmp];
			[_underlyingStream flushWriteBuffer];
		}
	}

	SSL_free(_SSL);
	_SSL = NULL;

	_handshakeDone = false;

	[_host release];
	_host = nil;

	[super close];
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	int ret;
	size_t bytesRead;

	if (!_handshakeDone)
		@throw [OFNotOpenException exceptionWithObject: self];

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
#ifdef HAVE_SSL_HAS_PENDING
	return (_underlyingStream.hasDataInReadBuffer ||
	    SSL_has_pending(_SSL) || BIO_ctrl_pending(_readBIO) > 0);
#else
	return (_underlyingStream.hasDataInReadBuffer ||
	    SSL_pending(_SSL) > 0 || BIO_ctrl_pending(_readBIO) > 0);
#endif
}

- (void)asyncPerformClientHandshakeWithHost: (OFString *)host
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

	if ((_SSL = SSL_new(clientContext)) == NULL) {
		BIO_free(_readBIO);
		BIO_free(_writeBIO);
		@throw [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: host
			      errorCode: initFailedErrorCode];
	}

	SSL_set_bio(_SSL, _readBIO, _writeBIO);
	SSL_set_connect_state(_SSL);

	_host = [host copy];

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

	status = SSL_do_handshake(_SSL);

	while (BIO_ctrl_pending(_writeBIO) > 0) {
		int tmp = BIO_read(_writeBIO, _buffer, bufferSize);

		OFEnsure(tmp >= 0);

		[_underlyingStream writeBuffer: _buffer length: tmp];
		[_underlyingStream flushWriteBuffer];
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
				[_delegate retain];
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
			[_delegate retain];
			objc_autoreleasePoolPop(pool);
			return;
		default:
			/* FIXME: Map to better errors */
			exception = [OFTLSHandshakeFailedException
			    exceptionWithStream: self
					   host: host
				      errorCode: OFTLSStreamErrorCodeUnknown];
			break;
		}
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
		static const OFTLSStreamErrorCode unknownErrorCode =
		    OFTLSStreamErrorCodeUnknown;
		int status;

		OFEnsure(length <= INT_MAX);
		OFEnsure(BIO_write(_readBIO, buffer, (int)length) ==
		    (int)length);

		status = SSL_do_handshake(_SSL);

		while (BIO_ctrl_pending(_writeBIO) > 0) {
			int tmp = BIO_read(_writeBIO, buffer, bufferSize);

			OFEnsure(tmp >= 0);

			[_underlyingStream writeBuffer: _buffer length: tmp];
			[_underlyingStream flushWriteBuffer];
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
			default:
				exception = [OFTLSHandshakeFailedException
				    exceptionWithStream: self
						   host: _host
					      errorCode: unknownErrorCode];
				break;
			}
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
		static const OFTLSStreamErrorCode unknownErrorCode =
		    OFTLSStreamErrorCodeUnknown;
		int status;
		OFRunLoopMode runLoopMode;

		while (BIO_ctrl_pending(_writeBIO) > 0) {
			int tmp = BIO_read(_writeBIO, _buffer, bufferSize);

			OFEnsure(tmp >= 0);

			[_underlyingStream writeBuffer: _buffer length: tmp];
			[_underlyingStream flushWriteBuffer];
		}

		status = SSL_do_handshake(_SSL);

		while (BIO_ctrl_pending(_writeBIO) > 0) {
			int tmp = BIO_read(_writeBIO, _buffer, bufferSize);

			OFEnsure(tmp >= 0);

			[_underlyingStream writeBuffer: _buffer length: tmp];
			[_underlyingStream flushWriteBuffer];
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
			default:
				exception = [OFTLSHandshakeFailedException
				    exceptionWithStream: self
						   host: _host
					      errorCode: unknownErrorCode];
				break;
			}
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
