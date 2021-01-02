/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "ObjFW.h"

#define TEST(test, ...)					\
	{						\
		[self outputTesting: test		\
			   inModule: module];		\
							\
		if (__VA_ARGS__)			\
			[self outputSuccess: test	\
				   inModule: module];	\
		else {					\
			[self outputFailure: test	\
				   inModule: module];	\
			_fails++;			\
		}					\
	}
#define EXPECT_EXCEPTION(test, exception, code)		\
	{						\
		bool caught = false;			\
							\
		[self outputTesting: test		\
			   inModule: module];		\
							\
		@try {					\
			code;				\
		} @catch (exception *e) {		\
			caught = true;			\
		}					\
							\
		if (caught)				\
			[self outputSuccess: test	\
				   inModule: module];	\
		else {					\
			[self outputFailure: test	\
				   inModule: module];	\
			_fails++;			\
		}					\
	}
#define R(...) (__VA_ARGS__, 1)

@class OFString;

@interface TestsAppDelegate: OFObject <OFApplicationDelegate>
{
	int _fails;
}

- (void)outputTesting: (OFString *)test
	     inModule: (OFString *)module;
- (void)outputSuccess: (OFString *)test
	     inModule: (OFString *)module;
- (void)outputFailure: (OFString *)test
	     inModule: (OFString *)module;
@end

@interface TestsAppDelegate (OFASN1DERParsingTests)
- (void)ASN1DERParsingTests;
@end

@interface TestsAppDelegate (OFASN1DERRepresentationTests)
- (void)ASN1DERRepresentationTests;
@end

@interface TestsAppDelegate (OFArrayTests)
- (void)arrayTests;
@end

@interface TestsAppDelegate (OFBlockTests)
- (void)blockTests;
@end

@interface TestsAppDelegate (OFCharacterSetTests)
- (void)characterSetTests;
@end

@interface TestsAppDelegate (OFDNSResolverTests)
- (void)DNSResolverTests;
@end

@interface TestsAppDelegate (OFDataTests)
- (void)dataTests;
@end

@interface TestsAppDelegate (OFDateTests)
- (void)dateTests;
@end

@interface TestsAppDelegate (OFDictionaryTests)
- (void)dictionaryTests;
@end

@interface TestsAppDelegate (ForwardingTests)
- (void)forwardingTests;
@end

@interface TestsAppDelegate (OFHTTPClientTests)
- (void)HTTPClientTests;
@end

@interface TestsAppDelegate (OFHTTPCookieTests)
- (void)HTTPCookieTests;
@end

@interface TestsAppDelegate (OFHTTPCookieManagerTests)
- (void)HTTPCookieManagerTests;
@end

@interface TestsAppDelegate (OFINIFileTests)
- (void)INIFileTests;
@end

@interface TestsAppDelegate (OFIPXSocketTests)
- (void)IPXSocketTests;
@end

@interface TestsAppDelegate (OFInvocationTests)
- (void)invocationTests;
@end

@interface TestsAppDelegate (OFJSONTests)
- (void)JSONTests;
@end

@interface TestsAppDelegate (OFKernelEventObserverTests)
- (void)kernelEventObserverTests;
@end

@interface TestsAppDelegate (OFListTests)
- (void)listTests;
@end

@interface TestsAppDelegate (OFLocaleTests)
- (void)localeTests;
@end

@interface TestsAppDelegate (OFMD5HashTests)
- (void)MD5HashTests;
@end

@interface TestsAppDelegate (OFMethodSignatureTests)
- (void)methodSignatureTests;
@end

@interface TestsAppDelegate (OFNumberTests)
- (void)numberTests;
@end

@interface TestsAppDelegate (OFObjectTests)
- (void)objectTests;
@end

@interface TestsAppDelegate (OFPropertyListTests)
- (void)propertyListTests;
@end

@interface TestsAppDelegate (OFPluginTests)
- (void)pluginTests;
@end

@interface TestsAppDelegate (RuntimeTests)
- (void)runtimeTests;
@end

@interface TestsAppDelegate (RuntimeARCTests)
- (void)runtimeARCTests;
@end

@interface TestsAppDelegate (OFRIPEMD160HashTests)
- (void)RIPEMD160HashTests;
@end

@interface TestsAppDelegate (ScryptTests)
- (void)scryptTests;
@end

@interface TestsAppDelegate (OFSHA1HashTests)
- (void)SHA1HashTests;
@end

@interface TestsAppDelegate (OFSHA224HashTests)
- (void)SHA224HashTests;
@end

@interface TestsAppDelegate (OFSHA256HashTests)
- (void)SHA256HashTests;
@end

@interface TestsAppDelegate (OFSHA384HashTests)
- (void)SHA384HashTests;
@end

@interface TestsAppDelegate (OFSHA512HashTests)
- (void)SHA512HashTests;
@end

@interface TestsAppDelegate (OFSCTPSocketTests)
- (void)SCTPSocketTests;
@end

@interface TestsAppDelegate (OFSPXSocketTests)
- (void)SPXSocketTests;
@end

@interface TestsAppDelegate (OFSPXStreamSocketTests)
- (void)SPXStreamSocketTests;
@end

@interface TestsAppDelegate (OFSerializationTests)
- (void)serializationTests;
@end

@interface TestsAppDelegate (OFSetTests)
- (void)setTests;
@end

@interface TestsAppDelegate (OFSystemInfoTests)
- (void)systemInfoTests;
@end

@interface TestsAppDelegate (OFHMACTests)
- (void)HMACTests;
@end

@interface TestsAppDelegate (OFStreamTests)
- (void)streamTests;
@end

@interface TestsAppDelegate (OFStringTests)
- (void)stringTests;
@end

@interface TestsAppDelegate (OFTCPSocketTests)
- (void)TCPSocketTests;
@end

@interface TestsAppDelegate (OFThreadTests)
- (void)threadTests;
@end

@interface TestsAppDelegate (OFUDPSocketTests)
- (void)UDPSocketTests;
@end

@interface TestsAppDelegate (OFURLTests)
- (void)URLTests;
@end

@interface TestsAppDelegate (OFValueTests)
- (void)valueTests;
@end

@interface TestsAppDelegate (OFWindowsRegistryKeyTests)
- (void)windowsRegistryKeyTests;
@end

@interface TestsAppDelegate (OFXMLElementBuilderTests)
- (void)XMLElementBuilderTests;
@end

@interface TestsAppDelegate (OFXMLNodeTests)
- (void)XMLNodeTests;
@end

@interface TestsAppDelegate (OFXMLParserTests)
    <OFXMLParserDelegate, OFXMLElementBuilderDelegate>
- (void)XMLParserTests;
@end

@interface TestsAppDelegate (PBKDF2Tests)
- (void)PBKDF2Tests;
@end

@interface TestsAppDelegate (SocketTests)
- (void)socketTests;
@end
