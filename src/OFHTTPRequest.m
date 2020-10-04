/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
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
#import "OFString.h"
#import "OFURL.h"
#import "OFDictionary.h"
#import "OFData.h"
#import "OFArray.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"
#import "OFUnsupportedVersionException.h"

const char *
of_http_request_method_to_string(of_http_request_method_t method)
{
	switch (method) {
	case OF_HTTP_REQUEST_METHOD_OPTIONS:
		return "OPTIONS";
	case OF_HTTP_REQUEST_METHOD_GET:
		return "GET";
	case OF_HTTP_REQUEST_METHOD_HEAD:
		return "HEAD";
	case OF_HTTP_REQUEST_METHOD_POST:
		return "POST";
	case OF_HTTP_REQUEST_METHOD_PUT:
		return "PUT";
	case OF_HTTP_REQUEST_METHOD_DELETE:
		return "DELETE";
	case OF_HTTP_REQUEST_METHOD_TRACE:
		return "TRACE";
	case OF_HTTP_REQUEST_METHOD_CONNECT:
		return "CONNECT";
	}

	return NULL;
}

of_http_request_method_t
of_http_request_method_from_string(OFString *string)
{
	if ([string isEqual: @"OPTIONS"])
		return OF_HTTP_REQUEST_METHOD_OPTIONS;
	if ([string isEqual: @"GET"])
		return OF_HTTP_REQUEST_METHOD_GET;
	if ([string isEqual: @"HEAD"])
		return OF_HTTP_REQUEST_METHOD_HEAD;
	if ([string isEqual: @"POST"])
		return OF_HTTP_REQUEST_METHOD_POST;
	if ([string isEqual: @"PUT"])
		return OF_HTTP_REQUEST_METHOD_PUT;
	if ([string isEqual: @"DELETE"])
		return OF_HTTP_REQUEST_METHOD_DELETE;
	if ([string isEqual: @"TRACE"])
		return OF_HTTP_REQUEST_METHOD_TRACE;
	if ([string isEqual: @"CONNECT"])
		return OF_HTTP_REQUEST_METHOD_CONNECT;

	@throw [OFInvalidArgumentException exception];
}

@implementation OFHTTPRequest
@synthesize URL = _URL, method = _method, headers = _headers;

+ (instancetype)request
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)requestWithURL: (OFURL *)URL
{
	return [[[self alloc] initWithURL: URL] autorelease];
}

- (instancetype)init
{
	self = [super init];

	_method = OF_HTTP_REQUEST_METHOD_GET;
	_protocolVersion.major = 1;
	_protocolVersion.minor = 1;

	return self;
}

- (instancetype)initWithURL: (OFURL *)URL
{
	self = [self init];

	@try {
		_URL = [URL copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_URL release];
	[_headers release];

	[super dealloc];
}

- (void)setRemoteAddress: (const of_socket_address_t *)remoteAddress
{
	_hasRemoteAddress = (remoteAddress != NULL);

	if (_hasRemoteAddress)
		_remoteAddress = *remoteAddress;
}

- (const of_socket_address_t *)remoteAddress
{
	if (_hasRemoteAddress)
		return &_remoteAddress;

	return NULL;
}

- (id)copy
{
	OFHTTPRequest *copy = [[OFHTTPRequest alloc] init];

	@try {
		copy->_method = _method;
		copy->_protocolVersion = _protocolVersion;
		copy.URL = _URL;
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
	    ![request->_URL isEqual: _URL] ||
	    ![request->_headers isEqual: _headers])
		return false;

	if (request.remoteAddress != self.remoteAddress &&
	    !of_socket_address_equal(request.remoteAddress, self.remoteAddress))
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD(hash, _method);
	OF_HASH_ADD(hash, _protocolVersion.major);
	OF_HASH_ADD(hash, _protocolVersion.minor);
	OF_HASH_ADD_HASH(hash, _URL.hash);
	OF_HASH_ADD_HASH(hash, _headers.hash);
	if (_hasRemoteAddress)
		OF_HASH_ADD_HASH(hash, of_socket_address_hash(&_remoteAddress));

	OF_HASH_FINALIZE(hash);

	return hash;
}

- (void)setProtocolVersion: (of_http_request_protocol_version_t)protocolVersion
{
	if (protocolVersion.major != 1 || protocolVersion.minor > 1)
		@throw [OFUnsupportedVersionException exceptionWithVersion:
		    [OFString stringWithFormat: @"%u.%u",
						protocolVersion.major,
						protocolVersion.minor]];

	_protocolVersion = protocolVersion;
}

- (of_http_request_protocol_version_t)protocolVersion
{
	return _protocolVersion;
}

- (void)setProtocolVersionString: (OFString *)string
{
	void *pool = objc_autoreleasePoolPush();
	OFArray *components = [string componentsSeparatedByString: @"."];
	unsigned long long major, minor;
	of_http_request_protocol_version_t protocolVersion;

	if (components.count != 2)
		@throw [OFInvalidFormatException exception];

	major = [components.firstObject unsignedLongLongValue];
	minor = [components.lastObject unsignedLongLongValue];

	if (major > UINT8_MAX || minor > UINT8_MAX)
		@throw [OFOutOfRangeException exception];

	protocolVersion.major = (uint8_t)major;
	protocolVersion.minor = (uint8_t)minor;

	self.protocolVersion = protocolVersion;

	objc_autoreleasePoolPop(pool);
}

- (OFString *)protocolVersionString
{
	return [OFString stringWithFormat: @"%u.%u",
					   _protocolVersion.major,
					   _protocolVersion.minor];
}

- (OFString *)description
{
	void *pool = objc_autoreleasePoolPush();
	const char *method = of_http_request_method_to_string(_method);
	OFString *indentedHeaders, *remoteAddress, *ret;

	indentedHeaders = [_headers.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];

	if (_hasRemoteAddress)
		remoteAddress =
		    of_socket_address_ip_string(&_remoteAddress, NULL);
	else
		remoteAddress = nil;

	ret = [[OFString alloc] initWithFormat:
	    @"<%@:\n\tURL = %@\n"
	    @"\tMethod = %s\n"
	    @"\tHeaders = %@\n"
	    @"\tRemote address = %@\n"
	    @">",
	    self.class, _URL, method, indentedHeaders, remoteAddress];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
