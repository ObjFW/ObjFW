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

#include <string.h>

#import "OFGeminiRequest.h"
#import "OFDictionary.h"
#import "OFIRI.h"
#import "OFString.h"

@implementation OFGeminiRequest
@synthesize IRI = _IRI;

+ (instancetype)requestWithIRI: (OFIRI *)IRI
{
	return objc_autoreleaseReturnValue([[self alloc] initWithIRI: IRI]);
}

- (instancetype)initWithIRI: (OFIRI *)IRI
{
	self = [super init];

	@try {
		_IRI = [IRI copy];
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
	OFGeminiRequest *copy = [[OFGeminiRequest alloc] initWithIRI: _IRI];

	@try {
		copy.remoteAddress = self.remoteAddress;
	} @catch (id e) {
		objc_release(copy);
		@throw e;
	}

	return copy;
}

- (bool)isEqual: (id)object
{
	OFGeminiRequest *request;

	if (object == self)
		return true;

	if (![object isKindOfClass: [OFGeminiRequest class]])
		return false;

	request = object;

	if (![request->_IRI isEqual: _IRI])
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

	OFHashAddHash(&hash, _IRI.hash);
	if (_hasRemoteAddress)
		OFHashAddHash(&hash, OFSocketAddressHash(&_remoteAddress));

	OFHashFinalize(&hash);

	return hash;
}

- (OFString *)description
{
	void *pool = objc_autoreleasePoolPush();
	OFString *remoteAddress, *ret;

	if (_hasRemoteAddress)
		remoteAddress = OFSocketAddressString(&_remoteAddress);
	else
		remoteAddress = nil;

	ret = [[OFString alloc] initWithFormat:
	    @"<%@:\n\tIRI = %@\n"
	    @"\tRemote address = %@\n"
	    @">",
	    self.class, _IRI, remoteAddress];

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(ret);
}
@end
