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

#import "OHSensorsLibraryGameController.h"
#import "OFArray.h"
#import "OHGameController.h"
#import "OHGameController+Private.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"

#import "OFInitializationFailedException.h"

#include <proto/exec.h>

static struct Library *SensorsBase;
static struct Library *PsdBase;

OF_DESTRUCTOR()
{
	if (PsdBase != NULL)
		CloseLibrary(PsdBase);

	if (SensorsBase != NULL)
		CloseLibrary(SensorsBase);
}

@implementation OHSensorsLibraryGameController
+ (void)initialize
{
	if (self != [OHSensorsLibraryGameController class])
		return;

	if ((SensorsBase = OpenLibrary("sensors.library", 53)) == NULL)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];

	if ((PsdBase = OpenLibrary("poseidon.library", 1)) == NULL)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

+ (OFArray OF_GENERIC(OHGameController *) *)controllers
{
	OFMutableArray *controllers = [OFMutableArray array];

	[controllers makeImmutable];

	return controllers;
}

- (instancetype)oh_init
{
	OF_INVALID_INIT_METHOD
}
@end
