/*
 * Copyright (c) 2008 - 2010
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFString.h"

#ifdef OF_APPLE_RUNTIME
extern void *_OFConstantStringClassReference;
#endif

/**
 * \brief A class for storing constant strings using the \@"" literal.
 */
@interface OFConstantString: OFString {}
@end
