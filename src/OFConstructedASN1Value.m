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

#import "OFConstructedASN1Value.h"
#import "OFASN1Set.h"
#import "OFASN1Value+Private.h"
#import "OFArray.h"
#import "OFCountedSet.h"
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
#import "OFOutOfRangeException.h"

@implementation OFConstructedASN1Value
@synthesize components = _components;

+ (instancetype)valueWithComponents: (OFArray OF_GENERIC(OF_KINDOF(
					 OFASN1Value *)) *)components
			   tagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithComponents: components
		      tagClass: tagClass
		     tagNumber: tagNumber]);
}

- (instancetype)initWithComponents: (OFArray OF_GENERIC(OF_KINDOF(
					OFASN1Value *)) *)components
			  tagClass: (OFASN1TagClass)tagClass
			 tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithTagClass: tagClass tagNumber: tagNumber];

	@try {
		_components = [components copy];

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

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber
{
	OF_INVALID_INIT_METHOD
}

- (void)dealloc
{
	objc_release(_components);
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

	void *pool = objc_autoreleasePoolPush();

	OFMutableArray *componentRepresentations =
	    [OFMutableArray arrayWithCapacity: _components.count];
	size_t totalLength = 0;
	for (OF_KINDOF(OFASN1Value *) component in _components) {
		OFData *componentRepresentation = [component DERRepresentation];
		[componentRepresentations addObject: componentRepresentation];

		size_t componentLength = componentRepresentation.count;
		if (SIZE_MAX - totalLength < componentLength)
			@throw [OFOutOfRangeException exception];

		totalLength += componentLength;
	}

	if (SIZE_MAX - totalLength < 2)
		@throw [OFOutOfRangeException exception];

	OFMutableData *data = [OFMutableData dataWithCapacity: totalLength + 2];

	unsigned char tag[6];
	[data addItems: tag
		 count: _OFDEREncodeTag(_tagClass, _tagNumber, true, tag)];

	unsigned char length[9];
	[data addItems: length
		 count: _OFDEREncodeLength(totalLength, length)];

	for (OFData *componentRepresentation in componentRepresentations)
		[data addItems: componentRepresentation.items
			 count: componentRepresentation.count];

	[data makeImmutable];

	objc_retain(data);

	objc_autoreleasePoolPop(pool);

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

	return objc_autoreleaseReturnValue(data);
}

- (OFString *)description
{
	OFString *components = [_components.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];

	return [OFString stringWithFormat:
	    @"<%@:\n"
	    @"\tTag class = %@\n"
	    @"\tTag number = %@\n"
	    @"\tComponents = %@\n"
	    @">",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber), components];
}

- (OF_KINDOF(OFConstructedASN1Value *))parsedAs: (Class)class
{
	if (![class isSubclassOfClass: [OFConstructedASN1Value class]])
		@throw [OFInvalidArgumentException exception];

	return objc_autoreleaseReturnValue(
	    [[class alloc] initWithComponents: _components
				     tagClass: _tagClass
				    tagNumber: _tagNumber]);
}
@end
