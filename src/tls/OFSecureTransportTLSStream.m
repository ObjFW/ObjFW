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

#import "OFSecureTransportTLSStream.h"

#import "OFAlreadyOpenException.h"
#import "OFNotOpenException.h"
#import "OFReadFailedException.h"
#import "OFTLSHandshakeFailedException.h"
#import "OFWriteFailedException.h"

int _ObjFWTLS_reference;

static OSStatus
readFunc(SSLConnectionRef connection, void *data, size_t *dataLength)
{
	bool incomplete;
	size_t length;

	@try {
		length = [((OFTLSStream *)connection).underlyingStream
		    readIntoBuffer: data
			    length: *dataLength];
	} @catch (OFReadFailedException *e) {
		if (e.errNo == EWOULDBLOCK || e.errNo == EAGAIN) {
			*dataLength = 0;
			return errSSLWouldBlock;
		}

		@throw e;
	}

	incomplete = (length < *dataLength);
	*dataLength = length;

	return (incomplete ? errSSLWouldBlock : noErr);
}

static OSStatus
writeFunc(SSLConnectionRef connection, const void *data, size_t *dataLength)
{
	@try {
		[((OFTLSStream *)connection).underlyingStream
		    writeBuffer: data
			 length: *dataLength];
	} @catch (OFWriteFailedException *e) {
		*dataLength = e.bytesWritten;

		if (e.errNo == EWOULDBLOCK || e.errNo == EAGAIN)
			return errSSLWouldBlock;

		@throw e;
	}

	return noErr;
}

/*
 * Apple deprecated Secure Transport without providing a replacement that can
 * work with any socket. On top of that, their replacement, Network.framework,
 * doesn't support STARTTLS at all.
 */
#if OF_GCC_VERSION >= 402
# pragma GCC diagnostic ignored "-Wdeprecated"
#endif

@implementation OFSecureTransportTLSStream
+ (void)load
{
	if (OFTLSStreamImplementation == Nil)
		OFTLSStreamImplementation = self;
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
	if (_context != NULL)
		[self close];

	[_host release];

	[super dealloc];
}

- (void)close
{
	if (_context == NULL)
		@throw [OFNotOpenException exceptionWithObject: self];

	[_host release];
	_host = nil;

	SSLClose(_context);
#ifdef HAVE_SSLCREATECONTEXT
	CFRelease(_context);
#else
	SSLDisposeContext(_context);
#endif
	_context = NULL;

	[super close];
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer length: (size_t)length
{
	OSStatus status;
	size_t ret;

	if (_context == NULL)
		@throw [OFNotOpenException exceptionWithObject: self];

	status = SSLRead(_context, buffer, length, &ret);
	if (status != noErr && status != errSSLWouldBlock)
		/* FIXME: Translate status to errNo */
		@throw [OFReadFailedException exceptionWithObject: self
						  requestedLength: length
							    errNo: 0];

	return ret;
}

- (size_t)lowlevelWriteBuffer: (const void *)buffer length: (size_t)length
{
	OSStatus status;
	size_t bytesWritten = 0;

	if (_context == NULL)
		@throw [OFNotOpenException exceptionWithObject: self];

	status = SSLWrite(_context, buffer, length, &bytesWritten);
	if (status != noErr && status != errSSLWouldBlock)
		/* FIXME: Translate status to errNo */
		@throw [OFWriteFailedException exceptionWithObject: self
						   requestedLength: length
						      bytesWritten: bytesWritten
							     errNo: 0];

	return bytesWritten;
}

- (bool)lowlevelHasDataInReadBuffer
{
	size_t bufferSize;

	return (_underlyingStream.hasDataInReadBuffer ||
	    (SSLGetBufferedReadSize(_context, &bufferSize) == noErr &&
	    bufferSize > 0));
}

- (void)asyncPerformClientHandshakeWithHost: (OFString *)host
				runLoopMode: (OFRunLoopMode)runLoopMode
{
	static const OFTLSStreamErrorCode initFailedErrorCode =
	    OFTLSStreamErrorCodeInitializationFailed;
	void *pool = objc_autoreleasePoolPush();
	id exception = nil;
	OSStatus status;

	if (_context != NULL)
		@throw [OFAlreadyOpenException exceptionWithObject: self];

#ifdef HAVE_SSLCREATECONTEXT
	if ((_context = SSLCreateContext(kCFAllocatorDefault, kSSLClientSide,
	    kSSLStreamType)) == NULL)
#else
	if (SSLNewContext(false, &_context) != noErr)
#endif
		@throw [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: host
			      errorCode: initFailedErrorCode];

	if (SSLSetIOFuncs(_context, readFunc, writeFunc) != noErr ||
	    SSLSetConnection(_context, self) != noErr)
		@throw [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: host
			      errorCode: initFailedErrorCode];

	_host = [host copy];

	if (_verifiesCertificates)
		if (SSLSetPeerDomainName(_context,
		    _host.UTF8String, _host.UTF8StringLength) != noErr)
			@throw [OFTLSHandshakeFailedException
			    exceptionWithStream: self
					   host: _host
				      errorCode: initFailedErrorCode];

	status = SSLHandshake(_context);

	if (status == errSSLWouldBlock) {
		/*
		 * Theoretically it is possible we block because Secure
		 * Transport cannot write without blocking. But unfortunately,
		 * Secure Transport does not tell us whether it's blocked on
		 * reading or writing. Waiting for the stream to be either
		 * readable or writable doesn't work either, as the stream is
		 * almost always at least ready for one of the two.
		 */
		[_underlyingStream asyncReadIntoBuffer: (void *)""
						length: 0
					   runLoopMode: runLoopMode];
		[_delegate retain];
		objc_autoreleasePoolPop(pool);
		return;
	}

	if (status != noErr)
		/* FIXME: Map to better errors */
		exception = [OFTLSHandshakeFailedException
		    exceptionWithStream: self
				   host: _host
			      errorCode: OFTLSStreamErrorCodeUnknown];

	if ([_delegate respondsToSelector:
	    @selector(stream:didPerformClientHandshakeWithHost:exception:)])
		[_delegate		       stream: self
		    didPerformClientHandshakeWithHost: _host
					    exception: exception];

	objc_autoreleasePoolPop(pool);
}

-      (bool)stream: (OFStream *)stream
  didReadIntoBuffer: (void *)buffer
	     length: (size_t)length
	  exception: (id)exception
{
	if (exception == nil) {
		OSStatus status = SSLHandshake(_context);

		if (status == errSSLWouldBlock)
			return true;

		if (status != noErr)
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
@end
