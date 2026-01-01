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

#import "OFLHAArchive.h"

OF_ASSUME_NONNULL_BEGIN

OF_DIRECT_MEMBERS
@interface OFLHAArchiveEntry ()
- (instancetype)of_init OF_METHOD_FAMILY(init);
- (instancetype)of_initWithHeader: (uint8_t [_Nonnull 21])header
			   stream: (OFStream *)stream
			 encoding: (OFStringEncoding)encoding
    OF_METHOD_FAMILY(init);
- (void)of_writeToStream: (OFStream *)stream
		encoding: (OFStringEncoding)encoding;
@end

OF_ASSUME_NONNULL_END
