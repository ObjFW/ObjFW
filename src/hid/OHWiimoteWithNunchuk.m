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

#import "OHWiimoteWithNunchuk.h"
#import "OFDictionary.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerDirectionalPad+Private.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"
#import "OHWiimote+Private.h"

static OFString *const buttonNames[] = {
	@"C", @"Z"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHWiimoteWithNunchuk
- (instancetype)oh_init
{
	self = [super oh_init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttons =
		    objc_autorelease([_buttons mutableCopy]);
		OFMutableDictionary *directionalPads =
		    objc_autorelease([_directionalPads mutableCopy]);
		OHGameControllerAxis *xAxis, *yAxis;
		OHGameControllerDirectionalPad *directionalPad;

		for (size_t i = 0; i < numButtons; i++) {
			OHGameControllerButton *button = [OHGameControllerButton
			    oh_elementWithName: buttonNames[i]
					analog: false];

			[buttons setObject: button forKey: buttonNames[i]];
		}

		xAxis = [OHGameControllerAxis
		    oh_elementWithName: @"Analog Stick X"
				analog: true];
		yAxis = [OHGameControllerAxis
		    oh_elementWithName: @"Analog Stick Y"
				analog: true];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"Analog Stick"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: true];
		[directionalPads setObject: directionalPad
				    forKey: @"Analog Stick"];

		[buttons makeImmutable];
		objc_release(_buttons);
		_buttons = nil;
		_buttons = [buttons copy];

		[directionalPads makeImmutable];
		objc_release(_directionalPads);
		_directionalPads = nil;
		_directionalPads = [directionalPads copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}
@end
