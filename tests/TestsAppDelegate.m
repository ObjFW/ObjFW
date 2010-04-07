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

#import "OFString.h"
#import "OFFile.h"
#import "OFAutoreleasePool.h"

#import "TestsAppDelegate.h"

OF_APPLICATION_DELEGATE(TestsAppDelegate)

@implementation TestsAppDelegate
- (void)outputString: (OFString*)str
	   withColor: (int)color
{
#ifdef STDOUT
	switch (color) {
	case 0:
		[of_stdout writeString: @"\r\033[K\033[1;33m"];
		break;
	case 1:
		[of_stdout writeString: @"\r\033[K\033[1;32m"];
		break;
	case 2:
		[of_stdout writeString: @"\r\033[K\033[1;31m"];
		break;
	}

	[of_stdout writeString: str];
	[of_stdout writeString: @"\033[m"];
#else
#error No output method!
#endif
}

- (void)outputTesting: (OFString*)test
	     inModule: (OFString*)module
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	[self outputString: [OFString stringWithFormat: @"[%s] %s: testing...",
							[module cString],
							[test cString]]
		 withColor: 0];
	[pool release];
}

- (void)outputSuccess: (OFString*)test
	     inModule: (OFString*)module
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	[self outputString: [OFString stringWithFormat: @"[%s] %s: ok\n",
							[module cString],
							[test cString]]
		 withColor: 1];
	[pool release];
}

- (void)outputFailure: (OFString*)test
	     inModule: (OFString*)module
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	[self outputString: [OFString stringWithFormat: @"[%s] %s: failed\n",
							[module cString],
							[test cString]]
		 withColor: 2];
	[pool release];
}

- (void)applicationDidFinishLaunching
{
	[self objectTests];
	[self hashesTests];
	[self stringTests];
	[self dataArrayTests];
	[self arrayTests];
	[self dictionaryTests];
	[self listTests];
	[self numberTests];
	[self streamTests];
	[self TCPSocketTests];
#ifdef OF_THREADS
	[self threadTests];
#endif
	[self XMLElementTests];
	[self XMLParserTests];
#ifdef OF_PLUGINS
	[self pluginTests];
#endif
#ifdef OF_HAVE_PROPERTIES
	[self propertiesTests];
#endif
}
@end
