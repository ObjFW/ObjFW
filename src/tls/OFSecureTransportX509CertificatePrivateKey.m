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

#import "OFSecureTransportX509CertificatePrivateKey.h"

#ifndef OF_IOS
# import "OFData.h"
# import "OFSecureTransportKeychain.h"

# include <Security/SecImportExport.h>

# import "OFInvalidFormatException.h"
# import "OFOutOfMemoryException.h"

/*
 * Apple deprecated Secure Transport without providing a replacement that can
 * work with any socket. On top of that, their replacement, Network.framework,
 * doesn't support STARTTLS at all.
 */
# if OF_GCC_VERSION >= 402
#  pragma GCC diagnostic ignored "-Wdeprecated"
# endif

@implementation OFSecureTransportX509CertificatePrivateKey
+ (void)load
{
	if (OFX509CertificatePrivateKeyImplementation == Nil)
		OFX509CertificatePrivateKeyImplementation = self;
}

+ (instancetype)privateKeyFromPEMFileAtIRI: (OFIRI *)IRI
{
	void *pool = objc_autoreleasePoolPush();
	OFSecureTransportKeychain *keychain =
	    [OFSecureTransportKeychain temporaryKeychain];
	OFData *data = [OFData dataWithContentsOfIRI: IRI];
	CFDataRef dataCF = CFDataCreate(kCFAllocatorDefault,
	    data.items, data.count * data.itemSize);
	SecExternalFormat format = kSecFormatOpenSSL;
	SecExternalItemType type = kSecItemTypePrivateKey;
	CFArrayRef items;
	OFSecureTransportX509CertificatePrivateKey *privateKey;

	if (dataCF == NULL)
		@throw [OFOutOfMemoryException exception];

	if (SecKeychainItemImport(dataCF, NULL, &format, &type, 0, NULL,
	    keychain.keychain, &items) != noErr) {
		CFRelease(dataCF);
		@throw [OFInvalidFormatException exception];
	}

	if (CFArrayGetCount(items) != 1) {
		CFRelease(dataCF);
		CFRelease(items);
		@throw [OFInvalidFormatException exception];
	}

	@try {
		SecKeychainItemRef item =
		    (SecKeychainItemRef)CFArrayGetValueAtIndex(items, 0);

		privateKey = [[self alloc]
		    of_initWithSecKeychainItem: item
				      keychain: keychain];
	} @finally {
		CFRelease(dataCF);
		CFRelease(items);
	}

	objc_autoreleasePoolPop(pool);

	return [privateKey autorelease];
}

- (instancetype)
    of_initWithSecKeychainItem: (SecKeychainItemRef)keychainItem
		      keychain: (OFSecureTransportKeychain *)keychain
{
	self = [super init];

	_keychainItem = (SecKeychainItemRef)CFRetain(keychainItem);
	_keychain = [keychain retain];

	return self;
}

- (void)dealloc
{
	CFRelease(_keychainItem);
	[_keychain release];

	[super dealloc];
}
@end
#endif
