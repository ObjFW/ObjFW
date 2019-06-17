/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFMutableString.h"
#import "OFUTF8String.h"

OF_ASSUME_NONNULL_BEGIN

@interface OFMutableUTF8String: OFMutableString
{
@public
	struct of_string_utf8_ivars *restrict _s;
	struct of_string_utf8_ivars _storage;
}
@end

OF_ASSUME_NONNULL_END
