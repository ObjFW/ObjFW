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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

@class OFData;

/**
 * @protocol OFMessagePackRepresentation OFMessagePackRepresentation.h
 *	     ObjFW/ObjFW.h
 *
 * @brief A protocol implemented by classes that support encoding to a
 *	  MessagePack representation.
 */
@protocol OFMessagePackRepresentation
/**
 * @brief The MessagePack representation of the object as OFData.
 */
@property (readonly, nonatomic) OFData *messagePackRepresentation;
@end

OF_ASSUME_NONNULL_END
