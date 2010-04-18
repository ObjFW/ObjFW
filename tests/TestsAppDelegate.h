/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFApplication.h"

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
			fails++;			\
		}					\
	}
#define EXPECT_EXCEPTION(test, exception, code)		\
	{						\
		BOOL caught = NO;			\
							\
		[self outputTesting: test		\
			   inModule: module];		\
							\
		@try {					\
			code;				\
		} @catch (exception *e) {		\
			caught = YES;			\
			[e dealloc];			\
		}					\
							\
		if (caught)				\
			[self outputSuccess: test	\
				   inModule: module];	\
		else {					\
			[self outputFailure: test	\
				   inModule: module];	\
			fails++;			\
		}					\
	}
#define R(x) (x, 1)

@class OFString;

@interface TestsAppDelegate: OFObject
{
	int fails;
}

- (void)outputString: (OFString*)str
	   withColor: (int)color;
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

@interface TestsAppDelegate (OFDataArrayTests)
- (void)dataArrayTests;
@end

@interface TestsAppDelegate (OFDictionaryTests)
- (void)dictionaryTests;
@end

@interface TestsAppDelegate (OFFileTests)
- (void)fileTests;
@end

@interface TestsAppDelegate (OFHashesTests)
- (void)hashesTests;
@end

@interface TestsAppDelegate (OFListTests)
- (void)listTests;
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

@interface TestsAppDelegate (OFXMLElementTests)
- (void)XMLElementTests;
@end

@interface TestsAppDelegate (OFXMLParserTests)
- (void)XMLParserTests;
@end
