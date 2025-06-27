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

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFIRI;
@class OFStream;

@protocol Archive <OFObject>
+ (instancetype)archiveWithIRI: (nullable OFIRI *)IRI
			stream: (OF_KINDOF(OFStream *))stream
			  mode: (OFString *)mode
		      encoding: (OFStringEncoding)encoding;
- (instancetype)initWithIRI: (nullable OFIRI *)IRI
		     stream: (OF_KINDOF(OFStream *))stream
		       mode: (OFString *)mode
		   encoding: (OFStringEncoding)encoding;
- (void)listFiles;
- (void)extractFiles: (OFArray OF_GENERIC(OFString *) *)files;
- (void)printFiles: (OFArray OF_GENERIC(OFString *) *)files;
@optional
- (void)addFiles: (OFArray OF_GENERIC(OFString *) *)files
  archiveComment: (nullable OFString *)archiveComment;
@end

OF_ASSUME_NONNULL_END
