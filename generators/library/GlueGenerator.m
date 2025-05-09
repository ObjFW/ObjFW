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

#import "OFArray.h"
#import "OFXMLAttribute.h"

#import "GlueGenerator.h"

#import "OFInvalidFormatException.h"
#import "OFUnsupportedVersionException.h"

#import "copyright.h"

@implementation GlueGenerator
- (instancetype)initWithLibrary: (OFXMLElement *)library
			 header: (OFStream *)header
	  morphOSImplementation: (OFStream *)morphOSImpl
{
	self = [super init];

	@try {
		OFXMLAttribute *version;

		if (![library.name isEqual: @"amiga-library"] ||
		    library.namespace != nil)
			@throw [OFInvalidFormatException exception];

		if ((version = [library attributeForName: @"version"]) == nil)
			@throw [OFInvalidFormatException exception];

		if (![version.stringValue isEqual: @"1.0"])
			@throw [OFUnsupportedVersionException
			    exceptionWithVersion: version.stringValue];

		_library = [library retain];
		_header = [header retain];
		_morphOSImpl = [morphOSImpl retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_library release];
	[_header release];
	[_morphOSImpl release];

	[super dealloc];
}

- (void)generate
{
	size_t includes = 0;

	[_header writeString: COPYRIGHT];
	[_morphOSImpl writeString: COPYRIGHT];

	[_header writeString:
	    @"/* This file is automatically generated from amiga-library.xml */"
	    @"\n\n"];

	[_morphOSImpl writeString:
	    @"/* This file is automatically generated from amiga-library.xml */"
	    @"\n\n"
	    @"#include \"config.h\"\n"
	    @"\n"
	    @".section .text\n"];

	for (OFXMLElement *include in [_library elementsForName: @"include"]) {
		[_header writeFormat: @"#import \"%@\"\n",
				      include.stringValue];
		includes++;
	}

	if (includes > 0)
		[_header writeString: @"\n"];

	for (OFXMLElement *function in
	    [_library elementsForName: @"function"]) {
		OFString *name =
		    [function attributeForName: @"name"].stringValue;
		OFString *returnType =
		    [function attributeForName: @"return-type"].stringValue;
		OFArray OF_GENERIC(OFXMLElement *) *arguments =
		    [function elementsForName: @"argument"];
		size_t argumentIndex;

		if (returnType == nil)
			returnType = @"void";

		[_header writeFormat:
		    @"extern %@%@glue_%@",
		    returnType,
		    (![returnType hasSuffix: @"*"] ? @" " : @""),
		    name];

		if (arguments.count > 0)
			[_header writeString: @"("];
		else
			[_header writeString: @"(void"];

		argumentIndex = 0;
		for (OFXMLElement *argument in arguments) {
			OFString *argName =
			    [argument attributeForName: @"name"].stringValue;
			OFString *argType =
			    [argument attributeForName: @"type"].stringValue;

			if (argumentIndex++ > 0)
				[_header writeString: @", "];

			[_header writeString: argType];
			if (![argType hasSuffix: @"*"])
				[_header writeString: @" "];
			[_header writeString: argName];
		}

		[_header writeString: @");\n"];

		[_morphOSImpl writeFormat:
		    @"\n"
		    @".globl glue_%@\n"
		    @"glue_%@:\n"
		    @"	lwz	%%r13, 44(%%r12)\n"
		    @"	b	%@\n",
		    name, name, name];
	}
}
@end
