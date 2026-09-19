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

#import "OFPrimitiveASN1Value.h"
#import "OFASN1Value+Private.h"
#import "OFData.h"
#import "OFString.h"

#ifdef OF_HAVE_ATOMIC_OPS
# import "OFAtomic.h"
#endif
#ifdef OF_HAVE_THREADS
# import "OFPlainMutex.h"
#endif

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFNotImplementedException.h"

@implementation OFPrimitiveASN1Value
@synthesize rawValue = _rawValue;

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithRawValue: (OFData *)rawValue
			tagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithTagClass: tagClass tagNumber: tagNumber];

	@try {
		if (rawValue.itemSize != 1)
			@throw [OFInvalidFormatException exception];

		_rawValue = [rawValue copy];

#if !defined(OF_HAVE_ATOMIC_OPS) && !defined(OF_AMIGAOS)
		if (OFSpinlockNew(&_spinlock) != 0)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];
#endif
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_rawValue);
	objc_release(_DERRepresentation);

#if !defined(OF_HAVE_ATOMIC_OPS) && !defined(OF_AMIGAOS)
	OFSpinlockFree(&_spinlock);
#endif

	[super dealloc];
}

- (OFData *)DERRepresentation
{
#if defined(OF_HAVE_ATOMIC_OPS)
	if (_DERRepresentation != nil)
		return _DERRepresentation;
#elif defined(OF_AMIGAOS)
	Forbid();
	OFData *DERRepresentation = _DERRepresentation;
	Permit();

	if (DERRepresentation != nil)
		return DERRepresentation;
#else
	OFEnsure(OFSpinlockLock(&_spinlock) == 0);
	OFData *DERRepresentation = _DERRepresentation;
	OFEnsure(OFSpinlockUnlock(&_spinlock) == 0);

	if (DERRepresentation != nil)
		return DERRepresentation;
#endif

	size_t count = _rawValue.count;

	OFMutableData *data = [OFMutableData dataWithCapacity: count + 2];

	unsigned char tag[6];
	[data addItems: tag
		 count: _OFDEREncodeTag(_tagClass, _tagNumber, false, tag)];

	unsigned char length[9];
	[data addItems: length
		 count: _OFDEREncodeLength(count, length)];
	[data addItems: _rawValue.items count: count];

	[data makeImmutable];

#if defined(OF_HAVE_ATOMIC_OPS)
	objc_retain(data);

	if (!OFAtomicPointerCompareAndSwap((void **)&_DERRepresentation,
	    nil, data))
		objc_release(data);
#elif defined(OF_AMIGAOS)
	objc_retain(data);

	Forbid();

	bool release = false;
	if (_DERRepresentation == nil)
		_DERRepresentation = data;
	else
		release = true;

	Permit();

	if (release)
		objc_release(data);
#else
	objc_retain(data);

	OFEnsure(OFSpinlockLock(&_spinlock) == 0);

	bool release = false;
	if (_DERRepresentation == nil)
		_DERRepresentation = data;
	else
		release = true;

	OFEnsure(OFSpinlockUnlock(&_spinlock) == 0);

	if (release)
		objc_release(data);
#endif

	return data;
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tTag class = %@\n"
	    @"\tTag number = %@\n"
	    @"\tRaw value = %@\n"
	    @">",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber), _rawValue];
}

- (OF_KINDOF(OFASN1Value *))parsedAs: (Class)class
{
	if (![class isSubclassOfClass: [OFASN1Value class]])
		@throw [OFInvalidArgumentException exception];

	@try {
		return objc_autoreleaseReturnValue(
		    [[class alloc] initWithRawValue: _rawValue
					   tagClass: _tagClass
					  tagNumber: _tagNumber]);
	} @catch (OFNotImplementedException *e) {
		@throw [OFInvalidArgumentException exception];
	}
}
@end
