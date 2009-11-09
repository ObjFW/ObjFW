/*
 * Copyright (c) 2008 - 2009
 *   Jonathan Schleifer <js@webkeks.org>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE included in
 * the packaging of this file.
 */

#import "OFString.h"

#ifndef __objc_INCLUDE_GNU
#import <objc/runtime.h>

extern void *_OFConstStringClassReference;
#endif

/**
 * A class for storing static strings using the @"" literal.
 */
@interface OFConstString: OFString {}
@end
