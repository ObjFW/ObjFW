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

#import "OFEnumerator.h"

/**
 * \brief A protocol with methods common for all collections.
 */
@protocol OFCollection
#ifdef OF_HAVE_PROPERTIES
@property (readonly) size_t count;
#endif

/**
 * \return The number of objects in the collection
 */
- (size_t)count;

/**
 * \returns An OFEnumerator to enumerate through all objects of the collection
 */
- (OFEnumerator*)objectEnumerator;
@end
