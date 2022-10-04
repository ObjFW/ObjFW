/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import "OFURIHandler.h"
#import "OFDictionary.h"
#import "OFNumber.h"
#import "OFURI.h"

#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
#endif

#import "OFEmbeddedURIHandler.h"
#ifdef OF_HAVE_FILES
# import "OFFileURIHandler.h"
#endif
#if defined(OF_HAVE_SOCKETS) && defined(OF_HAVE_THREADS)
# import "OFHTTPURIHandler.h"
#endif
#import "OFZIPURIHandler.h"

#import "OFUnsupportedProtocolException.h"

static OFMutableDictionary OF_GENERIC(OFString *, OFURIHandler *) *handlers;
#ifdef OF_HAVE_THREADS
static OFMutex *mutex;

static void
releaseMutex(void)
{
	[mutex release];
}
#endif

@implementation OFURIHandler
@synthesize scheme = _scheme;

+ (void)initialize
{
	if (self != [OFURIHandler class])
		return;

	handlers = [[OFMutableDictionary alloc] init];
#ifdef OF_HAVE_THREADS
	mutex = [[OFMutex alloc] init];
	atexit(releaseMutex);
#endif

	[self registerClass: [OFEmbeddedURIHandler class]
		  forScheme: @"of-embedded"];
#ifdef OF_HAVE_FILES
	[self registerClass: [OFFileURIHandler class] forScheme: @"file"];
#endif
#if defined(OF_HAVE_SOCKETS) && defined(OF_HAVE_THREADS)
	[self registerClass: [OFHTTPURIHandler class] forScheme: @"http"];
	[self registerClass: [OFHTTPURIHandler class] forScheme: @"https"];
#endif
	[self registerClass: [OFZIPURIHandler class] forScheme: @"of-zip"];
}

+ (bool)registerClass: (Class)class forScheme: (OFString *)scheme
{
#ifdef OF_HAVE_THREADS
	[mutex lock];
	@try {
#endif
		OFURIHandler *handler;

		if ([handlers objectForKey: scheme] != nil)
			return false;

		handler = [[class alloc] initWithScheme: scheme];
		@try {
			[handlers setObject: handler forKey: scheme];
		} @finally {
			[handler release];
		}
#ifdef OF_HAVE_THREADS
	} @finally {
		[mutex unlock];
	}
#endif

	return true;
}

+ (OFURIHandler *)handlerForURI: (OFURI *)URI
{
	OF_KINDOF(OFURIHandler *) handler;

#ifdef OF_HAVE_THREADS
	[mutex lock];
	@try {
#endif
		handler = [handlers objectForKey: URI.scheme];
#ifdef OF_HAVE_THREADS
	} @finally {
		[mutex unlock];
	}
#endif

	if (handler == nil)
		@throw [OFUnsupportedProtocolException exceptionWithURI: URI];

	return handler;
}

+ (OFStream *)openItemAtURI: (OFURI *)URI mode: (OFString *)mode
{
	return [[self handlerForURI: URI] openItemAtURI: URI mode: mode];
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

- (OFStream *)openItemAtURI: (OFURI *)URI mode: (OFString *)mode
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFFileAttributes)attributesOfItemAtURI: (OFURI *)URI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)setAttributes: (OFFileAttributes)attributes ofItemAtURI: (OFURI *)URI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)fileExistsAtURI: (OFURI *)URI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)directoryExistsAtURI: (OFURI *)URI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)createDirectoryAtURI: (OFURI *)URI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFArray OF_GENERIC(OFURI *) *)contentsOfDirectoryAtURI: (OFURI *)URI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)removeItemAtURI: (OFURI *)URI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)linkItemAtURI: (OFURI *)source toURI: (OFURI *)destination
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)createSymbolicLinkAtURI: (OFURI *)destination
	    withDestinationPath: (OFString *)source
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)copyItemAtURI: (OFURI *)source toURI: (OFURI *)destination
{
	return false;
}

- (bool)moveItemAtURI: (OFURI *)source toURI: (OFURI *)destination
{
	return false;
}
@end
