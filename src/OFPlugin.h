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
#import "OFString.h"

#ifndef _WIN32
typedef void* of_plugin_handle_t;
#else
#include <windows.h>
typedef HMODULE of_plugin_handle_t;
#endif

/**
 * The OFPlugin class provides a system for loading plugins at runtime.
 */
@interface OFPlugin: OFObject
{
	of_plugin_handle_t handle;
}

/**
 * Loads an OFPlugin from a file.
 *
 * \param path Path to the OFPlugin file. The suffix is appended automatically.
 * \return The loaded OFPlugin
 */
+ pluginFromFile: (OFString*)path;
@end
