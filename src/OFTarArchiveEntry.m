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

#define OF_TAR_ARCHIVE_ENTRY_M

#include "config.h"

#include <inttypes.h>

#import "OFTarArchiveEntry.h"
#import "OFTarArchiveEntry+Private.h"
#import "OFStream.h"
#import "OFDate.h"

#import "OFNotOpenException.h"
#import "OFOutOfRangeException.h"

static OFString *
stringFromBuffer(const char *buffer, size_t length)
{
	for (size_t i = 0; i < length; i++)
		if (buffer[i] == '\0')
			length = i;

	return [OFString stringWithUTF8String: buffer
				       length: length];
}

static uintmax_t
octalValueFromBuffer(const char *buffer, size_t length, uintmax_t max)
{
	uintmax_t value = [stringFromBuffer(buffer, length) octalValue];

	if (value > max)
		@throw [OFOutOfRangeException exception];

	return value;
}

@implementation OFTarArchiveEntry
@synthesize fileName = _fileName, mode = _mode, size = _size;
@synthesize modificationDate = _modificationDate, type = _type;
@synthesize targetFileName = _targetFileName;
@synthesize owner = _owner, group = _group;
@synthesize deviceMajor = _deviceMajor, deviceMinor = _deviceMinor;

- init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_initWithHeader: (char [512])header
			   stream: (OFStream *)stream
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		_stream = [stream retain];

		_fileName = [stringFromBuffer(header, 100) copy];
		_mode = (uint32_t)octalValueFromBuffer(
		    header + 100, 8, UINT32_MAX);
		_size = _toRead = (uint64_t)octalValueFromBuffer(
		    header + 124, 12, UINT64_MAX);
		_modificationDate = [[OFDate alloc]
		    initWithTimeIntervalSince1970:
		    (of_time_interval_t)octalValueFromBuffer(
		    header + 136, 12, UINTMAX_MAX)];
		_type = header[156];
		_targetFileName = [stringFromBuffer(header + 157, 100) copy];

		if (_type == '\0')
			_type = OF_TAR_ARCHIVE_ENTRY_TYPE_FILE;

		if (memcmp(header + 257, "ustar\0" "00", 8) == 0) {
			OFString *fileName;

			_owner = [stringFromBuffer(header + 265, 32) copy];
			_group = [stringFromBuffer(header + 297, 32) copy];

			_deviceMajor = (uint32_t)octalValueFromBuffer(
			    header + 329, 8, UINT32_MAX);
			_deviceMinor = (uint32_t)octalValueFromBuffer(
			    header + 337, 8, UINT32_MAX);

			fileName = [OFString stringWithFormat: @"%@/%@",
			    stringFromBuffer(header + 345, 155), _fileName];
			[_fileName release];
			_fileName = [fileName copy];
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[self close];

	[_fileName release];
	[_modificationDate release];
	[_targetFileName release];
	[_owner release];
	[_group release];

	[super dealloc];
}

- (size_t)lowlevelReadIntoBuffer: (void *)buffer
			  length: (size_t)length
{
	size_t ret;

	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	if (_atEndOfStream)
		return 0;

	if ((uint64_t)length > _toRead)
		length = (size_t)_toRead;

	ret = [_stream readIntoBuffer: buffer
			       length: length];

	if (ret == 0)
		_atEndOfStream = true;

	_toRead -= ret;

	return ret;
}

- (bool)lowlevelIsAtEndOfStream
{
	if (_stream == nil)
		@throw [OFNotOpenException exceptionWithObject: self];

	return _atEndOfStream;
}

- (bool)hasDataInReadBuffer
{
	return ([super hasDataInReadBuffer] || [_stream hasDataInReadBuffer]);
}

- (void)close
{
	[_stream release];
	_stream = nil;

	[super close];
}

- (void)of_skip
{
	char buffer[512];

	while (_toRead >= 512) {
		[_stream readIntoBuffer: buffer
			    exactLength: 512];
		_toRead -= 512;
	}

	if (_toRead > 0) {
		[_stream readIntoBuffer: buffer
			    exactLength: (size_t)_toRead];
		_toRead = 0;
	}

	if (_size % 512 != 0)
		[_stream readIntoBuffer: buffer
			    exactLength: 512 - ((size_t)_size % 512)];
}

- (OFString *)description
{
	void *pool = objc_autoreleasePoolPush();
	OFString *ret = [OFString stringWithFormat: @"<%@:\n"
	     @"\tFile name = %@\n"
	     @"\tMode = %06o\n"
	     @"\tSize = %" PRIu64 @"\n"
	     @"\tModification date = %@\n"
	     @"\tType = %u\n"
	     @"\tTarget file name = %@\n"
	     @"\tOwner = %@\n"
	     @"\tGroup = %@\n"
	     @"\tDevice major = %" PRIu32 @"\n"
	     @"\tDevice minor = %" PRIu32 @"\n"
	     @">",
	    [self class], _fileName, _mode, _size, _modificationDate, _type,
	    _targetFileName, _owner, _group, _deviceMajor, _deviceMinor];

	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
@end
