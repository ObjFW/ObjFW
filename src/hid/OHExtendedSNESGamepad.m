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

#import "OHExtendedSNESGamepad.h"
#import "OHSNESGamepad.h"
#import "OHSNESGamepad+Private.h"
#import "OFDictionary.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# include <linux/input.h>
#endif

static OFString *const buttonNames[] = {
	@"ZL", @"ZR"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHExtendedSNESGamepad
- (instancetype)oh_init
{
	self = [super oh_init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttons =
		    objc_autorelease([_buttons mutableCopy]);

		for (size_t i = 0; i < numButtons; i++) {
			OHGameControllerButton *button = [OHGameControllerButton
			    oh_elementWithName: buttonNames[i]
					analog: false];
			[buttons setObject: button forKey: buttonNames[i]];
		}
		[buttons makeImmutable];
		objc_release(_buttons);
		_buttons = nil;
		_buttons = [buttons copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
- (OHGameControllerButton *)oh_buttonForEvdevButton: (uint16_t)button
{
	switch (button) {
	case BTN_TL2:
		return [_buttons objectForKey: @"ZL"];
	case BTN_TR2:
		return [_buttons objectForKey: @"ZR"];
	}

	return [super oh_buttonForEvdevButton: button];
}
#endif
@end
