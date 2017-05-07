/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
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

#ifndef OF_WINDOWS
# include <dlfcn.h>
# define OF_RTLD_LAZY RTLD_LAZY
# define OF_RTLD_NOW  RTLD_NOW
typedef void *of_plugin_handle_t;
#else
# include <windows.h>
# define OF_RTLD_LAZY 0
# define OF_RTLD_NOW  0
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
+ (OF_KINDOF(OFPlugin *))pluginFromFile: (OFString *)path;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern of_plugin_handle_t of_dlopen(OFString *path, int flags);
extern void *of_dlsym(of_plugin_handle_t handle, const char *symbol);
extern void of_dlclose(of_plugin_handle_t handle);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
