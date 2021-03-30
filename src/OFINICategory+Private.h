/*
 * Copyright (c) 2008-2021 Jonathan Schleifer <js@nil.im>
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

#import "OFINICategory.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@class OFStream;

OF_DIRECT_MEMBERS
@interface OFINICategory ()
- (instancetype)of_initWithName: (OFString *)name OF_METHOD_FAMILY(init);
- (void)of_parseLine: (OFString *)line;
- (bool)of_writeToStream: (OFStream *)stream
		encoding: (of_string_encoding_t)encoding
		   first: (bool)first;
@end

OF_ASSUME_NONNULL_END
