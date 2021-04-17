/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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
typedef void *OFPluginHandle;
#else
# include <windows.h>
# define OF_RTLD_LAZY 0
# define OF_RTLD_NOW  0
typedef HMODULE OFPluginHandle;
#endif

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFPlugin OFPlugin.h ObjFW/OFPlugin.h
 *
 * @brief Provides a system for loading plugins at runtime.
 */
@interface OFPlugin: OFObject
{
	OFPluginHandle _pluginHandle;
	OF_RESERVE_IVARS(OFPlugin, 4)
}

/**
 * @brief Loads a plugin from a file.
 *
 * @param path Path to the plugin file. The suffix is appended automatically.
 * @return The loaded plugin
 */
+ (OF_KINDOF(OFPlugin *))pluginWithPath: (OFString *)path;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern OFPluginHandle OFDlopen(OFString *path, int flags);
extern void *OFDlsym(OFPluginHandle handle, const char *symbol);
extern OFString *_Nullable OFDlerror(void);
extern void OFDlclose(OFPluginHandle handle);
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
