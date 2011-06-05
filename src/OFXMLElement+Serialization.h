/*
 * Copyright (c) 2008, 2009, 2010, 2011
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFXMLElement.h"

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFXMLElement_Serialization_reference;
#ifdef __cplusplus
}
#endif

/**
 * \brief A category that provides methods for deserializing objects.
 */
@interface OFXMLElement (OFSerialization)
/**
 * \brief Deserializes the receiver into an object.
 *
 * \return The deserialized object
 */
- (id)objectByDeserializing;
@end
