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

#import "OFLoadModuleFailedException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFLoadPluginFailedException OFLoadPluginFailedException.h
 *	  ObjFW/ObjFW.h
 *
 * @deprecated Use OFLoadModuleFailedException instead.
 *
 * @brief An exception indicating a plugin could not be loaded.
 */
OF_DEPRECATED(ObjFW, 1, 3, "Use OFLoadModuleFailedException instead")
@interface OFLoadPluginFailedException: OFLoadModuleFailedException
@end

OF_ASSUME_NONNULL_END
