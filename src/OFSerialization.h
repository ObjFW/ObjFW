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

@class OFConstantString;
@class OFXMLElement;

/**
 * @protocol OFSerialization OFSerialization.h ObjFW/OFSerialization.h
 *
 * @brief A protocol for serializing objects.
 */
@protocol OFSerialization
/**
 * @brief The object serialized into an XML element.
 */
@property (readonly, nonatomic) OFXMLElement *XMLElementBySerializing;

/**
 * @brief Initializes the object with the specified XML element serialization.
 *
 * @param element An OFXMLElement with the serialized object
 * @return An initialized object
 * @throw OFInvalidArgumentException The specified element is not valid
 *				     serialization
 */
- (instancetype)initWithSerialization: (OFXMLElement *)element;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern OFConstantString *const OFSerializationNS;
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
