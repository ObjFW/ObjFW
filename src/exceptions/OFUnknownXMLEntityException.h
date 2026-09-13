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

#import "OFException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFUnknownXMLEntityException OFUnknownXMLEntityException.h
 *	  ObjFW/ObjFW.h
 *
 * @brief An exception indicating that a parser encountered an unknown XML
 *	  entity.
 */
@interface OFUnknownXMLEntityException: OFException
{
	OFString *_entityName;
	OF_RESERVE_IVARS(OFUnknownXMLEntityException, 4)
}

/**
 * @brief The name of the unknown XML entity.
 */
@property (readonly, nonatomic) OFString *entityName;

/**
 * @brief Creates a new, autoreleased unknown XML entity exception.
 *
 * @param entityName The name of the unknown XML entity
 * @return A new, autoreleased unknown XML entity exception
 */
+ (instancetype)exceptionWithEntityName: (OFString *)entityName;

+ (instancetype)exception OF_UNAVAILABLE;

/**
 * @brief Initializes an already allocated unknown XML entity exception.
 *
 * @param entityName The name of the unknown XML entity
 * @return An initialized unknown XML entity exception
 */
- (instancetype)initWithEntityName: (OFString *)entityName
    OF_DESIGNATED_INITIALIZER;

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
