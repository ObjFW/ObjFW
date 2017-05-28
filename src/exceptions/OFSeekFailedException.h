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

#import "OFException.h"
#import "OFSeekableStream.h"

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFSeekFailedException \
 *	  OFSeekFailedException.h ObjFW/OFSeekFailedException.h
 *
 * @brief An exception indicating that seeking in a stream failed.
 */
@interface OFSeekFailedException: OFException
{
	OFSeekableStream *_stream;
	of_offset_t _offset;
	int _whence, _errNo;
}

/*!
 * The stream for which seeking failed.
 */
@property (readonly, nonatomic) OFSeekableStream *stream;

/*!
 * The offset to which seeking failed.
 */
@property (readonly, nonatomic) of_offset_t offset;

/*!
 * To what the offset is relative.
 */
@property (readonly, nonatomic) int whence;

/*!
 * The errno of the error that occurred.
 */
@property (readonly, nonatomic) int errNo;

+ (instancetype)exception OF_UNAVAILABLE;

/*!
 * @brief Creates a new, autoreleased seek failed exception.
 *
 * @param stream The stream for which seeking failed
 * @param offset The offset to which seeking failed
 * @param whence To what the offset is relative
 * @return A new, autoreleased seek failed exception
 */
+ (instancetype)exceptionWithStream: (OFSeekableStream *)stream
			     offset: (of_offset_t)offset
			     whence: (int)whence;

/*!
 * @brief Creates a new, autoreleased seek failed exception.
 *
 * @param stream The stream for which seeking failed
 * @param offset The offset to which seeking failed
 * @param whence To what the offset is relative
 * @param errNo The errno of the error that occurred
 * @return A new, autoreleased seek failed exception
 */
+ (instancetype)exceptionWithStream: (OFSeekableStream *)stream
			     offset: (of_offset_t)offset
			     whence: (int)whence
			      errNo: (int)errNo;

- init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated seek failed exception.
 *
 * @param stream The stream for which seeking failed
 * @param offset The offset to which seeking failed
 * @param whence To what the offset is relative
 * @return An initialized seek failed exception
 */
- initWithStream: (OFSeekableStream *)stream
	  offset: (of_offset_t)offset
	  whence: (int)whence;

/*!
 * @brief Initializes an already allocated seek failed exception.
 *
 * @param stream The stream for which seeking failed
 * @param offset The offset to which seeking failed
 * @param whence To what the offset is relative
 * @param errNo The errno of the error that occurred
 * @return An initialized seek failed exception
 */
- initWithStream: (OFSeekableStream *)stream
	  offset: (of_offset_t)offset
	  whence: (int)whence
	   errNo: (int)errNo;
@end

OF_ASSUME_NONNULL_END
