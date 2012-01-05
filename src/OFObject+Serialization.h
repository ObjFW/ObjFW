/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
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

#import "OFObject.h"

@class OFString;

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFObject_Serialization_reference;
#ifdef __cplusplus
}
#endif

/**
 * \brief A category that provides methods for serializing objects.
 */
@interface OFObject (OFSerialization)
/**
 * \brief Creates a string by serializing the receiver.
 *
 * \return The object serialized as a string
 */
- (OFString*)stringBySerializing;
@end
