/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#include <unistd.h>

#import "OFStream.h"

/**
 * \brief A stream that supports seeking.
 *
 * IMPORTANT: If you want to subclass this, override _seekToOffset:,
 * _seekForwardWithOffset: and _seekToOffsetRelativeToEnd:, but nothing else.
 * Those are not defined in the headers, but do the actual work.
 * OFSeekableStream uses those and makes them work together with the caching of
 * OFStream. If you override these methods without the _ prefix, you *WILL*
 * break caching, get broken results and seek to the wrong position!
 */
@interface OFSeekableStream: OFStream
/**
 * Seeks to the specified absolute offset.
 *
 * \param offset The offset in bytes
 */
- (void)seekToOffset: (off_t)offset;

/**
 * Seeks to the specified offset, relative to the current location.
 *
 * \param offset The offset relative to the current location
 * \return The absolute offset
 */
- (off_t)seekForwardWithOffset: (off_t)offset;

/**
 * Seeks to the specified offset, relative to the end of the stream.
 *
 * \param offset The offset relative to the end of the stream
 * \return The absolute offset
 */
- (off_t)seekToOffsetRelativeToEnd: (off_t)offset;
@end
