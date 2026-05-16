/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#include "config.h"

#import "OHGameController.h"
#import "OFArray.h"
#import "OFNumber.h"
#import "OFSet.h"

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# import "OHEvdevGameController.h"
#endif
#ifdef OF_WINDOWS
# import "OHXInputGameController.h"
#endif
#ifdef OF_NINTENDO_DS
# import "OHNintendoDSGameController.h"
#endif
#ifdef OF_NINTENDO_3DS
# import "OHNintendo3DSGameController.h"
#endif
#ifdef OF_WII
# import "OHWiiGameController.h"
#endif
#ifdef OF_NINTENDO_SWITCH
# import "OHNintendoSwitchGameController.h"
#endif
#ifdef OF_HAVE_GCF
# import "OHGCFGameController.h"
#endif

@implementation OHGameController
@dynamic name, profile;

+ (OFArray OF_GENERIC(OHGameController *) *)controllers
{
#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
	return [OHEvdevGameController controllers];
#elif defined(OF_WINDOWS)
	return [OHXInputGameController controllers];
#elif defined(OF_NINTENDO_DS)
	return [OHNintendoDSGameController controllers];
#elif defined(OF_NINTENDO_3DS)
	return [OHNintendo3DSGameController controllers];
#elif defined(OF_WII)
	return [OHWiiGameController controllers];
#elif defined(OF_NINTENDO_SWITCH)
	return [OHNintendoSwitchGameController controllers];
#elif defined(OF_HAVE_GCF)
	if (@available(macOS 14.0, iOS 17.0, *))
		return [OHGCFGameController controllers];
	else
		return [OFArray array];
#else
	return [OFArray array];
#endif
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)oh_init
{
	return [super init];
}

- (OHVIDPID)VIDPID
{
	return (OHVIDPID){ 0, 0 };
}

- (OFNumber *)vendorID
{
	OHVIDPID VIDPID = self.VIDPID;

	if (VIDPID.vendorID != 0 && VIDPID.productID != 0)
		return [OFNumber numberWithUnsignedShort: VIDPID.vendorID];

	return nil;
}

- (OFNumber *)productID
{
	OHVIDPID VIDPID = self.VIDPID;

	if (VIDPID.vendorID != 0 && VIDPID.productID != 0)
		return [OFNumber numberWithUnsignedShort: VIDPID.productID];

	return nil;
}

- (void)updateState
{
	OF_UNRECOGNIZED_SELECTOR
}

- (id <OHGamepad>)gamepad
{
	return nil;
}

- (id <OHExtendedGamepad>)extendedGamepad
{
	return nil;
}

- (OFString *)description
{
	if (self.VIDPID.vendorID != 0 && self.VIDPID.productID != 0)
		return [OFString stringWithFormat:
		    @"<%@: %@ [%04X:%04X]>",
		    self.class, self.name, self.VIDPID.vendorID,
		    self.VIDPID.productID];
	else
		return [OFString stringWithFormat: @"<%@: %@>",
						   self.class, self.name];
}
@end
