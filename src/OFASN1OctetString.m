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

#import "OFASN1OctetString.h"
#import "OFData.h"

@implementation OFASN1OctetString
+ (instancetype)octetStringWithOctets: (OFData *)octets
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] initWithOctets: octets]);
}

+ (instancetype)octetStringWithOctets: (OFData *)octets
			     tagClass: (OFASN1TagClass)tagClass
			    tagNumber: (OFASN1TagNumber)tagNumber
{
	return objc_autoreleaseReturnValue([[self alloc]
	    initWithOctets: octets
		  tagClass: tagClass
		 tagNumber: tagNumber]);
}

- (instancetype)initWithOctets: (OFData *)octets
{
	return [self initWithOctets: octets
			   tagClass: OFASN1TagClassUniversal
			  tagNumber: OFASN1TagNumberOctetString];
}

- (instancetype)initWithOctets: (OFData *)octets
		      tagClass: (OFASN1TagClass)tagClass
		     tagNumber: (OFASN1TagNumber)tagNumber
{
	return [self initWithDEREncodedContents: octets
				       tagClass: tagClass
				      tagNumber: tagNumber];
}

- (OFData *)octets
{
	return _DEREncodedContents;
}
@end
