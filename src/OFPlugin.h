/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of libobjfw. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFObject.h"

/**
 * The OFPlugin class provides a system for loading plugins at runtime.
 */
@interface OFPlugin: OFObject
{
	void *handle;
}

/**
 * Loads an OFPlugin from a file.
 *
 * \param path Path to the OFPlugin file. The suffix is appended automatically.
 * \return A new autoreleased OFPlugin
 */
+ pluginFromFile: (const char*)path;
@end
