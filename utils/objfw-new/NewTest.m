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
newTest(OFString *name)
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
			   @"#import <ObjFWTest/ObjFWTest.h>\n"
			   @"\n"
			   @"@interface %@: OTTestCase\n"
			   @"@end\n"
			   @"\n"
			   @"@implementation %@\n"
			   @"@end\n",
			   name, name];

	[file close];
}
