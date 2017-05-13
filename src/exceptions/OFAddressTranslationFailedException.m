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

#import "OFAddressTranslationFailedException.h"
#import "OFString.h"

#import "OFInitializationFailedException.h"
#import "OFLockFailedException.h"
#import "OFUnlockFailedException.h"

#include "socket_helpers.h"

#if !defined(HAVE_THREADSAFE_GETADDRINFO) && defined(OF_HAVE_THREADS)
# include "threading.h"

static of_mutex_t mutex;
#endif

@implementation OFAddressTranslationFailedException
@synthesize host = _host;

#if !defined(HAVE_THREADSAFE_GETADDRINFO) && defined(OF_HAVE_THREADS)
+ (void)initialize
{
	if (self != [OFAddressTranslationFailedException class])
		return;

	if (!of_mutex_new(&mutex))
		@throw [OFInitializationFailedException
		    exceptionWithClass: [self class]];
}
#endif

+ (instancetype)exceptionWithHost: (OFString *)host
{
	return [[[self alloc] initWithHost: host] autorelease];
}

+ (instancetype)exceptionWithHost: (OFString *)host
			    error: (int)error
{
	return [[[self alloc] initWithHost: host
				     error: error] autorelease];
}

+ (instancetype)exceptionWithError: (int)error
{
	return [[[self alloc] initWithError: error] autorelease];
}

- initWithHost: (OFString *)host
{
	self = [super init];

	@try {
		_host = [host copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithHost: (OFString *)host
		       error: (int)error
{
	self = [super init];

	@try {
		_host = [host copy];
		_error = error;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithError: (int)error
{
	self = [super init];

	_error = error;

	return self;
}

- (void)dealloc
{
	[_host release];

	[super dealloc];
}

- (OFString *)description
{
	/* FIXME: Add proper description for Win32 */
#ifndef OF_WINDOWS
	if (_error == 0) {
#endif
		if (_host != nil)
			return [OFString stringWithFormat:
			    @"The host %@ could not be translated to an "
			    @"address!",
			    _host];
		else
			return @"An address could not be translated!";
#ifndef OF_WINDOWS
	}

# ifdef HAVE_GETADDRINFO
#  if defined(OF_HAVE_THREADS) && !defined(HAVE_THREADSAFE_GETADDRINFO)
	if (!of_mutex_lock(&mutex))
		@throw [OFLockFailedException exception];

	@try {
#  endif
		if (_host != nil)
			return [OFString stringWithFormat:
			    @"The host %@ could not be translated to an "
			    @"address: %s",
			    _host, gai_strerror(_error)];
		else
			return [OFString stringWithFormat:
			    @"An address could not be translated: %s",
			    gai_strerror(_error)];
#  if defined(OF_HAVE_THREADS) && !defined(HAVE_THREADSAFE_GETADDRINFO)
	} @finally {
		if (!of_mutex_unlock(&mutex))
			@throw [OFUnlockFailedException exception];
	}
#  endif
# else
#  ifdef OF_HAVE_THREADS
	if (!of_mutex_lock(&mutex))
		@throw [OFLockFailedException exception];

	@try {
#  endif
		if (_host != nil)
			return [OFString stringWithFormat:
			    @"The host %@ could not be translated to an "
			    "address: %s",
			    _host, hstrerror(_error)];
		else
			return [OFString stringWithFormat:
			    @"An address could not be translated: %s",
			    hstrerror(_error)];
#  ifdef OF_HAVE_THREADS
	} @finally {
		if (!of_mutex_unlock(&mutex))
			@throw [OFUnlockFailedException exception];
	}
#  endif
# endif
#endif
}
@end
