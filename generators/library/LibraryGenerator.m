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
- (void)generateInDirectory: (OFString *)directory
{
	OFIRI *sourcesIRI = [[OFFileManager defaultManager].currentDirectoryIRI
	    IRIByAppendingPathComponent: directory];
	OFIRI *libraryIRI = [sourcesIRI
	    IRIByAppendingPathComponent: @"amiga-library.xml"];
	OFIRI *linkLibIRI = [sourcesIRI
	    IRIByAppendingPathComponent: @"linklib/linklib.m"];
	OFIRI *glueHeaderIRI = [sourcesIRI
	    IRIByAppendingPathComponent: @"amiga-glue.h"];
	OFIRI *glueIRI = [sourcesIRI
	    IRIByAppendingPathComponent: @"amiga-glue.m"];
	OFIRI *funcArrayIRI = [sourcesIRI
	    IRIByAppendingPathComponent: @"amiga-funcarray.inc"];
	OFXMLElement *library = [OFXMLElement elementWithStream:
	    [OFFile fileWithPath: libraryIRI.fileSystemRepresentation
			    mode: @"r"]];
	OFFile *linkLib =
	    [OFFile fileWithPath: linkLibIRI.fileSystemRepresentation
			    mode: @"w"];
	OFFile *glueHeader =
	    [OFFile fileWithPath: glueHeaderIRI.fileSystemRepresentation
			    mode: @"w"];
	OFFile *glue =
	    [OFFile fileWithPath: glueIRI.fileSystemRepresentation mode: @"w"];
	OFFile *funcArray =
	    [OFFile fileWithPath: funcArrayIRI.fileSystemRepresentation
			    mode: @"w"];
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

- (void)applicationDidFinishLaunching: (OFNotification *)notification
{
	[self generateInDirectory: @"../../src"];
	[self generateInDirectory: @"../../src/runtime"];

	[OFApplication terminate];
}
@end
