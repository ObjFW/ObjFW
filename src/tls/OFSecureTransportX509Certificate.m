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

/* Needed to avoid the NSArray compatibility alias */
#include <CoreFoundation/CoreFoundation.h>

#import "OFSecureTransportX509Certificate.h"

#ifndef OF_IOS
# import "OFArray.h"
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

static SecKeychainItemRef
privateKeyFromFile(OFIRI *IRI)
{
	void *pool;
	SecExternalFormat format = kSecFormatOpenSSL;
	SecExternalItemType type = kSecItemTypePrivateKey;
	OFSecureTransportKeychain *keychain;
	OFData *data;
	CFDataRef dataCF;
	CFArrayRef items;
	SecKeychainItemRef key;

	if (IRI == nil)
		return NULL;

	pool = objc_autoreleasePoolPush();
	keychain = [OFSecureTransportKeychain temporaryKeychain];

	data = [OFData dataWithContentsOfIRI: IRI];

	dataCF = CFDataCreate(kCFAllocatorDefault,
	    data.items, data.count * data.itemSize);
	if (dataCF == NULL)
		@throw [OFOutOfMemoryException exception];

	if (SecKeychainItemImport(dataCF, NULL, &format, &type, 0, NULL,
	    keychain.keychain, &items) != noErr) {
		CFRelease(dataCF);
		@throw [OFInvalidFormatException exception];
	}

	CFRelease(dataCF);

	if (CFArrayGetCount(items) != 1) {
		CFRelease(items);
		@throw [OFInvalidFormatException exception];
	}

	key = (SecKeychainItemRef)CFRetain(CFArrayGetValueAtIndex(items, 0));

	CFRelease(items);
	objc_autoreleasePoolPop(pool);

	return key;
}

@implementation OFSecureTransportX509Certificate
@synthesize of_certificate = _certificate, of_privateKey = _privateKey;

+ (void)load
{
	if (OFX509CertificateImplementation == Nil)
		OFX509CertificateImplementation = self;
}

+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPEMFileAtIRI: (OFIRI *)certificatesIRI
		       privateKeyIRI: (OFIRI *)privateKeyIRI
{
	OFMutableArray *chain = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	OFSecureTransportKeychain *keychain =
	    [OFSecureTransportKeychain temporaryKeychain];
	OFData *data = [OFData dataWithContentsOfIRI: certificatesIRI];
	CFDataRef dataCF = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault,
	    data.items, data.count * data.itemSize, kCFAllocatorNull);
	SecExternalFormat format = kSecFormatPEMSequence;
	SecExternalItemType type = kSecItemTypeCertificate;
	CFArrayRef items;
	CFIndex count;

	if (dataCF == NULL)
		@throw [OFOutOfMemoryException exception];

	if (SecKeychainItemImport(dataCF, NULL, &format, &type, 0, NULL,
	    keychain.keychain, &items) != noErr) {
		CFRelease(dataCF);
		@throw [OFInvalidFormatException exception];
	}

	CFRelease(dataCF);

	count = CFArrayGetCount(items);
	for (CFIndex i = 0; i < count; i++)  {
		SecKeychainItemRef key;

		@try {
			SecCertificateRef item =
			    (SecCertificateRef)CFArrayGetValueAtIndex(items, i);

			if (i == 0)
				key = privateKeyFromFile(privateKeyIRI);

			[chain addObject:
			    [[[self alloc] of_initWithCertificate: item
						       privateKey: key
							 keychain: keychain]
			    autorelease]];
		} @catch (id e) {
			CFRelease(items);

			if (key != NULL)
				CFRelease(key);

			@throw e;
		}
	}

	CFRelease(items);
	[chain makeImmutable];
	objc_autoreleasePoolPop(pool);

	return chain;
}

- (instancetype)of_initWithCertificate: (SecCertificateRef)certificate
			    privateKey: (SecKeychainItemRef)privateKey
			      keychain: (OFSecureTransportKeychain *)keychain
{
	self = [super init];

	_certificate = (SecCertificateRef)CFRetain(certificate);

	if (privateKey != NULL)
		_privateKey = (SecKeychainItemRef)CFRetain(privateKey);

	_keychain = [keychain retain];

	return self;
}

- (void)dealloc
{
	CFRelease(_certificate);

	if (_privateKey != NULL)
		CFRelease(_privateKey);

	[_keychain release];

	[super dealloc];
}
@end
#endif
