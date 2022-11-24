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

#import "OFIRIHandler.h"
#import "OFDictionary.h"
#import "OFIRI.h"
#import "OFNumber.h"

#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
#endif

#import "OFArchiveIRIHandler.h"
#import "OFEmbeddedIRIHandler.h"
#ifdef OF_HAVE_FILES
# import "OFFileIRIHandler.h"
#endif
#if defined(OF_HAVE_SOCKETS) && defined(OF_HAVE_THREADS)
# import "OFHTTPIRIHandler.h"
#endif

#import "OFUnsupportedProtocolException.h"

static OFMutableDictionary OF_GENERIC(OFString *, OFIRIHandler *) *handlers;
#ifdef OF_HAVE_THREADS
static OFMutex *mutex;

static void
releaseMutex(void)
{
	[mutex release];
}
#endif

@implementation OFIRIHandler
@synthesize scheme = _scheme;

+ (void)initialize
{
	if (self != [OFIRIHandler class])
		return;

	handlers = [[OFMutableDictionary alloc] init];
#ifdef OF_HAVE_THREADS
	mutex = [[OFMutex alloc] init];
	atexit(releaseMutex);
#endif

	[self registerClass: [OFEmbeddedIRIHandler class]
		  forScheme: @"embedded"];
#ifdef OF_HAVE_FILES
	[self registerClass: [OFFileIRIHandler class] forScheme: @"file"];
#endif
#if defined(OF_HAVE_SOCKETS) && defined(OF_HAVE_THREADS)
	[self registerClass: [OFHTTPIRIHandler class] forScheme: @"http"];
	[self registerClass: [OFHTTPIRIHandler class] forScheme: @"https"];
#endif
	[self registerClass: [OFArchiveIRIHandler class] forScheme: @"gzip"];
	[self registerClass: [OFArchiveIRIHandler class] forScheme: @"lha"];
	[self registerClass: [OFArchiveIRIHandler class] forScheme: @"tar"];
	[self registerClass: [OFArchiveIRIHandler class] forScheme: @"zip"];
}

+ (bool)registerClass: (Class)class forScheme: (OFString *)scheme
{
#ifdef OF_HAVE_THREADS
	[mutex lock];
	@try {
#endif
		OFIRIHandler *handler;

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

+ (OFIRIHandler *)handlerForIRI: (OFIRI *)IRI
{
	OF_KINDOF(OFIRIHandler *) handler;

#ifdef OF_HAVE_THREADS
	[mutex lock];
	@try {
#endif
		handler = [handlers objectForKey: IRI.scheme];
#ifdef OF_HAVE_THREADS
	} @finally {
		[mutex unlock];
	}
#endif

	if (handler == nil)
		@throw [OFUnsupportedProtocolException exceptionWithIRI: IRI];

	return handler;
}

+ (OFStream *)openItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode
{
	return [[self handlerForIRI: IRI] openItemAtIRI: IRI mode: mode];
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

- (OFStream *)openItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFFileAttributes)attributesOfItemAtIRI: (OFIRI *)IRI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)setAttributes: (OFFileAttributes)attributes ofItemAtIRI: (OFIRI *)IRI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)fileExistsAtIRI: (OFIRI *)IRI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)directoryExistsAtIRI: (OFIRI *)IRI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)createDirectoryAtIRI: (OFIRI *)IRI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (OFArray OF_GENERIC(OFIRI *) *)contentsOfDirectoryAtIRI: (OFIRI *)IRI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)removeItemAtIRI: (OFIRI *)IRI
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)linkItemAtIRI: (OFIRI *)source toIRI: (OFIRI *)destination
{
	OF_UNRECOGNIZED_SELECTOR
}

- (void)createSymbolicLinkAtIRI: (OFIRI *)destination
	    withDestinationPath: (OFString *)source
{
	OF_UNRECOGNIZED_SELECTOR
}

- (bool)copyItemAtIRI: (OFIRI *)source toIRI: (OFIRI *)destination
{
	return false;
}

- (bool)moveItemAtIRI: (OFIRI *)source toIRI: (OFIRI *)destination
{
	return false;
}
@end
