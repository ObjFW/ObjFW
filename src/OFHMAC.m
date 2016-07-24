/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFHMAC.h"

#import "OFHashAlreadyCalculatedException.h"
#import "OFInvalidArgumentException.h"

@implementation OFHMAC
+ (instancetype)HMACWithHashClass: (Class <OFCryptoHash>)class
{
	return [[[self alloc] initWithHashClass: class] autorelease];
}

- initWithHashClass: (id <OFCryptoHash>)class
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		_outerHash = [[class cryptoHash] retain];
		_innerHash = [[class cryptoHash] retain];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_outerHash release];
	[_innerHash release];

	[super dealloc];
}

- (void)setKey: (const void*)key
	length: (size_t)length
{
	size_t blockSize = [[_outerHash class] blockSize];
	uint8_t outerKeyPad[blockSize], innerKeyPad[blockSize];

	if (length > blockSize) {
		void *pool = objc_autoreleasePoolPush();
		id <OFCryptoHash> hash = [[_outerHash class] cryptoHash];

		[hash updateWithBuffer: key
				length: length];

		length = [[hash class] digestSize];
		if OF_UNLIKELY (length > blockSize)
			length = blockSize;

		memcpy(outerKeyPad, [hash digest], length);
		memcpy(innerKeyPad, [hash digest], length);

		objc_autoreleasePoolPop(pool);
	} else {
		memcpy(outerKeyPad, key, length);
		memcpy(innerKeyPad, key, length);
	}

	memset(outerKeyPad + length, 0, blockSize - length);
	memset(innerKeyPad + length, 0, blockSize - length);

	for (size_t i = 0; i < blockSize; i++) {
		outerKeyPad[i] ^= 0x5C;
		innerKeyPad[i] ^= 0x36;
	}

	[_outerHash updateWithBuffer: outerKeyPad
			      length: blockSize];
	[_innerHash updateWithBuffer: innerKeyPad
			      length: blockSize];

	_keySet = true;
}

- (void)updateWithBuffer: (const void*)buffer
		  length: (size_t)length
{
	if (!_keySet)
		@throw [OFInvalidArgumentException exception];

	if (_calculated)
		@throw [OFHashAlreadyCalculatedException
		    exceptionWithObject: self];

	[_innerHash updateWithBuffer: buffer
			      length: length];
}

- (const uint8_t*)digest
{
	if (_calculated)
		return [_outerHash digest];

	[_outerHash updateWithBuffer: [_innerHash digest]
			      length: [[_innerHash class] digestSize]];
	_calculated = true;

	return [_outerHash digest];
}

- (size_t)digestSize
{
	return [[_outerHash class] digestSize];
}

- (void)reset
{
	[_outerHash reset];
	[_innerHash reset];

	_keySet = false;
	_calculated = false;
}
@end
