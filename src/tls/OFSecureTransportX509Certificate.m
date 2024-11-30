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

#import "OFArray.h"
#import "OFData.h"
#ifndef OF_IOS
# import "OFSecureTransportKeychain.h"
#endif
#import "OFString.h"

#include <Security/SecImportExport.h>

#import "OFInvalidFormatException.h"
#import "OFOutOfMemoryException.h"
#import "OFOutOfRangeException.h"

/*
 * Apple deprecated Secure Transport without providing a replacement that can
 * work with any socket. On top of that, their replacement, Network.framework,
 * doesn't support STARTTLS at all.
 */
#if OF_GCC_VERSION >= 402
# pragma GCC diagnostic ignored "-Wdeprecated"
#endif

#ifndef OF_IOS
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
#endif

@implementation OFSecureTransportX509Certificate
@synthesize of_certificate = _certificate;
#ifndef OF_IOS
@synthesize of_privateKey = _privateKey;
#endif

+ (void)load
{
	if (OFX509CertificateImplementation == Nil)
		OFX509CertificateImplementation = self;
}

#ifndef OF_IOS
+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    of_certificateChainFromFileAtIRI: (OFIRI *)IRI
		       privateKeyIRI: (OFIRI *)privateKeyIRI
			  passphrase: (OFString *)passphrase
			      format: (SecExternalFormat)format
				type: (SecExternalItemType)type
{
	OFMutableArray *chain = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	OFSecureTransportKeychain *keychain =
	    [OFSecureTransportKeychain temporaryKeychain];
	OFData *data = [OFData dataWithContentsOfIRI: IRI];
	CFDataRef dataCF = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault,
	    data.items, data.count * data.itemSize, kCFAllocatorNull);
	SecKeyImportExportParameters params;
	CFArrayRef items;
	CFIndex count;

	if (dataCF == NULL)
		@throw [OFOutOfMemoryException exception];

	memset(&params, 0, sizeof(params));

	if (passphrase != nil) {
		if (passphrase.UTF8StringLength > LONG_MAX)
			@throw [OFOutOfRangeException exception];

		params.passphrase = CFStringCreateWithBytes(kCFAllocatorDefault,
		    (const UInt8 *)passphrase.UTF8String,
		    (CFIndex)passphrase.UTF8StringLength,
		    kCFStringEncodingUTF8, false);

		if (params.passphrase == NULL) {
			CFRelease(dataCF);
			@throw [OFOutOfMemoryException exception];
		}
	}

	if (SecKeychainItemImport(dataCF, NULL, &format, &type, 0, &params,
	    keychain.keychain, &items) != noErr) {
		CFRelease(dataCF);

		if (params.passphrase != NULL)
			CFRelease(params.passphrase);

		@throw [OFInvalidFormatException exception];
	}

	CFRelease(dataCF);

	if (params.passphrase != NULL)
		CFRelease(params.passphrase);

	count = CFArrayGetCount(items);
	for (CFIndex i = 0; i < count; i++)  {
		SecKeychainItemRef key = NULL;

		@try {
			SecCertificateRef item =
			    (SecCertificateRef)CFArrayGetValueAtIndex(items, i);

			if (privateKeyIRI != nil && i == 0)
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

+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPEMFileAtIRI: (OFIRI *)certificatesIRI
		       privateKeyIRI: (OFIRI *)privateKeyIRI
{
	return [self of_certificateChainFromFileAtIRI: certificatesIRI
					privateKeyIRI: privateKeyIRI
					   passphrase: nil
					       format: kSecFormatPEMSequence
						 type: kSecItemTypeCertificate];
}

+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPKCS12FileAtIRI: (OFIRI *)IRI
			     passphrase: (OFString *)passphrase
{
	return [self of_certificateChainFromFileAtIRI: IRI
					privateKeyIRI: nil
					   passphrase: passphrase
					       format: kSecFormatPKCS12
						 type: kSecItemTypeAggregate];
}
#else
+ (OFArray OF_GENERIC(OFX509Certificate *) *)
    certificateChainFromPKCS12FileAtIRI: (OFIRI *)IRI
			     passphrase: (OFString *)passphrase
{
	OFMutableArray *chain = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	OFData *data = [OFData dataWithContentsOfIRI: IRI];
	CFDataRef dataCF = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault,
	    data.items, data.count * data.itemSize, kCFAllocatorNull);
	CFDictionaryRef options = NULL;
	CFArrayRef items;
	CFIndex count;

	if (dataCF == NULL)
		@throw [OFOutOfMemoryException exception];

	if (passphrase != nil) {
		CFStringRef passphraseCF =
		    CFStringCreateWithBytes(kCFAllocatorDefault,
		    (const UInt8 *)passphrase.UTF8String,
		    (CFIndex)passphrase.UTF8StringLength,
		    kCFStringEncodingUTF8, false);

		if (passphraseCF == NULL) {
			CFRelease(dataCF);
			@throw [OFOutOfMemoryException exception];
		}

		options = CFDictionaryCreate(kCFAllocatorDefault,
		    (const void **)&kSecImportExportPassphrase,
		    (const void **)&passphraseCF, 1,
		    &kCFTypeDictionaryKeyCallBacks,
		    &kCFTypeDictionaryValueCallBacks);

		CFRelease(passphraseCF);

		if (options == NULL) {
			CFRelease(dataCF);
			@throw [OFOutOfMemoryException exception];
		}
	}

	if (SecPKCS12Import(dataCF, options, &items) != noErr) {
		CFRelease(dataCF);

		if (options != NULL)
			CFRelease(options);

		@throw [OFInvalidFormatException exception];
	}

	CFRelease(dataCF);

	if (options != NULL)
		CFRelease(options);

	count = CFArrayGetCount(items);
	@try {
		for (CFIndex i = 0; i < count; i++) {
			CFDictionaryRef item = CFArrayGetValueAtIndex(items, i);
			bool hasIdentity = false;
			SecCertificateRef cert;
			CFArrayRef certs;
			CFIndex certsCount;

			if ((cert = (SecCertificateRef)CFDictionaryGetValue(
			    item, kSecImportItemIdentity)) != NULL) {
				[chain addObject: [[[self alloc]
				    of_initWithCertificate: cert] autorelease]];
				hasIdentity = true;
			}

			if ((certs = CFDictionaryGetValue(item,
			    kSecImportItemCertChain)) == NULL)
				continue;

			certsCount = CFArrayGetCount(certs);
			for (CFIndex j = 0; j < certsCount; j++) {
				if (hasIdentity && j == 0)
					continue;

				cert = (SecCertificateRef)
				    CFArrayGetValueAtIndex(certs, j);

				[chain addObject: [[[self alloc]
				    of_initWithCertificate: cert] autorelease]];
			}
		}
	} @finally {
		CFRelease(items);
	}

	[chain makeImmutable];
	objc_autoreleasePoolPop(pool);

	return chain;
}
#endif

- (instancetype)of_initWithCertificate: (SecCertificateRef)certificate
#ifndef OF_IOS
			    privateKey: (SecKeychainItemRef)privateKey
			      keychain: (OFSecureTransportKeychain *)keychain
#endif
{
	self = [super init];

	_certificate = (SecCertificateRef)CFRetain(certificate);

#ifndef OF_IOS
	if (privateKey != NULL)
		_privateKey = (SecKeychainItemRef)CFRetain(privateKey);

	_keychain = [keychain retain];
#endif

	return self;
}

- (void)dealloc
{
	CFRelease(_certificate);

#ifndef OF_IOS
	if (_privateKey != NULL)
		CFRelease(_privateKey);

	[_keychain release];
#endif

	[super dealloc];
}
@end
