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

#import "OFObject.h"

/**
 * The OFEnumerator class provides methods to enumerate through collections.
 */
@interface OFEnumerator: OFObject {}
/**
 * \return The next object
 */
- (id)nextObject;

/**
 * Resets the enumerator, so the next call to nextObject returns the first
 * object again.
 */
- reset;
@end
