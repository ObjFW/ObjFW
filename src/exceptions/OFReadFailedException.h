/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OFReadOrWriteFailedException.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OFReadFailedException OFReadFailedException.h ObjFW/ObjFW.h
 *
 * @brief An exception indicating that reading from an object failed.
 */
@interface OFReadFailedException: OFReadOrWriteFailedException
{
	OF_RESERVE_IVARS(OFReadFailedException, 4)
}
@end

OF_ASSUME_NONNULL_END
