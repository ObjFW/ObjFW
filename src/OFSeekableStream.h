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
 * @note If you want to subclass this, override
 *	 @ref lowlevelSeekToOffset:whence:. OFSeekableStream uses this method
 *	 and makes it work together with the caching of OFStream. If you
 *	 override this methods without the lowlevel prefix, you <i>will</i>
 *	 break caching, get broken results and seek to the wrong position!
 */
@interface OFSeekableStream: OFStream
/*!
 * @brief Seeks to the specified absolute offset.
 *
 * @param offset The offset in bytes
 * @param whence From where to seek. Possible values are:
 *		  * SEEK_SET: Seek to the specified byte.
 *		  * SEEK_CUR: Seek to the current location + offset.
 *		  * SEEK_END: Seek to the end of the stream + offset.
 */
- (void)seekToOffset: (off_t)offset
	      whence: (int)whence;

/*!
 * @brief Seek the stream on the lowlevel.
 *
 * @warning Do not call this directly!
 *
 * Override this with this method with your actual seek implementation when
 * subclassing!
 *
 * @param offset The offset to seek to
 * @param whence From where to seek. Possible values are:
 *		  * SEEK_SET: Seek to the specified byte.
 *		  * SEEK_CUR: Seek to the current location + offset.
 *		  * SEEK_END: Seek to the end of the stream + offset.
 */
- (void)lowlevelSeekToOffset: (off_t)offset
		      whence: (int)whence;
@end
