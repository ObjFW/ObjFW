/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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
#import "OFURI.h"
#import "OFXMLElement.h"

#import "FuncArrayGenerator.h"
#import "GlueGenerator.h"
#import "LinkLibGenerator.h"

@interface LibraryGenerator: OFObject <OFApplicationDelegate>
@end

OF_APPLICATION_DELEGATE(LibraryGenerator)

@implementation LibraryGenerator
- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	OFURI *sourcesURI = [[OFFileManager defaultManager].currentDirectoryURI
	    URIByAppendingPathComponent: @"../../src"];
	OFURI *runtimeLibraryURI = [sourcesURI
	    URIByAppendingPathComponent: @"runtime/amiga-library.xml"];
	OFURI *runtimeLinkLibURI = [sourcesURI
	    URIByAppendingPathComponent: @"runtime/linklib/linklib.m"];
	OFURI *runtimeGlueHeaderURI = [sourcesURI
	    URIByAppendingPathComponent: @"runtime/amiga-glue.h"];
	OFURI *runtimeGlueURI = [sourcesURI
	    URIByAppendingPathComponent: @"runtime/amiga-glue.m"];
	OFURI *runtimeFuncArrayURI = [sourcesURI
	    URIByAppendingPathComponent: @"runtime/amiga-funcarray.inc"];
	OFXMLElement *runtimeLibrary = [OFXMLElement elementWithStream:
	    [OFFile fileWithPath: runtimeLibraryURI.fileSystemRepresentation
			    mode: @"r"]];
	OFFile *runtimeLinkLib =
	    [OFFile fileWithPath: runtimeLinkLibURI.fileSystemRepresentation
			    mode: @"w"];
	OFFile *runtimeGlueHeader =
	    [OFFile fileWithPath: runtimeGlueHeaderURI.fileSystemRepresentation
			    mode: @"w"];
	OFFile *runtimeGlue =
	    [OFFile fileWithPath: runtimeGlueURI.fileSystemRepresentation
			    mode: @"w"];
	OFFile *runtimeFuncArray =
	    [OFFile fileWithPath: runtimeFuncArrayURI.fileSystemRepresentation
			    mode: @"w"];
	LinkLibGenerator *runtimeLinkLibGenerator = [[[LinkLibGenerator alloc]
	    initWithLibrary: runtimeLibrary
	     implementation: runtimeLinkLib] autorelease];
	GlueGenerator *runtimeGlueGenerator = [[[GlueGenerator alloc]
	    initWithLibrary: runtimeLibrary
		     header: runtimeGlueHeader
	     implementation: runtimeGlue] autorelease];
	FuncArrayGenerator *runtimeFuncArrayGenerator;
	runtimeFuncArrayGenerator = [[[FuncArrayGenerator alloc]
	    initWithLibrary: runtimeLibrary
		    include: runtimeFuncArray] autorelease];

	[runtimeLinkLibGenerator generate];
	[runtimeGlueGenerator generate];
	[runtimeFuncArrayGenerator generate];

	[OFApplication terminate];
}
@end
