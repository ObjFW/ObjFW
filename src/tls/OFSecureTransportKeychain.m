/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version 3.0 only,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * version 3.0 along with this program. If not, see
 * <https://www.gnu.org/licenses/>.
 */

#include "config.h"

#import "OFSecureTransportKeychain.h"
#import "OFIRI.h"
#import "OFLocale.h"
#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
#endif
#import "OFString.h"
#import "OFSystemInfo.h"
#import "OFUUID.h"

#import "OFInitializationFailedException.h"

/*
 * Apple deprecated Secure Transport without providing a replacement that can
 * work with any socket. On top of that, their replacement, Network.framework,
 * doesn't support STARTTLS at all.
 */
#if OF_GCC_VERSION >= 402
# pragma GCC diagnostic ignored "-Wdeprecated"
#endif

static OFSecureTransportKeychain *temporaryKeychain;
#ifdef OF_HAVE_THREADS
static OFMutex *temporaryKeychainMutex;
#endif

@implementation OFSecureTransportKeychain
@synthesize keychain = _keychain;

static void
cleanup(void)
{
#ifdef OF_HAVE_THREADS
	[temporaryKeychainMutex lock];
	@try {
#endif
		if (temporaryKeychain != nil &&
		    temporaryKeychain->_keychain != NULL)
			SecKeychainDelete(temporaryKeychain->_keychain);
#ifdef OF_HAVE_THREADS
	} @finally {
		[temporaryKeychainMutex unlock];
	}
#endif
}

+ (void)initialize
{
	if (self != [OFSecureTransportKeychain class])
		return;

#ifdef OF_HAVE_THREADS
	temporaryKeychainMutex = [[OFMutex alloc] init];
#endif

	atexit(cleanup);
}

+ (instancetype)temporaryKeychain
{
	OFSecureTransportKeychain *keychain;

#ifdef OF_HAVE_THREADS
	[temporaryKeychainMutex lock];
	@try {
#endif
		if (temporaryKeychain != nil)
			keychain = temporaryKeychain;
		else {
			void *pool;
			OFString *filename, *path, *password;

			keychain = [[[self alloc] init] autorelease];
			pool = objc_autoreleasePoolPush();
			filename = [OFString stringWithFormat:
			    @"%@.keychain", [OFUUID UUID]];
			path = [[OFSystemInfo temporaryDirectoryIRI]
			    IRIByAppendingPathComponent: filename]
			    .fileSystemRepresentation;
			password = [OFString stringWithFormat:
			    @"%08X%08X", OFRandom64(), OFRandom64()];

			if (SecKeychainCreate([path cStringWithEncoding:
			    [OFLocale encoding]],
			    (UInt32)password.UTF8StringLength,
			    password.UTF8String, NO, NULL,
			    &keychain->_keychain) != noErr)
				@throw [OFInitializationFailedException
				    exceptionWithClass: self];

			objc_autoreleasePoolPop(pool);

			temporaryKeychain = keychain;
		}
#ifdef OF_HAVE_THREADS
	} @finally {
		[temporaryKeychainMutex unlock];
	}
#endif

	return [[keychain retain] autorelease];
}

- (void)dealloc
{
#ifdef OF_HAVE_THREADS
	[temporaryKeychainMutex lock];
	@try {
#endif
		if (self == temporaryKeychain)
			temporaryKeychain = nil;
#ifdef OF_HAVE_THREADS
	} @finally {
		[temporaryKeychainMutex unlock];
	}
#endif

	if (_keychain != NULL) {
		SecKeychainDelete(_keychain);
		CFRelease(_keychain);
	}

	[super dealloc];
}
@end
