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

#import "OFX509SubjectPublicKeyInfo.h"
#import "OFASN1BitString.h"
#import "OFX509AlgorithmIdentifier.h"
#import "OFArray.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"

@implementation OFX509SubjectPublicKeyInfo: OFASN1Sequence
@synthesize algorithm = _algorithm, subjectPublicKey = _subjectPublicKey;

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

		if (components.count != 2)
			@throw [OFInvalidFormatException exception];

		OFEnumerator *enumerator = [components objectEnumerator];

		OF_KINDOF(OFASN1Value *) value = [enumerator nextObject];
		if (![value isKindOfClass: [OFASN1Sequence class]])
			@throw [OFInvalidFormatException exception];
		_algorithm = objc_retain(
		    [value parsedAs: [OFX509AlgorithmIdentifier class]]);

		value = [enumerator nextObject];
		if (![value isKindOfClass: [OFASN1BitString class]])
			@throw [OFInvalidFormatException exception];
		_subjectPublicKey = objc_retain(value);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_algorithm);
	objc_release(_subjectPublicKey);

	[super dealloc];
}

- (OFString *)description
{
	OFString *algorithm = [_algorithm.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];
	OFString *subjectPublicKey = [_subjectPublicKey.description
	    stringByReplacingOccurrencesOfString: @"\n"
				      withString: @"\n\t"];

	return [OFString stringWithFormat:
	    @"<%@ [%@ %@]:\n"
	    @"\tAlgorithm = %@\n"
	    @"\tSubject public key = %@\n"
	    @">",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber), algorithm,
	    subjectPublicKey];
}
@end
