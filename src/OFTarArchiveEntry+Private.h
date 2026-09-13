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

#import "OFTarArchiveEntry.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@class OFStream;

OF_DIRECT_MEMBERS
@interface OFTarArchiveEntry ()
- (instancetype)of_init OF_METHOD_FAMILY(init);
- (instancetype)
    of_initWithHeader: (unsigned char [_Nonnull 512])header
       extendedHeader: (nullable OFDictionary *)extendedHeader
	     encoding: (OFStringEncoding)encoding OF_METHOD_FAMILY(init);
- (void)of_writeToStream: (OFStream *)stream
		encoding: (OFStringEncoding)encoding;
@end

OF_ASSUME_NONNULL_END
