/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFDictionary.h"

/**
 * The OFMutableDictionary class is a class for using mutable hash tables.
 */
@interface OFMutableDictionary: OFDictionary {}
/**
 * Sets a key to an object. A key can be any object.
 *
 * \param key The key to set
 * \param obj The object to set the key to
 */
- setObject: (OFObject*)obj
     forKey: (OFObject <OFCopying>*)key;

/**
 * Remove the object with the given key from the dictionary.
 *
 * \param key The key whose object should be removed
 */
- removeObjectForKey: (OFObject*)key;
@end
