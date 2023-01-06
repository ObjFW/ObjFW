/*
 * Copyright (c) 2008-2023 Jonathan Schleifer <js@nil.im>
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
#import "OFIRI.h"
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
	OFIRI *sourcesIRI = [[OFFileManager defaultManager].currentDirectoryIRI
	    IRIByAppendingPathComponent: @"../../src"];
	OFIRI *runtimeLibraryIRI = [sourcesIRI
	    IRIByAppendingPathComponent: @"runtime/amiga-library.xml"];
	OFIRI *runtimeLinkLibIRI = [sourcesIRI
	    IRIByAppendingPathComponent: @"runtime/linklib/linklib.m"];
	OFIRI *runtimeGlueHeaderIRI = [sourcesIRI
	    IRIByAppendingPathComponent: @"runtime/amiga-glue.h"];
	OFIRI *runtimeGlueIRI = [sourcesIRI
	    IRIByAppendingPathComponent: @"runtime/amiga-glue.m"];
	OFIRI *runtimeFuncArrayIRI = [sourcesIRI
	    IRIByAppendingPathComponent: @"runtime/amiga-funcarray.inc"];
	OFXMLElement *runtimeLibrary = [OFXMLElement elementWithStream:
	    [OFFile fileWithPath: runtimeLibraryIRI.fileSystemRepresentation
			    mode: @"r"]];
	OFFile *runtimeLinkLib =
	    [OFFile fileWithPath: runtimeLinkLibIRI.fileSystemRepresentation
			    mode: @"w"];
	OFFile *runtimeGlueHeader =
	    [OFFile fileWithPath: runtimeGlueHeaderIRI.fileSystemRepresentation
			    mode: @"w"];
	OFFile *runtimeGlue =
	    [OFFile fileWithPath: runtimeGlueIRI.fileSystemRepresentation
			    mode: @"w"];
	OFFile *runtimeFuncArray =
	    [OFFile fileWithPath: runtimeFuncArrayIRI.fileSystemRepresentation
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
