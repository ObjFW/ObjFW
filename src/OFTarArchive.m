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

#import "OFTarArchive.h"
#import "OFTarArchiveEntry.h"
#import "OFTarArchiveEntry+Private.h"
#import "OFStream.h"
#ifdef OF_HAVE_FILES
# import "OFFile.h"
#endif

#import "OFInvalidFormatException.h"

@implementation OFTarArchive: OFObject
+ (instancetype)archiveWithStream: (OFStream *)stream
{
	return [[[self alloc] initWithStream: stream] autorelease];
}

#ifdef OF_HAVE_FILES
+ (instancetype)archiveWithPath: (OFString *)path
{
	return [[[self alloc] initWithPath: path] autorelease];
}
#endif

- initWithStream: (OFStream *)stream
{
	self = [super init];

	_stream = [stream retain];

	return self;
}

#ifdef OF_HAVE_FILES
- initWithPath: (OFString *)path
{
	self = [super init];

	@try {
		_stream = [[OFFile alloc] initWithPath: path
						  mode: @"rb"];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

- (void)dealloc
{
	[_stream release];
	[_lastReturnedEntry release];

	[super dealloc];
}

- (OFTarArchiveEntry *)nextEntry
{
	union {
		char c[512];
		uint32_t u32[512 / sizeof(uint32_t)];
	} buffer;
	bool empty = true;

	[_lastReturnedEntry OF_skip];
	[_lastReturnedEntry close];
	[_lastReturnedEntry release];
	_lastReturnedEntry = nil;

	if ([_stream isAtEndOfStream])
		return nil;

	[_stream readIntoBuffer: buffer.c
		    exactLength: 512];

	for (size_t i = 0; i < 512 / sizeof(uint32_t); i++)
		if (buffer.u32[i] != 0)
			empty = false;

	if (empty) {
		[_stream readIntoBuffer: buffer.c
			    exactLength: 512];

		for (size_t i = 0; i < 512 / sizeof(uint32_t); i++)
			if (buffer.u32[i] != 0)
				@throw [OFInvalidFormatException exception];

		return nil;
	}

	_lastReturnedEntry = [[OFTarArchiveEntry alloc]
	    OF_initWithHeader: buffer.c
		       stream: _stream];

	return [[_lastReturnedEntry retain] autorelease];
}
@end
