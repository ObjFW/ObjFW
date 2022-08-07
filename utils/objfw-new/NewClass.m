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

#include <errno.h>

#import "OFApplication.h"
#import "OFFile.h"
#import "OFStdIOStream.h"
#import "OFString.h"

#import "OFOpenItemFailedException.h"

void
newClass(OFString *name)
{
	OFString *headerPath = [name stringByAppendingPathExtension: @"h"];
	OFString *implPath = [name stringByAppendingPathExtension: @"m"];
	OFFile *headerFile, *implFile;
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

	[headerFile writeFormat: @"#import <ObjFW/ObjFW.h>\n"
				 @"\n"
				 @"@interface %@: OFObject\n"
				 @"@end\n",
				 name];

	[implFile writeFormat: @"#import \"%@\"\n"
			       @"\n"
			       @"@implementation %@\n"
			       @"@end\n",
			       headerPath, name];

	[headerFile close];
	[implFile close];
}
