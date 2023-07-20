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

#import "OFStdIOStream.h"

OF_ASSUME_NONNULL_BEGIN

OF_DIRECT_MEMBERS
@interface OFStdIOStream ()
#if defined(OF_AMIGAOS)
- (instancetype)of_initWithHandle: (BPTR)handle
			 closable: (bool)closable OF_METHOD_FAMILY(init);
#elif defined(OF_WII_U)
- (instancetype)of_init OF_METHOD_FAMILY(init);
#else
- (instancetype)of_initWithFileDescriptor: (int)fd OF_METHOD_FAMILY(init);
#endif
@end

OF_ASSUME_NONNULL_END
