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
	OFData *_quarantine;
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
- (void)quarantineFile: (OFString *)path;
@end

OF_ASSUME_NONNULL_END
