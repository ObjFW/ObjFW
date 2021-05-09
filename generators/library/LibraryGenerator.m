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

#include "config.h"

#import "OFApplication.h"
#import "OFFile.h"
#import "OFFileManager.h"
#import "OFURL.h"
#import "OFXMLElement.h"

#import "FuncArrayGenerator.h"
#import "GlueGenerator.h"
#import "LinkLibGenerator.h"

@interface LibraryGenerator: OFObject <OFApplicationDelegate>
@end

OF_APPLICATION_DELEGATE(LibraryGenerator)

@implementation LibraryGenerator
- (void)generateInDirectory: (OFString *)directory
{
	OFURL *sourcesURL = [[OFFileManager defaultManager].currentDirectoryURL
	    URLByAppendingPathComponent: directory];
	OFURL *libraryURL = [sourcesURL
	    URLByAppendingPathComponent: @"library.xml"];
	OFURL *linkLibURL = [sourcesURL
	    URLByAppendingPathComponent: @"linklib/linklib.m"];
	OFURL *glueHeaderURL = [sourcesURL
	    URLByAppendingPathComponent: @"amiga-glue.h"];
	OFURL *glueURL = [sourcesURL
	    URLByAppendingPathComponent: @"amiga-glue.m"];
	OFURL *funcArrayURL = [sourcesURL
	    URLByAppendingPathComponent: @"amiga-funcarray.inc"];
	OFXMLElement *library = [OFXMLElement elementWithStream:
	    [OFFile fileWithURL: libraryURL mode: @"r"]];
	OFFile *linkLib = [OFFile fileWithURL: linkLibURL mode: @"w"];
	OFFile *glueHeader = [OFFile fileWithURL: glueHeaderURL mode: @"w"];
	OFFile *glue = [OFFile fileWithURL: glueURL mode: @"w"];
	OFFile *funcArray = [OFFile fileWithURL: funcArrayURL mode: @"w"];
	LinkLibGenerator *linkLibGenerator = [[[LinkLibGenerator alloc]
	    initWithLibrary: library
	     implementation: linkLib] autorelease];
	GlueGenerator *glueGenerator = [[[GlueGenerator alloc]
	    initWithLibrary: library
		     header: glueHeader
	     implementation: glue] autorelease];
	FuncArrayGenerator *funcArrayGenerator = [[[FuncArrayGenerator alloc]
	    initWithLibrary: library
		    include: funcArray] autorelease];

	[linkLibGenerator generate];
	[glueGenerator generate];
	[funcArrayGenerator generate];
}

- (void)applicationDidFinishLaunching
{
	[self generateInDirectory: @"../../src"];
	[self generateInDirectory: @"../../src/runtime"];

	[OFApplication terminate];
}
@end
