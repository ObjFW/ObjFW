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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

@class OFData;

/**
 * @protocol OFMessagePackRepresentation \
 *	     OFMessagePackRepresentation.h ObjFW/OFMessagePackRepresentation.h
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
