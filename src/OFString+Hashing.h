/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFString.h"

extern int _OFString_Hashing_reference;

/**
 * The OFString (OFHashing) category provides methods to calculate hashes for
 * strings.
 */
@interface OFString (Hashing)
/**
 * \return The MD5 hash of the string as an autoreleased OFString
 */
- (OFString*)MD5Hash;

/**
 * \return The SHA1 hash of the string as an autoreleased OFString
 */
- (OFString*)SHA1Hash;
@end
