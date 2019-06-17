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
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OFURL.h"

#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
#endif

#ifdef OF_HAVE_FILES
# import "OFFileURLHandler.h"
#endif
#if defined(OF_HAVE_SOCKETS) && defined(OF_HAVE_THREADS)
# import "OFHTTPURLHandler.h"
#endif

static OFMutableDictionary OF_GENERIC(OFString *, OFURLHandler *) *handlers;
#ifdef OF_HAVE_THREADS
static OFMutex *mutex;
#endif

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
	[self registerClass: [OFFileURLHandler class]
		  forScheme: @"file"];
#endif
#if defined(OF_HAVE_SOCKETS) && defined(OF_HAVE_THREADS)
	[self registerClass: [OFHTTPURLHandler class]
		  forScheme: @"http"];
	[self registerClass: [OFHTTPURLHandler class]
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
		return [handlers objectForKey: URL.scheme];
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
