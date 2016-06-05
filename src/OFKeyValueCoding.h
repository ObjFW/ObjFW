/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
 *   Jonathan Schleifer <js@heap.zone>
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

@class OFString;

/*!
 * @protocol OFKeyValueCoding OFKeyValueCoding.h ObjFW/OFKeyValueCoding.h
 *
 * @brief A protocol for Key Value Coding.
 *
 * Key Value Coding makes it possible to access properties dynamically using
 * the interface described by this protocol.
 */
@protocol OFKeyValueCoding
/*!
 * @brief Return the value for the specified key
 *
 * @param key The key of the value to return
 * @return The value for the specified key
 */
- (id)valueForKey: (OFString*)key;

/*!
 * @brief This is called by @ref valueForKey: if the specified key does not
 *	  exist.
 *
 * By default, this throws an @ref OFUndefinedKeyException.
 *
 * @param key The undefined key of the value to return
 * @return The value for the specified undefined key
 */
- (id)valueForUndefinedKey: (OFString*)key;

/*!
 * @brief Set the value for the specified key
 *
 * @param value The value for the specified key
 * @param key The key of the value to set
 */
- (void)setValue: (id)value
	  forKey: (OFString*)key;

/*!
 * @brief This is called by @ref setValue:forKey: if the specified key does not
 *	  exist.
 *
 * By default, this throws an @ref OFUndefinedKeyException.
 *
 * @param value The value for the specified undefined key
 * @param key The undefined key of the value to set
 */
-  (void)setValue: (id)value
  forUndefinedKey: (OFString*)key;
@end
