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

#import "OFX509KeyUsage.h"
#import "OFASN1BitString.h"
#import "OFASN1ObjectIdentifier.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFString.h"

#import "OFInvalidFormatException.h"

@implementation OFX509KeyUsage
- (instancetype)initWithDEREncodedContents: (OFData *)DEREncodedContents
				  tagClass: (OFASN1TagClass)tagClass
				 tagNumber: (OFASN1TagNumber)tagNumber
{
	self = [super initWithDEREncodedContents: DEREncodedContents
					tagClass: tagClass
				       tagNumber: tagNumber];

	@try {
		size_t bitCount = self.bitCount;
		if (bitCount == 0 || bitCount > 9)
			@throw [OFInvalidFormatException exception];

		OFData *bits = self.bits;
		_keyUsage = *(uint8_t *)[bits itemAtIndex: 0] << 1;
		if (bitCount == 9)
			_keyUsage |= *(uint8_t *)[bits itemAtIndex: 1] >> 7;

		if (!(_keyUsage & (0x100 >> (bitCount - 1))))
			@throw [OFInvalidFormatException exception];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (bool)digitalSignature
{
	return (_keyUsage & (0x100 >> 0));
}

- (bool)nonRepudiation
{
	return (_keyUsage & (0x100 >> 1));
}

- (bool)keyEncipherment
{
	return (_keyUsage & (0x100 >> 2));
}

- (bool)dataEncipherment
{
	return (_keyUsage & (0x100 >> 3));
}

- (bool)keyAgreement
{
	return (_keyUsage & (0x100 >> 4));
}

- (bool)keyCertSign
{
	return (_keyUsage & (0x100 >> 5));
}

- (bool)CRLSign
{
	return (_keyUsage & (0x100 >> 6));
}

- (bool)encipherOnly
{
	return (_keyUsage & (0x100 >> 7));
}

- (bool)decipherOnly
{
	return (_keyUsage & (0x100 >> 8));
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@ [%@ %@]:\n"
	    @"\tdigitalSignature = %@\n"
	    @"\tnonRepudiation = %@\n"
	    @"\tkeyEncipherment = %@\n"
	    @"\tdataEncipherment = %@\n"
	    @"\tkeyAgreement = %@\n"
	    @"\tkeyCertSign = %@\n"
	    @"\tCRLSign = %@\n"
	    @"\tencipherOnly = %@\n"
	    @"\tdecipherOnly = %@\n"
	    @">",
	    self.class, OFASN1TagClassDescription(_tagClass),
	    OFASN1TagNumberDescription(_tagClass, _tagNumber),
	    (self.digitalSignature ? @"true" : @"false"),
	    (self.nonRepudiation ? @"true" : @"false"),
	    (self.keyEncipherment ? @"true" : @"false"),
	    (self.dataEncipherment ? @"true" : @"false"),
	    (self.keyAgreement ? @"true" : @"false"),
	    (self.keyCertSign ? @"true" : @"false"),
	    (self.CRLSign ? @"true" : @"false"),
	    (self.encipherOnly ? @"true" : @"false"),
	    (self.decipherOnly ? @"true" : @"false")];
}
@end
