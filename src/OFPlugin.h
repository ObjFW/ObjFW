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

#import "OFModule.h"

OF_ASSUME_NONNULL_BEGIN

typedef OFModuleHandle OFPluginHandle
    OF_DEPRECATED(ObjFW, 1, 3, "Use OFModuleHandle instead");

/**
 * @class OFPlugin OFPlugin.h ObjFW/ObjFW.h
 *
 * @deprecated Use OFModule instead.
 *
 * @brief A class representing a loaded plugin (shared library).
 */
OF_SUBCLASSING_RESTRICTED
OF_DEPRECATED(ObjFW, 1, 3, "Use OFModule instead")
@interface OFPlugin: OFModule
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
+ (OFString *)pathForName: (OFString *)name;

/**
 * @brief Creates a new OFPlugin by loading the plugin with the specified path.
 *
 * @param path The path to the plugin file. If `nil` is specified, the main
 *	       binary is returned as a plugin.
 * @return An new, autoreleased OFPlugin
 * @throw OFLoadPluginFailedException The plugin could not be loaded
 */
+ (instancetype)pluginWithPath: (nullable OFString *)path;
@end

OF_ASSUME_NONNULL_END
