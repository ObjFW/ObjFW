/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#import "OFGameController.h"
#import "OFArray.h"

#import "OFOutOfRangeException.h"

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# include "platform/Linux/OFGameController.m"
#elif defined(OF_NINTENDO_DS)
# include "platform/NintendoDS/OFGameController.m"
#elif defined(OF_NINTENDO_3DS)
# include "platform/Nintendo3DS/OFGameController.m"
#else
@implementation OFGameController
@dynamic name, buttons, pressedButtons, numAnalogSticks;

+ (OFArray OF_GENERIC(OFGameController *) *)controllers
{
	return [OFArray array];
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (OFPoint)positionOfAnalogStickWithIndex: (size_t)index
{
	OF_UNRECOGNIZED_SELECTOR
}
@end
#endif
