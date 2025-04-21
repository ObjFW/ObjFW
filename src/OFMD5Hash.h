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

#import "OFCryptographicHash.h"

OF_ASSUME_NONNULL_BEGIN

@class OFSecureData;

/**
 * @class OFMD5Hash OFMD5Hash.h ObjFW/ObjFW.h
 *
 * @brief A class which provides methods to create an MD5 hash.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFMD5Hash: OFObject <OFCryptographicHash>
{
	OFSecureData *_iVarsData;
	struct {
		uint32_t state[4];
		uint64_t bits;
		union {
			unsigned char bytes[64];
			uint32_t words[16];
		} buffer;
		size_t bufferLength;
	} *_iVars;
	bool _allowsSwappableMemory;
	bool _calculated;
}
@end

OF_ASSUME_NONNULL_END
