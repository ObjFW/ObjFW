/*
 * Copyright (c) 2008-2025 Jonathan Schleifer <js@nil.im>
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

#import "OHExtendedN64Controller.h"
#import "OHN64Controller.h"
#import "OHN64Controller+Private.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_GCF
# import "OFString+NSObject.h"
#endif
#import "OHGameControllerButton.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# include <linux/input.h>
#endif

static OFString *const buttonNames[] = {
	@"ZR", @"Home", @"Capture"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

#ifdef OF_HAVE_GCF
static OFDictionary<OFString *, NSString *> *buttonsMap;
static OFDictionary<OFString *, NSString *> *directionalPadsMap;
#endif

@implementation OHExtendedN64Controller
#ifdef OF_HAVE_GCF
+ (void)initialize
{
	void *pool;

	if (self != [OHExtendedN64Controller class])
		return;

	pool = objc_autoreleasePoolPush();

	buttonsMap = [[OFDictionary alloc] initWithKeysAndObjects:
	    @"A", @"Button A".NSObject,
	    @"B", @"Button B".NSObject,
	    @"L", @"Left Shoulder".NSObject,
	    @"R", @"Right Shoulder".NSObject,
	    @"Z", @"Left Trigger".NSObject,
	    @"Start", @"Button Menu".NSObject,
	    @"ZR", @"Right Trigger".NSObject,
	    @"Home", @"Button Home".NSObject,
	    @"Capture", @"Button Share".NSObject,
	    nil];
	directionalPadsMap = [[OFDictionary alloc] initWithKeysAndObjects:
	    @"Thumbstick", @"Left Thumbstick".NSObject,
	    @"C-Buttons", @"Right Thumbstick".NSObject,
	    @"D-Pad", @"Direction Pad".NSObject,
	    nil];

	objc_autoreleasePoolPop(pool);
}
#endif

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
	case BTN_TR2:
		return [_buttons objectForKey: @"ZR"];
	case BTN_MODE:
		return [_buttons objectForKey: @"Home"];
	case BTN_Z:
		return [_buttons objectForKey: @"Capture"];
	}

	return [super oh_buttonForEvdevButton: button];
}
#endif

#ifdef OF_HAVE_GCF
- (OFDictionary<OFString *, NSString *> *)oh_buttonsMap
{
	return buttonsMap;
}

- (OFDictionary<OFString *, NSString *> *)oh_axesMap
{
	return [OFDictionary dictionary];
}

- (OFDictionary<OFString *, NSString *> *)oh_directionalPadsMap
{
	return directionalPadsMap;
}
#endif
@end
