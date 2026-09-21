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

#import "OFX509TBSCertificate.h"
#import "OFASN1Integer.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFString.h"
#import "OFX509AlgorithmIdentifier.h"
#import "OFX509Extension.h"
#import "OFX509Name.h"
#import "OFX509SubjectPublicKeyInfo.h"
#import "OFX509UniqueIdentifier.h"
#import "OFX509Validity.h"

#import "OFInvalidFormatException.h"
#import "OFUnsupportedVersionException.h"

@implementation OFX509TBSCertificate: OFASN1Sequence
@synthesize version = _version, serialNumber = _serialNumber;
@synthesize signature = _signature, issuer = _issuer, validity = _validity;
@synthesize subject = _subject, subjectPublicKeyInfo = _subjectPublicKeyInfo;
@synthesize issuerUniqueID = _issuerUniqueID;
@synthesize subjectUniqueID = _subjectUniqueID, extensions = _extensions;

- (instancetype)initWithComponents: (OFArray OF_GENERIC(OF_KINDOF(
					OFASN1Value *)) *)components
			  tagClass: (OFASN1TagClass)tagClass
			 tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithComponents: components
				tagClass: tagClass
			       tagNumber: tagNumber];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFEnumerator *enumerator = [components objectEnumerator];

		OF_KINDOF(OFASN1Value *) value = [enumerator nextObject];
		if ([value tagClass] == OFASN1TagClassContextSpecific &&
		    [value tagNumber] == 0) {
			if (![value isKindOfClass:
			    [OFConstructedASN1Value class]] ||
			    [[value components] count] != 1)
				@throw [OFInvalidFormatException exception];

			value = [[value components] firstObject];
			if (![value isKindOfClass: [OFASN1Integer class]])
				@throw [OFInvalidFormatException exception];

			switch ([value longLongValue]) {
			case 0:
				@throw [OFInvalidFormatException exception];
			case 1:
				_version = 2;
				break;
			case 2:
				_version = 3;
				break;
			default:
				@throw [OFUnsupportedVersionException
				    exceptionWithVersion:
				    [value rawValue].description];
			}

			value = [enumerator nextObject];
		}

		if (![value isKindOfClass: [OFASN1Integer class]])
			@throw [OFInvalidFormatException exception];
		_serialNumber = objc_retain(value);

		value = [enumerator nextObject];
		if (![value isKindOfClass: [OFASN1Sequence class]])
			@throw [OFInvalidFormatException exception];
		_signature = objc_retain(
		    [value parsedAs: [OFX509AlgorithmIdentifier class]]);

		value = [enumerator nextObject];
		if (![value isKindOfClass: [OFASN1Sequence class]])
			@throw [OFInvalidFormatException exception];
		_issuer = objc_retain([value parsedAs: [OFX509Name class]]);

		value = [enumerator nextObject];
		if (![value isKindOfClass: [OFASN1Sequence class]])
			@throw [OFInvalidFormatException exception];
		_validity = objc_retain(
		    [value parsedAs: [OFX509Validity class]]);

		value = [enumerator nextObject];
		if (![value isKindOfClass: [OFASN1Sequence class]])
			@throw [OFInvalidFormatException exception];
		_subject = objc_retain([value parsedAs: [OFX509Name class]]);

		value = [enumerator nextObject];
		if (![value isKindOfClass: [OFASN1Sequence class]])
			@throw [OFInvalidFormatException exception];
		_subjectPublicKeyInfo = objc_retain(
		    [value parsedAs: [OFX509SubjectPublicKeyInfo class]]);

		value = [enumerator nextObject];
		if (value != nil &&
		    [value tagClass] == OFASN1TagClassContextSpecific &&
		    [value tagNumber] == 1) {
			_issuerUniqueID = objc_retain(
			    [value parsedAs: [OFX509UniqueIdentifier class]]);
			value = [enumerator nextObject];
		}

		if (value != nil &&
		    [value tagClass] == OFASN1TagClassContextSpecific &&
		    [value tagNumber] == 2) {
			_subjectUniqueID = objc_retain(
			    [value parsedAs: [OFX509UniqueIdentifier class]]);
			value = [enumerator nextObject];
		}

		if (value != nil &&
		    [value tagClass] == OFASN1TagClassContextSpecific &&
		    [value tagNumber] == 3) {
			if (![value isKindOfClass:
			    [OFConstructedASN1Value class]] ||
			    [[value components] count] != 1)
				@throw [OFInvalidFormatException exception];

			value = [[value components] firstObject];
			if (![value isKindOfClass: [OFASN1Sequence class]])
				@throw [OFInvalidFormatException exception];

			OFMutableArray *extensions = [OFMutableArray
			    arrayWithCapacity: [[value components] count]];
			for (OF_KINDOF(OFASN1Value *) iter in
			    [value components]) {
				if (![iter isKindOfClass:
				    [OFASN1Sequence class]])
					@throw [OFInvalidFormatException
					    exception];

				[extensions addObject:
				    [iter parsedAs: [OFX509Extension class]]];
			}
			[extensions makeImmutable];
			_extensions = objc_retain(extensions);

			value = [enumerator nextObject];
		}

		if (value != nil)
			@throw [OFInvalidFormatException exception];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_serialNumber);
	objc_release(_signature);
	objc_release(_issuer);
	objc_release(_validity);
	objc_release(_subject);
	objc_release(_subjectPublicKeyInfo);
	objc_release(_issuerUniqueID);
	objc_release(_subjectUniqueID);
	objc_release(_extensions);

	[super dealloc];
}

- (OFString *)description
{
	OFString *serialNumber = [_serialNumber.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	OFString *signature = [_signature.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	OFString *issuer = [_issuer.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	OFString *validity = [_validity.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	OFString *subject = [_subject.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	OFString *subjectPublicKeyInfo = [_subjectPublicKeyInfo.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	OFString *issuerUniqueID = [_issuerUniqueID.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	OFString *subjectUniqueID = [_subjectUniqueID.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	OFString *extensions = [_extensions.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];

	return [OFString stringWithFormat:
	    @"<%@ [%@ %@]:\n"
	    @"\tVersion = %d\n"
	    @"\tSerial number = %@\n"
	    @"\tSignature = %@\n"
	    @"\tIssuer = %@\n"
	    @"\tValidity = %@\n"
	    @"\tSubject = %@\n"
	    @"\tSubject public key info = %@\n"
	    @"\tIssuer unique ID = %@\n"
	    @"\tSubject unique ID = %@\n"
	    @"\tExtensions = %@\n"
	    @">",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber), _version,
	    serialNumber, signature, issuer, validity, subject,
	    subjectPublicKeyInfo, issuerUniqueID, subjectUniqueID, extensions];
}
@end
