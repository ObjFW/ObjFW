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

#import <Foundation/Foundation.h>

#import "OFSecureTransportTLSStream.h"
#import "OFArray.h"
#import "OFSecureTransportKeychain.h"
#import "OFSecureTransportX509Certificate.h"

#include <Security/SecCertificate.h>
#include <Security/SecIdentity.h>

#import "OFAlreadyOpenException.h"
#import "OFInvalidArgumentException.h"
#import "OFNotOpenException.h"
#import "OFReadFailedException.h"
#import "OFTLSHandshakeFailedException.h"
#import "OFWriteFailedException.h"

/*
 * Apple deprecated Secure Transport without providing a replacement that can
 * work with any socket. On top of that, their replacement, Network.framework,
 * doesn't support STARTTLS at all.
 */
#if OF_GCC_VERSION >= 402
# pragma GCC diagnostic ignored "-Wdeprecated"
#endif

int _ObjFWTLS_reference;

static OFTLSStreamErrorCode
statusToErrorCode(OSStatus status)
{
	switch (status) {
	case errSSLXCertChainInvalid:
		return OFTLSStreamErrorCodeCertificateVerificationFailed;
	}

	return OFTLSStreamErrorCodeUnknown;
}

static OSStatus
readFunc(SSLConnectionRef connection, void *data, size_t *dataLength)
{
	OFStream *underlyingStream =
	    ((OFTLSStream *)connection).underlyingStream;
	bool incomplete;
	size_t length;

	@try {
		length = [underlyingStream readIntoBuffer: data
						   length: *dataLength];
	} @catch (OFReadFailedException *e) {
		if (e.errNo == EWOULDBLOCK || e.errNo == EAGAIN) {
			*dataLength = 0;
			return errSSLWouldBlock;
		}

		@throw e;
	}

	if (length == 0 && underlyingStream.atEndOfStream)
		return errSSLClosedAbort;

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

	@try {
		SSLClose(_context);
	} @catch (OFWriteFailedException *e) {
		if (e.errNo != EPIPE)
			@throw e;
	}

#ifdef HAVE_SSLCREATECONTEXT
	[(id)_context release];
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

- (void)of_asyncPerformHandshakeWithHost: (OFString *)host
				  server: (bool)server
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
	if ((_context = SSLCreateContext(kCFAllocatorDefault,
	    (server ? kSSLServerSide : kSSLClientSide),
	    kSSLStreamType)) == NULL)
#else
	if (SSLNewContext(server, &_context) != noErr)
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
	_server = server;

	if (!server && _verifiesCertificates)
		if (SSLSetPeerDomainName(_context,
		    _host.UTF8String, _host.UTF8StringLength) != noErr)
			@throw [OFTLSHandshakeFailedException
			    exceptionWithStream: self
					   host: _host
				      errorCode: initFailedErrorCode];

	if (_certificateChain.count > 0) {
		bool first = true;
		NSMutableArray *array;
		SecCertificateRef firstCertificate;

		array = [NSMutableArray
		    arrayWithCapacity: _certificateChain.count];
		if (array == nil)
			@throw [OFTLSHandshakeFailedException
			    exceptionWithStream: self
					   host: _host
				      errorCode: initFailedErrorCode];

		firstCertificate = ((OFSecureTransportX509Certificate *)
		    _certificateChain.firstObject).of_certificate;

		if (CFGetTypeID(firstCertificate) == SecIdentityGetTypeID())
			[array addObject: (id)firstCertificate];
#ifndef OF_IOS
		else {
			SecKeychainRef keychain = [[OFSecureTransportKeychain
			    temporaryKeychain] keychain];
			SecIdentityRef identity;

			if (SecIdentityCreateWithCertificate(keychain,
			    firstCertificate, &identity) != noErr)
				@throw [OFTLSHandshakeFailedException
				    exceptionWithStream: self
						   host: _host
					      errorCode: initFailedErrorCode];

			[array addObject: (id)identity];
			[(id)identity release];
		}
#else
		else
			@throw [OFInvalidArgumentException exception];
#endif

		for (OFSecureTransportX509Certificate *certificate in
		    _certificateChain) {
			if (first) {
				first = false;
				continue;
			}

			[array addObject: (id)certificate.of_certificate];
		}

		SSLSetCertificate(_context, (CFArrayRef)array);
	}

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
			      errorCode: statusToErrorCode(status)];

	if (server) {
		if ([(id <OFObject>)_delegate respondsToSelector: @selector(
		    streamDidPerformServerHandshake:exception:)])
			[_delegate streamDidPerformServerHandshake: self
							 exception: exception];
	} else {
		if ([(id <OFObject>)_delegate respondsToSelector: @selector(
		    stream:didPerformClientHandshakeWithHost:exception:)])
			[_delegate		       stream: self
			    didPerformClientHandshakeWithHost: _host
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
		OSStatus status = SSLHandshake(_context);

		if (status == errSSLWouldBlock)
			return true;

		if (status != noErr)
			exception = [OFTLSHandshakeFailedException
			    exceptionWithStream: self
					   host: _host
				      errorCode: statusToErrorCode(status)];
	}

	if (_server) {
		if ([(id <OFObject>)_delegate respondsToSelector: @selector(
		    streamDidPerformServerHandshake:exception:)])
			[_delegate streamDidPerformServerHandshake: self
							 exception: exception];
	} else {
		if ([(id <OFObject>)_delegate respondsToSelector: @selector(
		    stream:didPerformClientHandshakeWithHost:exception:)])
			[_delegate		       stream: self
			    didPerformClientHandshakeWithHost: _host
						    exception: exception];
	}

	[_delegate release];

	return false;
}
@end
