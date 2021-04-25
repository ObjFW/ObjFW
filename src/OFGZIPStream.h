/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

/**
 * @brief The operating system on which compressed the data.
 */
typedef enum OFGZIPStreamOperatingSystem {
	OFGZIPStreamOperatingSystemFAT	       =   0,
	OFGZIPStreamOperatingSystemAmiga       =   1,
	OFGZIPStreamOperatingSystemVMS	       =   2,
	OFGZIPStreamOperatingSystemUNIX	       =   3,
	OFGZIPStreamOperatingSystemVM_CMS      =   4,
	OFGZIPStreamOperatingSystemAtariTOS    =   5,
	OFGZIPStreamOperatingSystemHPFS	       =   6,
	OFGZIPStreamOperatingSystemMacintosh   =   7,
	OFGZIPStreamOperatingSystemZSystem     =   8,
	OFGZIPStreamOperatingSystemCPM	       =   9,
	OFGZIPStreamOperatingSystemTOPS20      =  10,
	OFGZIPStreamOperatingSystemNTFS	       =  11,
	OFGZIPStreamOperatingSystemQDO	       =  12,
	OFGZIPStreamOperatingSystemAcornRISCOS =  13,
	OFGZIPStreamOperatingSystemUnknown     = 255
} OFGZIPStreamOperatingSystem;

/**
 * @class OFGZIPStream OFGZIPStream.h ObjFW/OFGZIPStream.h
 *
 * @brief A class that handles GZIP compression and decompression transparently
 *	  for an underlying stream.
 */
OF_SUBCLASSING_RESTRICTED
@interface OFGZIPStream: OFStream
{
	OFStream *_stream;
	OFInflateStream *_Nullable _inflateStream;
	enum {
		OFGZIPStreamStateID1,
		OFGZIPStreamStateID2,
		OFGZIPStreamStateCompressionMethod,
		OFGZIPStreamStateFlags,
		OFGZIPStreamStateModificationDate,
		OFGZIPStreamStateExtraFlags,
		OFGZIPStreamStateOperatingSystem,
		OFGZIPStreamStateExtraLength,
		OFGZIPStreamStateExtra,
		OFGZIPStreamStateName,
		OFGZIPStreamStateComment,
		OFGZIPStreamStateHeaderCRC16,
		OFGZIPStreamStateData,
		OFGZIPStreamStateCRC32,
		OFGZIPStreamStateUncompressedSize
	} _state;
	enum {
		OFGZIPStreamFlagText	    = 0x01,
		OFGZIPStreamFlagHeaderCRC16 = 0x02,
		OFGZIPStreamFlagExtra	    = 0x04,
		OFGZIPStreamFlagName	    = 0x08,
		OFGZIPStreamFlagComment	    = 0x10
	} _flags;
	uint8_t _extraFlags;
	OFGZIPStreamOperatingSystem _operatingSystemMadeOn;
	size_t _bytesRead;
	uint8_t _buffer[4];
	OFDate *_Nullable _modificationDate;
	uint16_t _extraLength;
	uint32_t _CRC32, _uncompressedSize;
}

/**
 * @brief The operating system on which the data was compressed.
 *
 * This property is only guaranteed to be available once @ref atEndOfStream is
 * true.
 */
@property (readonly, nonatomic)
    OFGZIPStreamOperatingSystem operatingSystemMadeOn;

/**
 * @brief The modification date of the original file.
 *
 * This property is only guaranteed to be available once @ref atEndOfStream is
 * true.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFDate *modificationDate;

/**
 * @brief Creates a new OFGZIPStream with the specified underlying stream.
 *
 * @param stream The underlying stream for the OFGZIPStream
 * @param mode The mode for the OFGZIPStream. Valid modes are "r" for reading
 *	       and "w" for writing.
 * @return A new, autoreleased OFGZIPStream
 */
+ (instancetype)streamWithStream: (OFStream *)stream mode: (OFString *)mode;

- (instancetype)init OF_UNAVAILABLE;

/**
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
