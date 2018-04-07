/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFCryptoHash.h"

OF_ASSUME_NONNULL_BEGIN

@class OFSecureData;

/*!
 * @class OFRIPEMD160Hash OFRIPEMD160Hash.h ObjFW/OFRIPEMD160Hash.h
 *
 * @brief A class which provides methods to create a RIPEMD-160 hash.
 */
@interface OFRIPEMD160Hash: OFObject <OFCryptoHash>
{
	OFSecureData *_iVarsData;
	struct of_ripemd160_hash_ivars {
		uint32_t state[5];
		uint64_t bits;
		union of_ripemd160_hash_buffer {
			uint8_t bytes[64];
			uint32_t words[16];
		} buffer;
		size_t bufferLength;
	} *_iVars;
	bool _calculated;
}
@end

OF_ASSUME_NONNULL_END
