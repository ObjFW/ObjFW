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

#import "NSOFEnumerator.h"
#import "OFEnumerator.h"

#import "NSBridging.h"
#import "OFBridging.h"

@implementation NSOFEnumerator
- (instancetype)initWithOFEnumerator: (OFEnumerator *)enumerator
{
	if ((self = [super init]) != nil)
		_enumerator = [enumerator retain];

	return self;
}

- (void)dealloc
{
	[_enumerator release];

	[super dealloc];
}

- (id)nextObject
{
	id object = [_enumerator nextObject];

	if ([(OFObject *)object conformsToProtocol: @protocol(OFBridging)])
		return [object NSObject];

	return object;
}
@end
