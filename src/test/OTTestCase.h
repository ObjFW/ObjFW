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

#ifdef OBJFWTEST_LOCAL_INCLUDES
# import "ObjFW.h"
#else
# import <ObjFW/ObjFW.h>
#endif

OF_ASSUME_NONNULL_BEGIN

@interface OTTestCase: OFObject
#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nullable, nonatomic)
    OFArray OF_GENERIC(OFPair OF_GENERIC(OFString *, id) *) *summary;
#endif

+ (nullable OFArray OF_GENERIC(OFPair OF_GENERIC(OFString *, id) *) *)summary;
- (void)setUp;
- (void)tearDown;
@end

OF_ASSUME_NONNULL_END
