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
	return objc_autoreleaseReturnValue([[self alloc] initWithIRI: IRI]);
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
		objc_release(self);
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
	objc_release(_IRI);
	objc_release(_headers);

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
		objc_release(copy);
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
	OFHTTPRequestProtocolVersion protocolVersion;

	if (components.count != 2)
		@throw [OFInvalidFormatException exception];

	protocolVersion.major = [components.firstObject unsignedCharValue];
	protocolVersion.minor = [components.lastObject unsignedCharValue];

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

	return objc_autoreleaseReturnValue(ret);
}
@end
