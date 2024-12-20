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

#import <Foundation/Foundation.h>

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
	SecExternalFormat format = kSecFormatUnknown;
	SecExternalItemType type = kSecItemTypePrivateKey;
	OFSecureTransportKeychain *keychain;
	OFData *data;
	NSData *dataNS;
	CFArrayRef items;
	SecKeychainItemRef key;

	if (IRI == nil)
		return NULL;

	pool = objc_autoreleasePoolPush();
	keychain = [OFSecureTransportKeychain temporaryKeychain];

	data = [OFData dataWithContentsOfIRI: IRI];

	dataNS = [NSData dataWithBytes: data.items
				length: data.count * data.itemSize];
	if (dataNS == nil)
		@throw [OFOutOfMemoryException exception];

	if (SecKeychainItemImport((CFDataRef)dataNS, NULL, &format, &type, 0,
	    NULL, keychain.keychain, &items) != noErr)
		@throw [OFInvalidFormatException exception];

	[(id)items autorelease];

	if ([(id)items count] != 1)
		@throw [OFInvalidFormatException exception];

	key = (SecKeychainItemRef)[[(id)items firstObject] retain];

	objc_autoreleasePoolPop(pool);

	[(id)key autorelease];

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

+ (bool)supportsPEMFiles
{
#ifndef OF_IOS
	return true;
#else
	return false;
#endif
}

+ (bool)supportsPKCS12Files
{
	return true;
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
	NSData *dataNS = [NSData dataWithBytesNoCopy: (void *)data.items
					      length: data.count * data.itemSize
					freeWhenDone: false];
	SecKeyImportExportParameters params = {
		.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION
	};
	CFArrayRef items;
	size_t i;

	if (dataNS == nil)
		@throw [OFOutOfMemoryException exception];

	if (passphrase != nil) {
		params.passphrase = [NSString stringWithUTF8String:
		    passphrase.UTF8String];
		if (params.passphrase == nil)
			@throw [OFOutOfMemoryException exception];
	}

	if (SecKeychainItemImport((CFDataRef)dataNS, NULL, &format, &type, 0,
	    &params, keychain.keychain, &items) != noErr)
		@throw [OFInvalidFormatException exception];

	[(id)items autorelease];

	i = 0;
	for (id item_ in (NSArray *)items) {
		SecCertificateRef item = (SecCertificateRef)item_;
		SecKeychainItemRef key = NULL;

		if (privateKeyIRI != nil && i == 0)
			key = privateKeyFromFile(privateKeyIRI);

		[chain addObject:
		    [[[self alloc] of_initWithCertificate: item
					       privateKey: key
						 keychain: keychain]
		    autorelease]];

		i++;
	}

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
	NSData *dataNS = [NSData dataWithBytesNoCopy: (void *)data.items
					      length: data.count * data.itemSize
					freeWhenDone: false];
	NSDictionary *options = nil;
	CFArrayRef items;

	if (dataNS == nil)
		@throw [OFOutOfMemoryException exception];

	if (passphrase != nil) {
		NSString *passphraseNS = [NSString stringWithUTF8String:
		    passphrase.UTF8String];
		if (passphraseNS == nil)
			@throw [OFOutOfMemoryException exception];

		options = [NSDictionary
		    dictionaryWithObject: passphraseNS
				  forKey: (NSString *)
					      kSecImportExportPassphrase];
		if (options == nil)
			@throw [OFOutOfMemoryException exception];
	}

	if (SecPKCS12Import((CFDataRef)dataNS, (CFDictionaryRef)options,
	    &items) != noErr)
		@throw [OFInvalidFormatException exception];

	[(id)items autorelease];

	for (NSDictionary *item in (NSArray *)items) {
		bool hasIdentity = false;
		SecCertificateRef cert;
		NSArray *certs;
		size_t i;

		cert = (SecCertificateRef)
		    [item objectForKey: (NSString *)kSecImportItemIdentity];
		if (cert != NULL) {
			[chain addObject: [[[self alloc]
			    of_initWithCertificate: cert] autorelease]];
			hasIdentity = true;
		}

		certs = [item objectForKey:
		    (NSString *)kSecImportItemCertChain];
		if (certs == nil)
			continue;

		i = 0;
		for (id cert_ in certs) {
			cert = (SecCertificateRef)cert_;

			if (hasIdentity && i == 0)
				continue;

			[chain addObject: [[[self alloc]
			    of_initWithCertificate: cert] autorelease]];
		}
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

	_certificate = (SecCertificateRef)[(id)certificate retain];

#ifndef OF_IOS
	if (privateKey != NULL)
		_privateKey = (SecKeychainItemRef)[(id)privateKey retain];

	_keychain = [keychain retain];
#endif

	return self;
}

- (void)dealloc
{
	[(id)_certificate release];

#ifndef OF_IOS
	if (_privateKey != NULL)
		[(id)_privateKey release];

	[_keychain release];
#endif

	[super dealloc];
}
@end
