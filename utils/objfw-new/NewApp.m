/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFApplication.h"
#import "OFFile.h"
#import "OFStdIOStream.h"
#import "OFString.h"

#import "OFOpenItemFailedException.h"

void
newApp(OFString *name)
{
	OFString *path = [name stringByAppendingPathExtension: @"m"];
	OFFile *file = nil;
	@try {
		file = [OFFile fileWithPath: path mode: @"wx"];
	} @catch (OFOpenItemFailedException *e) {
		if (e.errNo != EEXIST)
			@throw e;

		[OFStdErr writeFormat: @"File %@ already exists! Aborting...\n",
				       e.path];
		[OFApplication terminateWithStatus: 1];
	}

	[file writeFormat: @"#import <ObjFW/ObjFW.h>\n"
			   @"\n"
			   @"@interface %@: OFObject <OFApplicationDelegate>\n"
			   @"@end\n"
			   @"\n"
			   @"OF_APPLICATION_DELEGATE(%@)\n"
			   @"\n"
			   @"@implementation %@\n"
			   @"- (void)applicationDidFinishLaunching: "
			   @"(OFNotification *)notification\n"
			   @"{\n"
			   @"	[OFApplication terminate];\n"
			   @"}\n"
			   @"@end\n",
			   name, name, name];

	[file close];
}
