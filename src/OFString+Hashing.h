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

#import "OFString.h"

#ifdef __cplusplus
extern "C" {
#endif
extern int _OFString_Hashing_reference;
#ifdef __cplusplus
}
#endif

/**
 * \brief The OFString (Hashing) category provides methods to calculate hashes
 *	  for strings.
 */
@interface OFString (Hashing)
/**
 * \brief Returns the MD5 hash of the string as an autoreleased OFString.
 *
 * \return The MD5 hash of the string as an autoreleased OFString
 */
- (OFString*)MD5Hash;

/**
 * \brief Returns the SHA1 hash of the string as an autoreleased OFString.
 *
 * \return The SHA1 hash of the string as an autoreleased OFString
 */
- (OFString*)SHA1Hash;
@end
