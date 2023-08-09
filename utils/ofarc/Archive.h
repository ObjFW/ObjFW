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

#import "OFObject.h"
#import "OFFile.h"
#import "OFArray.h"

OF_ASSUME_NONNULL_BEGIN

@protocol Archive <OFObject>
+ (instancetype)archiveWithPath: (OFString *)path
			 stream: (OF_KINDOF(OFStream *))stream
			   mode: (OFString *)mode
		       encoding: (OFStringEncoding)encoding;
- (instancetype)initWithPath: (OFString *)path
		      stream: (OF_KINDOF(OFStream *))stream
			mode: (OFString *)mode
		    encoding: (OFStringEncoding)encoding;
- (void)listFiles;
- (void)extractFiles: (OFArray OF_GENERIC(OFString *) *)files;
- (void)printFiles: (OFArray OF_GENERIC(OFString *) *)files;
@optional
- (void)addFiles: (OFArray OF_GENERIC(OFString *) *)files;
@end

OF_ASSUME_NONNULL_END
