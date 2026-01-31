/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#import "OFObject.h"

@class OFString;

#ifndef OF_WINDOWS
# include <dlfcn.h>
typedef void *OFModuleHandle;
#else
# include <windows.h>
typedef HMODULE OFModuleHandle;
#endif

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFModule OFModule.h ObjFW/ObjFW.h
 *
 * @brief A class representing a module (e.g. shared library, plugin, etc.).
 *
 */
@interface OFModule: OFObject
{
	OFModuleHandle _handle;
	OF_RESERVE_IVARS(OFModule, 4)
}

/**
 * @brief Returns the plugin path for a plugin with the specified name.
 *
 * E.g. on ELF systems, it appends `.so`, while on macOS and iOS, it checks if
 * there is a `.bundle` and if so uses the plugin contained in it, but
 * otherwise falls back to appending `.dylib`.
 *
 * This can also be prefixed by a directory.
 *
 * @param name The name to return the plugin path for
 * @return The plugin path
 */
+ (OFString *)pathForPluginWithName: (OFString *)name;

/**
 * @brief Creates a new OFModule by loading the module with the specified path.
 *
 * @param path The path to the module file. If `nil` is specified, the main
 *	       module is returned.
 * @return An new, autoreleased OFModule
 * @throw OFLoadModuleFailedException The module could not be loaded
 */
+ (instancetype)moduleWithPath: (nullable OFString *)path;

/**
 * @brief Initializes an already allocated OFModule by loading the module with
 *	  the specified path.
 *
 * @param path The path to the module file. If `nil` is specified, the main
 *	       module is returned.
 * @return An initialized OFModule
 * @throw OFLoadModuleFailedException The module could not be loaded
 */
- (instancetype)initWithPath: (nullable OFString *)path;

/**
 * @brief Returns the address for the specified symbol, or `nil` if not found.
 *
 * @param symbol The symbol to return the address for
 * @return The address for the specified symbol, or `nil` if not found
 */
- (nullable void *)addressForSymbol: (OFString *)symbol;
@end

OF_ASSUME_NONNULL_END
