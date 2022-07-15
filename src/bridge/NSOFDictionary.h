/*
 * Copyright (c) 2008-2022 Jonathan Schleifer <js@nil.im>
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

#import <Foundation/NSDictionary.h>

#import "macros.h"

@class OFDictionary;

OF_ASSUME_NONNULL_BEGIN

@interface NSOFDictionary: NSDictionary
{
	OFDictionary *_dictionary;
}

- (instancetype)initWithOFDictionary: (OFDictionary *)dictionary;
@end

OF_ASSUME_NONNULL_END
