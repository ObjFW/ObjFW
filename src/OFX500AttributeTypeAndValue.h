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

/** @file */

@class OFASN1ObjectIdentifier;

/**
 * @brief An X.500 AttributeType.
 */
typedef OFASN1ObjectIdentifier OFX500AttributeType;

/**
 * @brief An X.500 AttributeValue.
 */
typedef OF_KINDOF(OFASN1Value *) OFX500AttributeValue;

/**
 * @class OFX500AttributeTypeAndValue OFX500AttributeTypeAndValue.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An X.500 AttributeTypeAndValue.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFX500AttributeTypeAndValue: OFASN1Sequence
{
	OFX500AttributeType *_attributeType;
	OFX500AttributeValue _attributeValue;
}

/**
 * @brief The AttributeType of the AttributeTypeAndValue.
 */
@property (readonly, retain, nonatomic) OFX500AttributeType *attributeType;

/**
 * @brief The AttributeValue of the AttributeTypeAndValue.
 */
@property (readonly, retain, nonatomic) OFX500AttributeValue attributeValue;
@end

OF_ASSUME_NONNULL_END
