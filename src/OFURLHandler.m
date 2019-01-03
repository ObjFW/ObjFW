/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

#import "OFURLHandler.h"
#import "OFNumber.h"
#import "OFURL.h"

#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
#endif

#ifdef OF_HAVE_FILES
# import "OFURLHandler_file.h"
#endif
#if defined(OF_HAVE_SOCKETS) && defined(OF_HAVE_THREADS)
# import "OFURLHandler_HTTP.h"
#endif

#import "OFUndefinedKeyException.h"

const of_file_attribute_key_t of_file_attribute_key_size =
    @"of_file_attribute_key_size";
const of_file_attribute_key_t of_file_attribute_key_type =
    @"of_file_attribute_key_type";
const of_file_attribute_key_t of_file_attribute_key_posix_permissions =
    @"of_file_attribute_key_posix_permissions";
const of_file_attribute_key_t of_file_attribute_key_posix_uid =
    @"of_file_attribute_key_posix_uid";
const of_file_attribute_key_t of_file_attribute_key_posix_gid =
    @"of_file_attribute_key_posix_gid";
const of_file_attribute_key_t of_file_attribute_key_owner =
    @"of_file_attribute_key_owner";
const of_file_attribute_key_t of_file_attribute_key_group =
    @"of_file_attribute_key_group";
const of_file_attribute_key_t of_file_attribute_key_last_access_date =
    @"of_file_attribute_key_last_access_date";
const of_file_attribute_key_t of_file_attribute_key_modification_date =
    @"of_file_attribute_key_modification_date";
const of_file_attribute_key_t of_file_attribute_key_status_change_date =
    @"of_file_attribute_key_status_change_date";
const of_file_attribute_key_t of_file_attribute_key_symbolic_link_destination =
    @"of_file_attribute_key_symbolic_link_destination";

const of_file_type_t of_file_type_regular = @"of_file_type_regular";
const of_file_type_t of_file_type_directory = @"of_file_type_directory";
const of_file_type_t of_file_type_symbolic_link = @"of_file_type_symbolic_link";
const of_file_type_t of_file_type_fifo = @"of_file_type_fifo";
const of_file_type_t of_file_type_character_special =
    @"of_file_type_character_special";
const of_file_type_t of_file_type_block_special = @"of_file_type_block_special";
const of_file_type_t of_file_type_socket = @"of_file_type_socket";

static OFMutableDictionary OF_GENERIC(OFString *, OFURLHandler *) *handlers;
#ifdef OF_HAVE_THREADS
static OFMutex *mutex;
#endif

static id
attributeForKeyOrException(of_file_attributes_t attributes,
    of_file_attribute_key_t key)
{
	id object = [attributes objectForKey: key];

	if (object == nil)
		@throw [OFUndefinedKeyException exceptionWithObject: attributes
								key: key];

	return object;
}

@implementation OFURLHandler
@synthesize scheme = _scheme;

+ (void)initialize
{
	if (self != [OFURLHandler class])
		return;

	handlers = [[OFMutableDictionary alloc] init];
#ifdef OF_HAVE_THREADS
	mutex = [[OFMutex alloc] init];
#endif

#ifdef OF_HAVE_FILES
	[self registerClass: [OFURLHandler_file class]
		  forScheme: @"file"];
#endif
#if defined(OF_HAVE_SOCKETS) && defined(OF_HAVE_THREADS)
	[self registerClass: [OFURLHandler_HTTP class]
		  forScheme: @"http"];
	[self registerClass: [OFURLHandler_HTTP class]
		  forScheme: @"https"];
#endif
}

+ (bool)registerClass: (Class)class
	    forScheme: (OFString *)scheme
{
#ifdef OF_HAVE_THREADS
	[mutex lock];
	@try {
#endif
		OFURLHandler *handler;

		if ([handlers objectForKey: scheme] != nil)
			return false;

		handler = [[class alloc] initWithScheme: scheme];
		@try {
			[handlers setObject: handler
				     forKey: scheme];
		} @finally {
			[handler release];
		}

		return true;
#ifdef OF_HAVE_THREADS
	} @finally {
		[mutex unlock];
	}
#endif
}

+ (OF_KINDOF(OFURLHandler *))handlerForURL: (OFURL *)URL
{
#ifdef OF_HAVE_THREADS
	[mutex lock];
	@try {
#endif
		return [handlers objectForKey: [URL scheme]];
#ifdef OF_HAVE_THREADS
	} @finally {
		[mutex unlock];
	}
#endif
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithScheme: (OFString *)scheme
{
	self = [super init];

	@try {
		_scheme = [scheme copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_scheme release];

	[super dealloc];
}

- (OFStream *)openItemAtURL: (OFURL *)URL
		       mode: (OFString *)mode
{
	OF_UNRECOGNIZED_SELECTOR
}

- (of_file_attributes_t)attributesOfItemAtURL: (OFURL *)URL
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)setAttributes: (of_file_attributes_t)attributes
	  ofItemAtURL: (OFURL *)URL
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)fileExistsAtURL: (OFURL *)URL
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)directoryExistsAtURL: (OFURL *)URL
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)createDirectoryAtURL: (OFURL *)URL
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFArray OF_GENERIC(OFString *) *)contentsOfDirectoryAtURL: (OFURL *)URL
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)removeItemAtURL: (OFURL *)URL
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)linkItemAtURL: (OFURL *)source
		toURL: (OFURL *)destination
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)createSymbolicLinkAtURL: (OFURL *)destination
	    withDestinationPath: (OFString *)source
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)copyItemAtURL: (OFURL *)source
		toURL: (OFURL *)destination
{
	return false;
}

- (bool)moveItemAtURL: (OFURL *)source
		toURL: (OFURL *)destination
{
	return false;
}
@end

@implementation OFDictionary (FileAttributes)
- (uintmax_t)fileSize
{
	return [attributeForKeyOrException(self, of_file_attribute_key_size)
	    uIntMaxValue];
}

- (of_file_type_t)fileType
{
	return attributeForKeyOrException(self, of_file_attribute_key_type);
}

- (uint16_t)filePOSIXPermissions
{
	return [attributeForKeyOrException(self,
	    of_file_attribute_key_posix_permissions) uInt16Value];
}

- (uint32_t)filePOSIXUID
{
	return [attributeForKeyOrException(self,
	    of_file_attribute_key_posix_uid) uInt32Value];
}

- (uint32_t)filePOSIXGID
{
	return [attributeForKeyOrException(self,
	    of_file_attribute_key_posix_gid) uInt32Value];
}

- (OFString *)fileOwner
{
	return attributeForKeyOrException(self, of_file_attribute_key_owner);
}

- (OFString *)fileGroup
{
	return attributeForKeyOrException(self, of_file_attribute_key_group);
}

- (OFDate *)fileLastAccessDate
{
	return attributeForKeyOrException(self,
	    of_file_attribute_key_last_access_date);
}

- (OFDate *)fileModificationDate
{
	return attributeForKeyOrException(self,
	    of_file_attribute_key_modification_date);
}

- (OFDate *)fileStatusChangeDate
{
	return attributeForKeyOrException(self,
	    of_file_attribute_key_status_change_date);
}

- (OFString *)fileSymbolicLinkDestination
{
	return attributeForKeyOrException(self,
	    of_file_attribute_key_symbolic_link_destination);
}
@end
