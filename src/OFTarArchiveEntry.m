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

#include "config.h"

#include <inttypes.h>

#import "OFTarArchiveEntry.h"
#import "OFTarArchiveEntry+Private.h"
#import "OFStream.h"
#import "OFDate.h"

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
+ (instancetype)entryWithFileName: (OFString *)fileName
{
	return [[[self alloc] initWithFileName: fileName] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_initWithHeader: (char [512])header
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFString *targetFileName;

		_fileName = [stringFromBuffer(header, 100) copy];
		_mode = (uint32_t)octalValueFromBuffer(
		    header + 100, 8, UINT32_MAX);
		_size = (uint64_t)octalValueFromBuffer(
		    header + 124, 12, UINT64_MAX);
		_modificationDate = [[OFDate alloc]
		    initWithTimeIntervalSince1970:
		    (of_time_interval_t)octalValueFromBuffer(
		    header + 136, 12, UINTMAX_MAX)];
		_type = header[156];

		targetFileName = stringFromBuffer(header + 157, 100);
		if ([targetFileName length] > 0)
			_targetFileName = [targetFileName copy];

		if (_type == '\0')
			_type = OF_TAR_ARCHIVE_ENTRY_TYPE_FILE;

		if (memcmp(header + 257, "ustar\0" "00", 8) == 0) {
			OFString *prefix;

			_owner = [stringFromBuffer(header + 265, 32) copy];
			_group = [stringFromBuffer(header + 297, 32) copy];

			_deviceMajor = (uint32_t)octalValueFromBuffer(
			    header + 329, 8, UINT32_MAX);
			_deviceMinor = (uint32_t)octalValueFromBuffer(
			    header + 337, 8, UINT32_MAX);

			prefix = stringFromBuffer(header + 345, 155);
			if ([prefix length] > 0) {
				OFString *fileName = [OFString
				    stringWithFormat: @"%@/%@",
						      prefix, _fileName];
				[_fileName release];
				_fileName = [fileName copy];
			}
		}

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithFileName: (OFString *)fileName
{
	self = [super init];

	@try {
		_fileName = [fileName copy];
		_type = OF_TAR_ARCHIVE_ENTRY_TYPE_FILE;
		_mode = 0644;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_fileName release];
	[_modificationDate release];
	[_targetFileName release];
	[_owner release];
	[_group release];

	[super dealloc];
}

- copy
{
	return [self retain];
}

- mutableCopy
{
	OFTarArchiveEntry *copy = [[OFMutableTarArchiveEntry alloc]
	    initWithFileName: _fileName];

	@try {
		copy->_mode = _mode;
		copy->_size = _size;
		copy->_modificationDate = [_modificationDate copy];
		copy->_type = _type;
		copy->_targetFileName = [_targetFileName copy];
		copy->_owner = [_owner copy];
		copy->_group = [_group copy];
		copy->_deviceMajor = _deviceMajor;
		copy->_deviceMinor = _deviceMinor;
	} @catch (id e) {
		[copy release];
		@throw e;
	}

	return copy;
}

- (OFString *)fileName
{
	return _fileName;
}

- (uint32_t)mode
{
	return _mode;
}

- (uint64_t)size
{
	return _size;
}

- (OFDate *)modificationDate
{
	return _modificationDate;
}

- (of_tar_archive_entry_type_t)type
{
	return _type;
}

- (OFString *)targetFileName
{
	return _targetFileName;
}

- (OFString *)owner
{
	return _owner;
}

- (OFString *)group
{
	return _group;
}

- (uint32_t)deviceMajor
{
	return _deviceMajor;
}

- (uint32_t)deviceMinor
{
	return _deviceMinor;
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
