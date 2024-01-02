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

#include <string.h>

#import "OFHTTPRequest.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDictionary.h"
#import "OFIRI.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"
#import "OFUnsupportedVersionException.h"

OFString *
OFHTTPRequestMethodString(OFHTTPRequestMethod method)
{
	switch (method) {
	case OFHTTPRequestMethodOptions:
		return @"OPTIONS";
	case OFHTTPRequestMethodGet:
		return @"GET";
	case OFHTTPRequestMethodHead:
		return @"HEAD";
	case OFHTTPRequestMethodPost:
		return @"POST";
	case OFHTTPRequestMethodPut:
		return @"PUT";
	case OFHTTPRequestMethodDelete:
		return @"DELETE";
	case OFHTTPRequestMethodTrace:
		return @"TRACE";
	case OFHTTPRequestMethodConnect:
		return @"CONNECT";
	}

	return nil;
}

OFHTTPRequestMethod
OFHTTPRequestMethodParseString(OFString *string)
{
	if ([string isEqual: @"OPTIONS"])
		return OFHTTPRequestMethodOptions;
	if ([string isEqual: @"GET"])
		return OFHTTPRequestMethodGet;
	if ([string isEqual: @"HEAD"])
		return OFHTTPRequestMethodHead;
	if ([string isEqual: @"POST"])
		return OFHTTPRequestMethodPost;
	if ([string isEqual: @"PUT"])
		return OFHTTPRequestMethodPut;
	if ([string isEqual: @"DELETE"])
		return OFHTTPRequestMethodDelete;
	if ([string isEqual: @"TRACE"])
		return OFHTTPRequestMethodTrace;
	if ([string isEqual: @"CONNECT"])
		return OFHTTPRequestMethodConnect;

	@throw [OFInvalidFormatException exception];
}

/* Deprecated */
const char *
OFHTTPRequestMethodName(OFHTTPRequestMethod method)
{
	return OFHTTPRequestMethodString(method).UTF8String;
}

/* Deprecated */
OFHTTPRequestMethod
OFHTTPRequestMethodParseName(OFString *string)
{
	return OFHTTPRequestMethodParseString(string);
}

@implementation OFHTTPRequest
@synthesize IRI = _IRI, method = _method, headers = _headers;

+ (instancetype)requestWithIRI: (OFIRI *)IRI
{
	return [[[self alloc] initWithIRI: IRI] autorelease];
}

- (instancetype)initWithIRI: (OFIRI *)IRI
{
	self = [super init];

	@try {
		_IRI = [IRI copy];
		_method = OFHTTPRequestMethodGet;
		_protocolVersion.major = 1;
		_protocolVersion.minor = 1;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	[_IRI release];
	[_headers release];

	[super dealloc];
}

- (void)setRemoteAddress: (const OFSocketAddress *)remoteAddress
{
	_hasRemoteAddress = (remoteAddress != NULL);

	if (_hasRemoteAddress)
		_remoteAddress = *remoteAddress;
}

- (const OFSocketAddress *)remoteAddress
{
	if (_hasRemoteAddress)
		return &_remoteAddress;

	return NULL;
}

- (id)copy
{
	OFHTTPRequest *copy = [[OFHTTPRequest alloc] initWithIRI: _IRI];

	@try {
		copy->_method = _method;
		copy->_protocolVersion = _protocolVersion;
		copy.headers = _headers;
		copy.remoteAddress = self.remoteAddress;
	} @catch (id e) {
		[copy release];
		@throw e;
	}

	return copy;
}

- (bool)isEqual: (id)object
{
	OFHTTPRequest *request;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFHTTPRequest class]])
		return false;

	request = object;

	if (request->_method != _method ||
	    request->_protocolVersion.major != _protocolVersion.major ||
	    request->_protocolVersion.minor != _protocolVersion.minor ||
	    ![request->_IRI isEqual: _IRI] ||
	    ![request->_headers isEqual: _headers])
		return false;

	if (request.remoteAddress != self.remoteAddress &&
	    !OFSocketAddressEqual(request.remoteAddress, self.remoteAddress))
		return false;

	return true;
}

- (unsigned long)hash
{
	unsigned long hash;

	OFHashInit(&hash);

	OFHashAddByte(&hash, _method);
	OFHashAddByte(&hash, _protocolVersion.major);
	OFHashAddByte(&hash, _protocolVersion.minor);
	OFHashAddHash(&hash, _IRI.hash);
	OFHashAddHash(&hash, _headers.hash);
	if (_hasRemoteAddress)
		OFHashAddHash(&hash, OFSocketAddressHash(&_remoteAddress));

	OFHashFinalize(&hash);

	return hash;
}

- (void)setProtocolVersion: (OFHTTPRequestProtocolVersion)protocolVersion
{
	if (protocolVersion.major != 1 || protocolVersion.minor > 1)
		@throw [OFUnsupportedVersionException exceptionWithVersion:
		    [OFString stringWithFormat: @"%hhu.%hhu",
						protocolVersion.major,
						protocolVersion.minor]];

	_protocolVersion = protocolVersion;
}

- (OFHTTPRequestProtocolVersion)protocolVersion
{
	return _protocolVersion;
}

- (void)setProtocolVersionString: (OFString *)string
{
	void *pool = objc_autoreleasePoolPush();
	OFArray *components = [string componentsSeparatedByString: @"."];
	unsigned long long major, minor;
	OFHTTPRequestProtocolVersion protocolVersion;

	if (components.count != 2)
		@throw [OFInvalidFormatException exception];

	major = [components.firstObject unsignedLongLongValue];
	minor = [components.lastObject unsignedLongLongValue];

	if (major > UCHAR_MAX || minor > UCHAR_MAX)
		@throw [OFOutOfRangeException exception];

	protocolVersion.major = (unsigned char)major;
	protocolVersion.minor = (unsigned char)minor;

	self.protocolVersion = protocolVersion;

	objc_autoreleasePoolPop(pool);
}

- (OFString *)protocolVersionString
{
	return [OFString stringWithFormat: @"%hhu.%hhu",
					   _protocolVersion.major,
					   _protocolVersion.minor];
}

- (OFString *)description
{
	void *pool = objc_autoreleasePoolPush();
	OFString *method = OFHTTPRequestMethodString(_method);
	OFString *indentedHeaders, *remoteAddress, *ret;

	indentedHeaders = [_headers.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];

	if (_hasRemoteAddress)
		remoteAddress = OFSocketAddressString(&_remoteAddress);
	else
		remoteAddress = nil;

	ret = [[OFString alloc] initWithFormat:
	    @"<%@:\n\tIRI = %@\n"
	    @"\tMethod = %@\n"
	    @"\tHeaders = %@\n"
	    @"\tRemote address = %@\n"
	    @">",
	    self.class, _IRI, method, indentedHeaders, remoteAddress];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
