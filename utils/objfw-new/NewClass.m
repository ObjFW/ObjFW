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

#include <errno.h>

#import "Property.h"

#import "OFApplication.h"
#import "OFArray.h"
#import "OFFile.h"
#import "OFStdIOStream.h"
#import "OFString.h"

#import "OFOpenItemFailedException.h"

void
newClass(OFString *name, OFString *superclass, OFMutableArray *properties)
{
	OFString *headerPath = [name stringByAppendingPathExtension: @"h"];
	OFString *implPath = [name stringByAppendingPathExtension: @"m"];
	OFFile *headerFile = nil, *implFile = nil;
	bool needsDealloc = false;
	@try {
		headerFile = [OFFile fileWithPath: headerPath mode: @"wx"];
		implFile = [OFFile fileWithPath: implPath mode: @"wx"];
	} @catch (OFOpenItemFailedException *e) {
		if (e.errNo != EEXIST)
			@throw e;

		[OFStdErr writeFormat: @"File %@ already exists! Aborting...\n",
				       e.path];
		[OFApplication terminateWithStatus: 1];
	}

	if (superclass == nil)
		superclass = @"OFObject";

	for (size_t i = 0; i < properties.count; i++) {
		Property *property = [Property propertyWithString:
		    [properties objectAtIndex: i]];
		[properties replaceObjectAtIndex: i
				      withObject: property];
	}

	[headerFile writeFormat: @"#import <ObjFW/ObjFW.h>\n"
				 @"\n"
				 @"OF_ASSUME_NONNULL_BEGIN\n"
				 @"\n"
				 @"@interface %@: %@\n",
				 name, superclass];

	if (properties.count > 0)
		[headerFile writeString: @"{\n"];

	for (Property *property in properties)
		[headerFile writeFormat: @"\t%@_%@;\n",
					 property.type, property.name];

	if (properties.count > 0)
		[headerFile writeString: @"}\n\n"];

	for (Property *property in properties) {
		[headerFile writeString: @"@property "];

		if (property.attributes.count > 0) {
			bool first = true;

			if ([property.attributes containsObject: @"nullable"])
				[headerFile writeString:
				    @"OF_NULLABLE_PROPERTY "];

			[headerFile writeString: @"("];

			for (OFString *attribute in property.attributes) {
				if ([attribute isEqual: @"nullable"])
					continue;

				if ([attribute isEqual: @"retain"] ||
				    [attribute isEqual: @"copy"])
					needsDealloc = true;

				if (!first)
					[headerFile writeString: @", "];

				[headerFile writeString: attribute];
				first = false;
			}

			[headerFile writeString: @") "];
		}

		[headerFile writeFormat: @"%@%@;\n",
					 property.type, property.name];
	}

	[headerFile writeString: @"@end\n"
				 @"\n"
				 @"OF_ASSUME_NONNULL_END\n"];

	[implFile writeFormat: @"#import \"%@\"\n"
			       @"\n"
			       @"@implementation %@\n",
			       headerPath, name];

	for (Property *property in properties)
		[implFile writeFormat: @"@synthesize %@ = _%@;\n",
				       property.name, property.name];

	if (needsDealloc) {
		[implFile writeString: @"\n"
				       @"- (void)dealloc\n"
				       @"{\n"];

		for (Property *property in properties)
			if ([property.attributes containsObject: @"retain"] ||
			    [property.attributes containsObject: @"copy"])
				[implFile writeFormat:
				    @"\tobjc_release(_%@);\n", property.name];

		[implFile writeString: @"\n"
				       @"\t[super dealloc];\n"
				       @"}\n"];
	}

	[implFile writeString: @"@end\n"];

	[headerFile close];
	[implFile close];
}
