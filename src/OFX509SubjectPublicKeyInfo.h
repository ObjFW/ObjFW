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

#import "OFASN1Sequence.h"

OF_ASSUME_NONNULL_BEGIN

@class OFASN1BitString;
@class OFX509AlgorithmIdentifier;

/**
 * @class OFX509SubjectPublicKeyInfo OFX509SubjectPublicKeyInfo.h ObjFW/ObjFW.h
 *
 * @brief An X.509 SubjectPublicKeyInfo.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFX509SubjectPublicKeyInfo: OFASN1Sequence
{
	OFX509AlgorithmIdentifier *_algorithm;
	OFASN1BitString *_subjectPublicKey;
}

/**
 * @brief The algorithm of the subject public key.
 */
@property (readonly, retain, nonatomic) OFX509AlgorithmIdentifier *algorithm;

/**
 * @brief The subject public key.
 */
@property (readonly, retain, nonatomic) OFASN1BitString *subjectPublicKey;
@end

OF_ASSUME_NONNULL_END
