/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFObject.h"
#import "OFString.h"

#import "Archive.h"

OF_ASSUME_NONNULL_BEGIN

@class OFIRI;

#ifndef S_IRWXG
# define S_IRWXG 0
#endif
#ifndef S_IRWXO
# define S_IRWXO 0
#endif

@interface OFArc: OFObject <OFApplicationDelegate>
{
	int8_t _overwrite;
@public
	int8_t _outputLevel;
	int _exitStatus;
}

- (id <Archive>)openArchiveWithIRI: (nullable OFIRI *)IRI
			      type: (OFString *)type
			      mode: (char)mode
			  encoding: (OFStringEncoding)encoding;
- (bool)shouldExtractFile: (OFString *)fileName
	      outFileName: (OFString *)outFileName;
- (ssize_t)copyBlockFromStream: (OFStream *)input
		      toStream: (OFStream *)output
		      fileName: (OFString *)fileName;
- (nullable OFString *)safeLocalPathForPath: (OFString *)path;
@end

OF_ASSUME_NONNULL_END
