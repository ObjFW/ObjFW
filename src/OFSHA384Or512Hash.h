/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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
 * @class OFSHA384Or512Hash OFSHA384Or512Hash.h ObjFW/OFSHA384Or512Hash.h
 *
 * @brief A base class for SHA-384 and SHA-512.
 */
@interface OFSHA384Or512Hash: OFObject <OFCryptographicHash>
{
@private
	OFSecureData *_iVarsData;
@protected
	struct {
		uint64_t state[8];
		uint64_t bits[2];
		union {
			unsigned char bytes[128];
			uint64_t words[80];
		} buffer;
		size_t bufferLength;
	} *_iVars;
@private
	bool _allowsSwappableMemory;
	bool _calculated;
	OF_RESERVE_IVARS(OFSHA384Or512Hash, 4)
}
@end

OF_ASSUME_NONNULL_END
