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

#import "OFASN1Value.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @brief A class representing an unparsed ASN.1 value.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFUnparsedASN1Value: OFASN1Value
{
	bool _constructed;
	OFData *_DEREncodedContents;
}

/**
 * @brief Whether the value if of a constructed type.
 */
@property (readonly, nonatomic, getter=isConstructed) bool constructed;

- (instancetype)initWithTagClass: (OFASN1TagClass)tagClass
		       tagNumber: (OFASN1TagNumber)tagNumber OF_UNAVAILABLE;

/**
 * @brief Returns the unparsed ASN.1 value parsed as a value of the specified
 *	  class.
 *
 * @param class_ The class to parse the value as
 * @return The unparsed ASN.1 value parsed as a value of the specified class
 */
- (OF_KINDOF(OFASN1Value *))parsedAs: (Class)class_;
@end

OF_ASSUME_NONNULL_END
