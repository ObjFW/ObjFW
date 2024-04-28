/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#ifndef __STDC_LIMIT_MACROS
# define __STDC_LIMIT_MACROS
#endif
#ifndef __STDC_CONSTANT_MACROS
# define __STDC_CONSTANT_MACROS
#endif

#include "objfw-defs.h"

#ifdef OF_HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif

#import "OFStream.h"

OF_ASSUME_NONNULL_BEGIN

/** @file */

#if defined(OF_WINDOWS)
typedef __int64 OFStreamOffset;
#elif defined(OF_ANDROID)
typedef long long OFStreamOffset;
#elif defined(OF_MORPHOS)
typedef long long OFStreamOffset;
#elif defined(OF_HAVE_OFF64_T)
typedef off64_t OFStreamOffset;
#else
typedef off_t OFStreamOffset;
#endif

/**
 * @brief From where to seek.
 */
typedef enum {
	/** Seek to the end of the stream + offset. */
	OFSeekSet,
	/** Seek to the current location + offset. */
	OFSeekCurrent,
	/** Seek to the specified byte. */
	OFSeekEnd
} OFSeekWhence;

/**
 * @class OFSeekableStream OFSeekableStream.h ObjFW/OFSeekableStream.h
 *
 * @brief A stream that supports seeking.
 *
 * @note If you want to subclass this, override
 *	 @ref lowlevelSeekToOffset:whence:. OFSeekableStream uses this method
 *	 and makes it work together with the caching of OFStream. If you
 *	 override this methods without the `lowlevel` prefix, you *will* break
 *	 caching, get broken results and seek to the wrong position!
 */
@interface OFSeekableStream: OFStream
{
	OF_RESERVE_IVARS(OFSeekableStream, 4)
}

/**
 * @brief Seeks to the specified offset.
 *
 * @param offset The offset in bytes
 * @param whence From where to seek.
 * @return The new offset form the start of the file
 * @throw OFSeekFailedException Seeking failed
 * @throw OFNotOpenException The stream is not open
 */
- (OFStreamOffset)seekToOffset: (OFStreamOffset)offset
			whence: (OFSeekWhence)whence;

/**
 * @brief Seek the stream on the lowlevel.
 *
 * @warning Do not call this directly!
 *
 * @note Override this method with your actual seek implementation when
 *	 subclassing!
 *
 * @param offset The offset to seek to
 * @param whence From where to seek.
 * @return The new offset from the start of the file
 * @throw OFSeekFailedException Seeking failed
 * @throw OFNotOpenException The stream is not open
 */
- (OFStreamOffset)lowlevelSeekToOffset: (OFStreamOffset)offset
				whence: (OFSeekWhence)whence;
@end

OF_ASSUME_NONNULL_END
