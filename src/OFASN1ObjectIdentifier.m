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

#import "OFASN1ObjectIdentifier.h"
#import "OFASN1Value+Private.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OFString.h"

#import "OFInvalidArgumentException.h"
#import "OFInvalidFormatException.h"
#import "OFOutOfRangeException.h"

static OFMutableDictionary OF_GENERIC(OFString *, OFString *) *names;

@implementation OFASN1ObjectIdentifier
+ (void)initialize
{
	if (self != [OFASN1ObjectIdentifier class])
		return;

	names = [[OFMutableDictionary alloc] initWithKeysAndObjects:
	    @"0", @"itu-t",
	    @"1", @"iso",
	    @"1.2", @"member-body",
	    @"1.2.840", @"us",
	    @"1.2.820.10045", @"ansi-x962",
	    @"1.2.820.10045.4", @"signatures",
	    @"1.2.820.10045.4.3", @"ecdsa-with-SHA2",
	    @"1.2.840.10045.4.3.1", @"ecdsa-with-SHA224",
	    @"1.2.840.10045.4.3.2", @"ecdsa-with-SHA256",
	    @"1.2.840.10045.4.3.3", @"ecdsa-with-SHA384",
	    @"1.2.840.10045.4.3.4", @"ecdsa-with-SHA512",
	    @"1.2.840.113549", @"rsadsi",
	    @"1.2.840.113549.1", @"pkcs",
	    @"1.2.840.113549.1.1", @"pkcs-1",
	    @"1.2.840.113549.1.1.1", @"rsaEncryption",
	    @"1.2.840.113549.1.1.11", @"sha256WithRSAEncryption",
	    @"1.2.840.113549.1.1.12", @"sha384WithRSAEncryption",
	    @"1.2.840.113549.1.1.13", @"sha512WithRSAEncryption",
	    @"1.2.840.113549.1.1.14", @"sha224WithRSAEncryption",
	    @"1.3", @"identified-organization",
	    @"1.3.6", @"dod",
	    @"1.3.6.1", @"internet",
	    @"1.3.6.1.4", @"private",
	    @"1.3.6.1.4.1", @"enterprise",
	    @"1.3.6.1.4.1.66927", @"jonathan-schleifer",
	    @"1.3.6.1.4.1.66927.1", @"objfw",
	    @"1.3.101", @"thawte",
	    @"1.3.101.112", @"id-Ed25519",
	    @"1.3.101.113", @"id-Ed448",
	    @"2", @"joint-iso-itu-t",
	    @"2.5", @"ds",
	    @"2.5.4", @"attributeType",
	    @"2.5.4.3", @"commonName",
	    @"2.5.29", @"certificateExtension",
	    @"2.5.29.14", @"subjectKeyIdentifier",
	    @"2.5.29.17", @"subjectAltName",
	    @"2.5.29.18", @"issuerAltName",
	    @"2.5.29.35", @"authorityKeyIdentifier",
	    nil];
}

+ (void)registerName: (OFString *)name forStringValue: (OFString *)stringValue
{
	@synchronized (names) {
		[names setObject: name forKey: stringValue];
	}
}

+ (OFString *)nameForStringValue: (OFString *)stringValue
{
	@synchronized (names) {
		return [names objectForKey: stringValue];
	}
}

+ (instancetype)identifierWithArcs: (OFArray OF_GENERIC(OFNumber *) *)arcs
{
	return objc_autoreleaseReturnValue([[self alloc] initWithArcs: arcs]);
}

+ (instancetype)identifierWithArcs: (OFArray OF_GENERIC(OFNumber *) *)arcs
			  tagClass: (OFASN1TagClass)tagClass
			 tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithArcs: arcs
		tagClass: tagClass
	       tagNumber: tagNumber]);
}

+ (instancetype)identifierWithString: (OFString *)string
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithString: string]);
}

+ (instancetype)identifierWithString: (OFString *)string
			    tagClass: (OFASN1TagClass)tagClass
			   tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithString: string
		  tagClass: tagClass
		 tagNumber: tagNumber]);
}

- (instancetype)initWithArcs: (OFArray OF_GENERIC(OFNumber *) *)arcs
{
	return [self initWithArcs: arcs
			 tagClass: OFASN1TagClassUniversal
			tagNumber: OFASN1TagNumberObjectIdentifier];
}

static void
addBase128ValueToData(OFMutableData *data, unsigned long long value)
{
	if (value <= 0x7F) {
		unsigned char byte = value & 0x7F;
		[data addItem: &byte];
		return;
	}

	size_t startPos = data.count;

	while (value > 0) {
		unsigned char byte = (value & 0x7F) | 0x80;
		value >>= 7;
		[data addItem: &byte];
	}

	size_t count = data.count - startPos;
	unsigned char *items = (unsigned char *)data.mutableItems + startPos;
	for (size_t i = 0, j = count - 1; i < count / 2; i++, j--) {
		items[i] ^= items[j];
		items[j] ^= items[i];
		items[i] ^= items[j];
	}

	items[count - 1] &= 0x7F;
}

- (instancetype)initWithArcs: (OFArray OF_GENERIC(OFNumber *) *)arcs
		    tagClass: (OFASN1TagClass)tagClass
		   tagNumber: (OFASN1TagNumber)tagNumber
{
	void *pool = objc_autoreleasePoolPush();

	OFMutableData *DEREncodedContents;
	@try {
		size_t count = arcs.count;
		if (count < 2)
			@throw [OFInvalidFormatException exception];

		unsigned long long value;
		unsigned long long arc2 =
		    [[arcs objectAtIndex: 1] unsignedLongLongValue];
		switch ([[arcs objectAtIndex: 0]
		    unsignedLongLongValue]) {
		case 0:
			if (arc2 > 39)
				@throw [OFInvalidArgumentException exception];

			value = 0;
			break;
		case 1:
			if (arc2 > 39)
				@throw [OFInvalidArgumentException exception];

			value = 40;
			break;
		case 2:
			value = 80;
			break;
		default:
			@throw [OFInvalidFormatException exception];
		}

		DEREncodedContents = [OFMutableData data];

		if (ULLONG_MAX - value < arc2)
			@throw [OFOutOfRangeException exception];

		addBase128ValueToData(DEREncodedContents, value + arc2);
		for (size_t i = 2; i < count; i++)
			addBase128ValueToData(DEREncodedContents,
			    [[arcs objectAtIndex: i] unsignedLongLongValue]);

		[DEREncodedContents makeImmutable];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithDEREncodedContents: DEREncodedContents
				       tagClass: tagClass
				      tagNumber: tagNumber];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)initWithString: (OFString *)string
{
	return [self initWithString: string
			   tagClass: OFASN1TagClassUniversal
			  tagNumber: OFASN1TagNumberObjectIdentifier];
}

- (instancetype)initWithString: (OFString *)string
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber
{
	void *pool = objc_autoreleasePoolPush();

	OFArray OF_GENERIC(OFNumber *) *arcs;
	@try {
		arcs = [[string componentsSeparatedByString: @"."]
		    valueForKey: @"unsignedLongLongValue"];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	self = [self initWithArcs: arcs
			 tagClass: tagClass
			tagNumber: tagNumber];

	objc_autoreleasePoolPop(pool);

	return self;
}

- (instancetype)initWithDEREncodedContents: (OFData *)DEREncodedContents
				  tagClass: (OFASN1TagClass)tagClass
				 tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithDEREncodedContents: DEREncodedContents
					tagClass: tagClass
				       tagNumber: tagNumber];

	@try {
		const unsigned char *items = DEREncodedContents.items;
		size_t count = DEREncodedContents.count;

		if (count == 0)
			@throw [OFInvalidArgumentException exception];

		bool first = true;
		for (size_t i = 0; i < count; i++) {
			if (first && items[i] == 0x80)
				@throw [OFInvalidFormatException exception];

			first = !(items[i] & 0x80);
		}

		if (items[count - 1] & 0x80)
			@throw [OFInvalidFormatException exception];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (OFArray OF_GENERIC(OFNumber *) *)arcs
{
	OFMutableArray OF_GENERIC(OFNumber *) *arcs =
	    [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	const unsigned char *items = _DEREncodedContents.items;
	size_t count = _DEREncodedContents.count;

	unsigned long long value = 0;
	uint_fast8_t bits = 0;
	for (size_t i = 0; i < count; i++) {
		if ((ULLONG_MAX >> 7) < value || UINT_FAST8_MAX - bits < 7)
			@throw [OFOutOfRangeException exception];

		value = (value << 7) | (items[i] & 0x7F);
		bits += 7;

		if (items[i] & 0x80)
			continue;

		if (arcs.count == 0) {
			if (value < 40)
				[arcs addObject: [OFNumber numberWithInt: 0]];
			else if (value < 80) {
				[arcs addObject: [OFNumber numberWithInt: 1]];
				value -= 40;
			} else {
				[arcs addObject: [OFNumber numberWithInt: 2]];
				value -= 80;
			}
		}

		[arcs addObject: [OFNumber numberWithUnsignedLongLong: value]];

		value = 0;
		bits = 0;
	}

	[arcs makeImmutable];

	objc_autoreleasePoolPop(pool);

	return arcs;
}

- (OFString *)stringValue
{
	void *pool = objc_autoreleasePoolPush();
	OFString *stringValue = [[self.arcs valueForKey: @"stringValue"]
	    componentsJoinedByString: @"."];

	objc_retain(stringValue);

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(stringValue);
}

- (OFString *)description
{
	void *pool = objc_autoreleasePoolPush();
	OFArray OF_GENERIC(OFNumber *) *arcs = self.arcs;

	OFMutableString *identifier = [OFMutableString string];
	OFMutableString *namedIdentifier = [OFMutableString string];
	for (OFNumber *arc in arcs) {
		if (identifier.length > 0)
			[identifier appendString: @"."];
		if (namedIdentifier.length > 0)
			[namedIdentifier appendString: @"."];

		OFString *stringValue = arc.stringValue;
		[identifier appendString: stringValue];

		OFString *name =
		    [OFASN1ObjectIdentifier nameForStringValue: identifier];
		if (name != nil)
			[namedIdentifier appendFormat: @"%@(%@)",
						       name, stringValue];
		else
			[namedIdentifier appendString: stringValue];
	}

	OFString *ret = [[OFString alloc] initWithFormat:
	    @"<%@ [%@ %@]: %@>",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber), namedIdentifier];

	objc_autoreleasePoolPop(pool);

	return objc_autoreleaseReturnValue(ret);
}
@end
