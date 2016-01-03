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

#import "OFObject.h"

@class OFString;

#ifndef _WIN32
typedef void* of_plugin_handle_t;
#else
# include <windows.h>
typedef HMODULE of_plugin_handle_t;
#endif

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFPlugin OFPlugin.h ObjFW/OFPlugin.h
 *
 * @brief Provides a system for loading plugins at runtime.
 */
@interface OFPlugin: OFObject
{
	of_plugin_handle_t _handle;
}

/*!
 * @brief Loads a plugin from a file.
 *
 * @param path Path to the plugin file. The suffix is appended automatically.
 * @return The loaded plugin
 */
+ (OF_KINDOF(OFPlugin*))pluginFromFile: (OFString*)path;
@end

OF_ASSUME_NONNULL_END
