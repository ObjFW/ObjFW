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

#if defined(OF_WINDOWS)
typedef __int64 of_offset_t;
#elif defined(OF_ANDROID)
typedef long long of_offset_t;
#elif defined(OF_MORPHOS) && !defined(OF_IXEMUL)
typedef signed long long of_offset_t;
#elif defined(OF_HAVE_OFF64_T)
typedef off64_t of_offset_t;
#else
typedef off_t of_offset_t;
#endif

/*!
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
/*!
 * @brief Seeks to the specified absolute offset.
 *
 * @param offset The offset in bytes
 * @param whence From where to seek.@n
 *		 Possible values are:
 *		 Value      | Description
 *		 -----------|---------------------------------------
 *		 `SEEK_SET` | Seek to the specified byte
 *		 `SEEK_CUR` | Seek to the current location + offset
 *		 `SEEK_END` | Seek to the end of the stream + offset
 * @return The new offset form the start of the file
 */
- (of_offset_t)seekToOffset: (of_offset_t)offset
		     whence: (int)whence;

/*!
 * @brief Seek the stream on the lowlevel.
 *
 * @warning Do not call this directly!
 *
 * @note Override this method with your actual seek implementation when
 *	 subclassing!
 *
 * @param offset The offset to seek to
 * @param whence From where to seek.@n
 *		 Possible values are:
 *		 Value      | Description
 *		 -----------|---------------------------------------
 *		 `SEEK_SET` | Seek to the specified byte
 *		 `SEEK_CUR` | Seek to the current location + offset
 *		 `SEEK_END` | Seek to the end of the stream + offset
 * @return The new offset from the start of the file
 */
- (of_offset_t)lowlevelSeekToOffset: (of_offset_t)offset
			     whence: (int)whence;
@end

OF_ASSUME_NONNULL_END
