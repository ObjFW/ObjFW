/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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
	    IRIByAppendingPathComponent: @"amiga-library-glue.h"];
	OFIRI *glueIRI = [sourcesIRI
	    IRIByAppendingPathComponent: @"amiga-library-glue.m"];
	OFIRI *funcArrayIRI = [sourcesIRI
	    IRIByAppendingPathComponent: @"amiga-library-funcarray.inc"];
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
	    [OFFile fileWithPath: glueIRI.fileSystemRepresentation
			    mode: @"w"];
	OFFile *funcArray =
	    [OFFile fileWithPath: funcArrayIRI.fileSystemRepresentation
			    mode: @"w"];
	LinkLibGenerator *linkLibGenerator = objc_autorelease(
	    [[LinkLibGenerator alloc] initWithLibrary: library
				       implementation: linkLib]);
	GlueGenerator *glueGenerator = objc_autorelease(
	    [[GlueGenerator alloc] initWithLibrary: library
					    header: glueHeader
				    implementation: glue]);
	FuncArrayGenerator *funcArrayGenerator = objc_autorelease(
	    [[FuncArrayGenerator alloc] initWithLibrary: library
						include: funcArray]);

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
