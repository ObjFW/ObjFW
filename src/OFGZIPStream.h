/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018
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

#import "OFStream.h"
#import "OFDate.h"

@class OFInflateStream;

OF_ASSUME_NONNULL_BEGIN

/*!
 * @class OFGZIPStream OFGZIPStream.h ObjFW/OFGZIPStream.h
 *
 * @brief A class that handles GZIP compression and decompression transparently
 *	  for an underlying stream.
 */
@interface OFGZIPStream: OFStream
{
	OFStream *_stream;
	OFInflateStream *_Nullable _inflateStream;
	enum of_gzip_stream_state {
		OF_GZIP_STREAM_ID1,
		OF_GZIP_STREAM_ID2,
		OF_GZIP_STREAM_COMPRESSION_METHOD,
		OF_GZIP_STREAM_FLAGS,
		OF_GZIP_STREAM_MODIFICATION_TIME,
		OF_GZIP_STREAM_EXTRA_FLAGS,
		OF_GZIP_STREAM_OS,
		OF_GZIP_STREAM_EXTRA_LENGTH,
		OF_GZIP_STREAM_EXTRA,
		OF_GZIP_STREAM_NAME,
		OF_GZIP_STREAM_COMMENT,
		OF_GZIP_STREAM_HEADER_CRC16,
		OF_GZIP_STREAM_DATA,
		OF_GZIP_STREAM_CRC32,
		OF_GZIP_STREAM_UNCOMPRESSED_SIZE
	} _state;
	enum of_gzip_stream_flags {
		OF_GZIP_STREAM_FLAG_TEXT	 = 0x01,
		OF_GZIP_STREAM_FLAG_HEADER_CRC16 = 0x02,
		OF_GZIP_STREAM_FLAG_EXTRA	 = 0x04,
		OF_GZIP_STREAM_FLAG_NAME	 = 0x08,
		OF_GZIP_STREAM_FLAG_COMMENT	 = 0x10
	} _flags;
	uint8_t _extraFlags;
	enum of_gzip_stream_os {
		OF_GZIP_STREAM_OS_FAT		=   0,
		OF_GZIP_STREAM_OS_AMIGA		=   1,
		OF_GZIP_STREAM_OS_VMS		=   2,
		OF_GZIP_STREAM_OS_UNIX		=   3,
		OF_GZIP_STREAM_OS_VM_CMS	=   4,
		OF_GZIP_STREAM_OS_ATARI_TOS	=   5,
		OF_GZIP_STREAM_OS_HPFS		=   6,
		OF_GZIP_STREAM_OS_MACINTOSH	=   7,
		OF_GZIP_STREAM_OS_Z_SYSTEM	=   8,
		OF_GZIP_STREAM_OS_CP_M		=   9,
		OF_GZIP_STREAM_OS_TOPS_20	=  10,
		OF_GZIP_STREAM_OS_NTFS		=  11,
		OF_GZIP_STREAM_OS_QDO		=  12,
		OF_GZIP_STREAM_OS_ACORN_RISC_OS	=  13,
		OF_GZIP_STREAM_OS_UNKNOWN	= 255
	} _OS;
	size_t _bytesRead;
	uint8_t _buffer[4];
	OFDate *_Nullable _modificationDate;
	uint16_t _extraLength;
	uint32_t _CRC32, _uncompressedSize;
}

/*!
 * @brief Creates a new OFGZIPStream with the specified underlying stream.
 *
 * @param stream The underlying stream for the OFGZIPStream
 * @param mode The mode for the OFGZIPStream. Valid modes are "r" for reading
 *	       and "w" for writing.
 * @return A new, autoreleased OFGZIPStream
 */
+ (instancetype)streamWithStream: (OFStream *)stream
			    mode: (OFString *)mode;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated OFGZIPStream with the specified
 *	  underlying stream.
 *
 * @param stream The underlying stream for the OFGZIPStream
 * @param mode The mode for the OFGZIPStream. Valid modes are "r" for reading
 *	       and "w" for writing.
 * @return An initialized OFGZIPStream
 */
- (instancetype)initWithStream: (OFStream *)stream
			  mode: (OFString *)mode OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
