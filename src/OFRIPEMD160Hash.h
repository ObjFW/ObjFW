/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
 * @class OFRIPEMD160Hash OFRIPEMD160Hash.h ObjFW/OFRIPEMD160Hash.h
 *
 * @brief A class which provides methods to create a RIPEMD-160 hash.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFRIPEMD160Hash: OFObject <OFCryptographicHash>
{
	OFSecureData *_iVarsData;
	struct {
		uint32_t state[5];
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
