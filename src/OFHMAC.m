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

#import "OFHMAC.h"
#import "OFSecureData.h"

#import "OFHashAlreadyCalculatedException.h"
#import "OFHashNotCalculatedException.h"
#import "OFInvalidArgumentException.h"

@implementation OFHMAC
@synthesize hashClass = _hashClass;
@synthesize allowsSwappableMemory = _allowsSwappableMemory;

+ (instancetype)HMACWithHashClass: (Class <OFCryptographicHash>)class
	    allowsSwappableMemory: (bool)allowsSwappableMemory
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithHashClass: class
		      allowsSwappableMemory: allowsSwappableMemory]);
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithHashClass: (Class <OFCryptographicHash>)class
	    allowsSwappableMemory: (bool)allowsSwappableMemory
{
	self = [super init];

	_hashClass = class;
	_allowsSwappableMemory = allowsSwappableMemory;

	return self;
}

- (void)dealloc
{
	objc_release(_outerHash);
	objc_release(_innerHash);
	objc_release(_outerHashCopy);
	objc_release(_innerHashCopy);

	[super dealloc];
}

- (void)setKey: (const void *)key length: (size_t)length
{
	void *pool = objc_autoreleasePoolPush();
	size_t blockSize = [_hashClass blockSize];
	OFSecureData *outerKeyPad = [OFSecureData
		    dataWithCount: blockSize
	    allowsSwappableMemory: _allowsSwappableMemory];
	OFSecureData *innerKeyPad = [OFSecureData
		    dataWithCount: blockSize
	    allowsSwappableMemory: _allowsSwappableMemory];
	unsigned char *outerKeyPadItems = outerKeyPad.mutableItems;
	unsigned char *innerKeyPadItems = innerKeyPad.mutableItems;

	objc_release(_outerHash);
	objc_release(_innerHash);
	objc_release(_outerHashCopy);
	objc_release(_innerHashCopy);
	_outerHash = _innerHash = _outerHashCopy = _innerHashCopy = nil;

	@try {
		if (length > blockSize) {
			id <OFCryptographicHash> hash = [_hashClass
			    hashWithAllowsSwappableMemory:
			    _allowsSwappableMemory];
			[hash updateWithBuffer: key length: length];
			[hash calculate];

			length = hash.digestSize;
			if OF_UNLIKELY (length > blockSize)
				length = blockSize;

			memcpy(outerKeyPadItems, hash.digest, length);
			memcpy(innerKeyPadItems, hash.digest, length);
		} else {
			memcpy(outerKeyPadItems, key, length);
			memcpy(innerKeyPadItems, key, length);
		}

		memset(outerKeyPadItems + length, 0, blockSize - length);
		memset(innerKeyPadItems + length, 0, blockSize - length);

		for (size_t i = 0; i < blockSize; i++) {
			outerKeyPadItems[i] ^= 0x5C;
			innerKeyPadItems[i] ^= 0x36;
		}

		_outerHash = objc_retain([_hashClass
		    hashWithAllowsSwappableMemory: _allowsSwappableMemory]);
		_innerHash = objc_retain([_hashClass
		    hashWithAllowsSwappableMemory: _allowsSwappableMemory]);

		[_outerHash updateWithBuffer: outerKeyPadItems
				      length: blockSize];
		[_innerHash updateWithBuffer: innerKeyPadItems
				      length: blockSize];
	} @catch (id e) {
		[outerKeyPad zero];
		[innerKeyPad zero];

		@throw e;
	}

	objc_autoreleasePoolPop(pool);

	_outerHashCopy = [_outerHash copy];
	_innerHashCopy = [_innerHash copy];

	_calculated = false;
}

- (void)updateWithBuffer: (const void *)buffer length: (size_t)length
{
	if (_innerHash == nil)
		@throw [OFInvalidArgumentException exception];

	if (_calculated)
		@throw [OFHashAlreadyCalculatedException
		    exceptionWithObject: self];

	[_innerHash updateWithBuffer: buffer length: length];
}

- (void)calculate
{
	if (_calculated)
		@throw [OFHashAlreadyCalculatedException
		    exceptionWithObject: self];

	if (_outerHash == nil || _innerHash == nil)
		@throw [OFInvalidArgumentException exception];

	[_innerHash calculate];
	[_outerHash updateWithBuffer: _innerHash.digest
			      length: _innerHash.digestSize];
	[_outerHash calculate];
	_calculated = true;
}

- (const unsigned char *)digest
{
	if (!_calculated)
		@throw [OFHashNotCalculatedException exceptionWithObject: self];

	return _outerHash.digest;
}

- (size_t)digestSize
{
	return [_hashClass digestSize];
}

- (void)reset
{
	objc_release(_outerHash);
	objc_release(_innerHash);
	_outerHash = _innerHash = nil;

	_outerHash = [_outerHashCopy copy];
	_innerHash = [_innerHashCopy copy];

	_calculated = false;
}

- (void)zero
{
	objc_release(_outerHash);
	objc_release(_innerHash);
	objc_release(_outerHashCopy);
	objc_release(_innerHashCopy);
	_outerHash = _innerHash = _outerHashCopy = _innerHashCopy = nil;

	_calculated = false;
}
@end
