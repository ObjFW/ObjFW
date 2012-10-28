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

#import "OFDataArray.h"

@class OFString;

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFDataArray_Hashing_reference;
#ifdef __cplusplus
}
#endif

/*!
 * @brief A category which provides methods to calculate hashes for data arrays.
 */
@interface OFDataArray (Hashing)
/*!
 * @brief Returns the MD5 hash of the data array as an autoreleased OFString.
 *
 * @return The MD5 hash of the data array as an autoreleased OFString
 */
- (OFString*)MD5Hash;

/*!
 * @brief Returns the SHA-1 hash of the data array as an autoreleased OFString.
 *
 * @return The SHA-1 hash of the data array as an autoreleased OFString
 */
- (OFString*)SHA1Hash;
@end
