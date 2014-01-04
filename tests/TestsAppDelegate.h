/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "OFApplication.h"
#import "OFXMLElementBuilder.h"

#define TEST(test, cond)				\
	{						\
		[self outputTesting: test		\
			   inModule: module];		\
							\
		if (cond)				\
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
#define R(x) (x, 1)

@class OFString;

@interface TestsAppDelegate: OFObject
{
	int _fails;
}

- (void)outputString: (OFString*)str
	     inColor: (int)color;
- (void)outputTesting: (OFString*)test
	     inModule: (OFString*)module;
- (void)outputSuccess: (OFString*)test
	     inModule: (OFString*)module;
- (void)outputFailure: (OFString*)test
	     inModule: (OFString*)module;
@end

@interface TestsAppDelegate (OFArrayTests)
- (void)arrayTests;
@end

@interface TestsAppDelegate (OFBlockTests)
- (void)blockTests;
@end

@interface TestsAppDelegate (OFDataArrayTests)
- (void)dataArrayTests;
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

@interface TestsAppDelegate (OFJSONTests)
- (void)JSONTests;
@end

@interface TestsAppDelegate (OFListTests)
- (void)listTests;
@end

@interface TestsAppDelegate (OFMD5HashTests)
- (void)MD5HashTests;
@end

@interface TestsAppDelegate (OFNumberTests)
- (void)numberTests;
@end

@interface TestsAppDelegate (OFObjectTests)
- (void)objectTests;
@end

@interface TestsAppDelegate (OFPluginTests)
- (void)pluginTests;
@end

@interface TestsAppDelegate (PropertiesTests)
- (void)propertiesTests;
@end

@interface TestsAppDelegate (SerializationTests)
- (void)serializationTests;
@end

@interface TestsAppDelegate (OFSetTests)
- (void)setTests;
@end

@interface TestsAppDelegate (OFSHA1HashTests)
- (void)SHA1HashTests;
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

@interface TestsAppDelegate (OFURLTests)
- (void)URLTests;
@end

@interface TestsAppDelegate (OFXMLElementBuilderTests)
- (void)XMLElementBuilderTests;
@end

@interface TestsAppDelegate (OFXMLNodeTests)
- (void)XMLNodeTests;
@end

@interface TestsAppDelegate (OFXMLParserTests) <OFXMLElementBuilderDelegate>
- (void)XMLParserTests;
@end
