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

@class OFASN1Integer;

/**
 * @class OFX509BasicConstraints OFX509BasicConstraints.h ObjFW/ObjFW.h
 *
 * @brief An X.509 BasicConstraints.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFX509BasicConstraints: OFASN1Sequence
{
	bool _CA;
	OFASN1Integer *_Nullable _pathLengthConstraint;
}

/**
 * @brief Whether the certificate is a CA
 */
@property (readonly, nonatomic, getter=isCA) bool CA;

/**
 * @brief The maximum number intermediate certificates that may follow this
 *	  certificate
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    OFASN1Integer *pathLengthConstraint;
@end

OF_ASSUME_NONNULL_END
