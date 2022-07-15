/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
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
