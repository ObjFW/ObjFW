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

@implementation OFSecureTransportX509Certificate
@synthesize of_secCertificate = _certificate;

+ (void)load
{
	if (OFX509CertificateImplementation == Nil)
		OFX509CertificateImplementation = self;
}

+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPEMFileAtIRI: (OFIRI *)IRI
{
	OFMutableArray *chain = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	OFData *data = [OFData dataWithContentsOfIRI: IRI];
	CFDataRef dataCF = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault,
	    data.items, data.count * data.itemSize, kCFAllocatorNull);
	SecExternalFormat format = kSecFormatPEMSequence;
	SecExternalItemType type = kSecItemTypeCertificate;

	if (dataCF == NULL)
		@throw [OFOutOfMemoryException exception];

	@try {
		OFSecureTransportKeychain *keychain =
		    [OFSecureTransportKeychain temporaryKeychain];
		CFArrayRef items;

		if (SecKeychainItemImport(dataCF, NULL, &format, &type, 0,
		    NULL, keychain.keychain, &items) != noErr)
			@throw [OFInvalidFormatException exception];

		@try {
			CFIndex count = CFArrayGetCount(items);

			for (CFIndex i = 0; i < count; i++) {
				SecCertificateRef item = (SecCertificateRef)
				    CFArrayGetValueAtIndex(items, i);

				[chain addObject: [[[self alloc]
				    of_initWithSecCertificate: item
						     keychain: keychain]
				    autorelease]];
			}
		} @finally {
			CFRelease(items);
		}
	} @finally {
		CFRelease(dataCF);
	}

	[chain makeImmutable];

	objc_autoreleasePoolPop(pool);

	return chain;
}

- (instancetype)of_initWithSecCertificate: (SecCertificateRef)certificate
				 keychain: (OFSecureTransportKeychain *)keychain
{
	self = [super init];

	_certificate = (SecCertificateRef)CFRetain(certificate);
	_keychain = [keychain retain];

	return self;
}

- (void)dealloc
{
	CFRelease(_certificate);
	[_keychain release];

	[super dealloc];
}
@end
#endif
