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

#import "OFASN1Value.h"

OF_ASSUME_NONNULL_BEGIN

@interface OFASN1Value ()
- (instancetype)of_initWithTagClass: (OFASN1TagClass)tagClass
			  tagNumber: (OFASN1TagNumber)tagNumber
			constructed: (bool)constructed
		 DEREncodedContents: (OFData *)DEREncodedContents
    OF_METHOD_FAMILY(init);
@end

extern size_t _OFDEREncodeLength(size_t length,
    unsigned char buffer[_Nonnull 9]) OF_VISIBILITY_INTERNAL;
extern int64_t _OFDERDecodeInteger(const unsigned char *buffer, size_t length)
    OF_VISIBILITY_INTERNAL;
extern size_t _OFDEREncodeInteger(int64_t value,
    unsigned char buffer[_Nonnull 8]) OF_VISIBILITY_INTERNAL;

OF_ASSUME_NONNULL_END
