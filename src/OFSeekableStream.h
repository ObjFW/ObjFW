/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012
 *   Jonathan Schleifer <js@webkeks.org>
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

#include <sys/types.h>

#import "OFStream.h"

/*!
 * @brief A stream that supports seeking.
 *
 * @note If you want to subclass this, override lowlevelSeekToOffset:,
 *	 lowlevelSeekForwardWithOffset: and lowlevelSeekToOffsetRelativeToEnd:,
 *	 but nothing else, as they do the actual work. OFSeekableStream uses
 *	 those and makes them work together with the caching of OFStream.
 *	 If you override these methods without the lowlevel prefix, you
 *	 <i>will</i> break caching, get broken results and seek to the wrong
 *	 position!
 */
@interface OFSeekableStream: OFStream
/*!
 * @brief Seeks to the specified absolute offset.
 *
 * @param offset The offset in bytes
 */
- (void)seekToOffset: (off_t)offset;

/*!
 * @brief Seeks to the specified offset, relative to the current location.
 *
 * @param offset The offset relative to the current location
 * @return The absolute offset
 */
- (off_t)seekForwardWithOffset: (off_t)offset;

/*!
 * @brief Seeks to the specified offset, relative to the end of the stream.
 *
 * @param offset The offset relative to the end of the stream
 * @return The absolute offset
 */
- (off_t)seekToOffsetRelativeToEnd: (off_t)offset;

/*!
 * @brief Seek the stream on the lowlevel.
 *
 * @warning Do not call this directly!
 *
 * Override this with this method with your actual seek implementation when
 * subclassing!
 *
 * @param offset The offset to seek to
 */
- (void)lowlevelSeekToOffset: (off_t)offset;

/*!
 * @brief Seek the stream on the lowlevel.
 *
 * @warning Do not call this directly!
 *
 * Override this with this method with your actual seek implementation when
 * subclassing!
 *
 * @param offset The offset to seek forward to
 */
- (off_t)lowlevelSeekForwardWithOffset: (off_t)offset;

/*!
 * @brief Seek the stream on the lowlevel.
 *
 * @warning Do not call this directly!
 *
 * Override this with this method with your actual seek implementation when
 * subclassing!
 *
 * @param offset The offset to seek to, relative to the end
 */
- (off_t)lowlevelSeekToOffsetRelativeToEnd: (off_t)offset;
@end
