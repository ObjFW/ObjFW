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

#import "OHLeftJoyCon.h"
#import "OHLeftJoyCon+Private.h"
#import "OFDictionary.h"
#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
# import "OFString+NSObject.h"
#endif
#import "OHGameControllerAxis.h"
#import "OHGameControllerAxis+Private.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerDirectionalPad+Private.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# include <linux/input.h>
# import "evdev_compat.h"
#endif

static OFString *const buttonNames[] = {
	@"North", @"South", @"West", @"East", @"SL", @"SR", @"-",
#ifndef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
	/* GameController.framework doesn't expose a lot of buttons. */
	@"L", @"ZL", @"Left Thumbstick", @"Capture"
#endif
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
static OFDictionary<OFString *, NSString *> *buttonsMap;
static OFDictionary<OFString *, NSString *> *directionalPadsMap;
#endif

@implementation OHLeftJoyCon
@synthesize buttons = _buttons, directionalPads = _directionalPads;

#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
+ (void)initialize
{
	void *pool;

	if (self != [OHLeftJoyCon class])
		return;

	pool = objc_autoreleasePoolPush();

	buttonsMap = [[OFDictionary alloc] initWithKeysAndObjects:
	    @"North", @"Button Y".NSObject,
	    @"South", @"Button A".NSObject,
	    @"West", @"Button B".NSObject,
	    @"East", @"Button X".NSObject,
	    @"SL", @"Left Shoulder".NSObject,
	    @"SR", @"Right Shoulder".NSObject,
	    @"-", @"Button Menu".NSObject,
	    nil];
	directionalPadsMap = [[OFDictionary alloc] initWithKeysAndObjects:
	    @"Left Thumbstick", @"Direction Pad".NSObject,
	    nil];

	objc_autoreleasePoolPop(pool);
}
#endif

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)oh_init
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttons =
		    [OFMutableDictionary dictionaryWithCapacity: numButtons];
		OHGameControllerAxis *xAxis, *yAxis;
		OHGameControllerDirectionalPad *directionalPad;

		for (size_t i = 0; i < numButtons; i++) {
			OHGameControllerButton *button = [OHGameControllerButton
			    oh_elementWithName: buttonNames[i]
					analog: false];
			[buttons setObject: button forKey: buttonNames[i]];
		}
		[buttons makeImmutable];
		_buttons = [buttons copy];

		xAxis = [OHGameControllerAxis
		    oh_elementWithName: @"Left Thumbstick X"
				analog: true];
		yAxis = [OHGameControllerAxis
		    oh_elementWithName: @"Left Thumbstick Y"
				analog: true];
#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
		yAxis.oh_inverted = true;
#endif
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"Left Thumbstick"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: true];
		_directionalPads = [[OFDictionary alloc]
		    initWithObject: directionalPad
			    forKey: @"Left Thumbstick"];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_buttons release];
	[_directionalPads release];

	[super dealloc];
}

- (OFDictionary OF_GENERIC(OFString *, OHGameControllerAxis *) *)axes
{
	return [OFDictionary dictionary];
}

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
- (OHGameControllerButton *)oh_buttonForEvdevButton: (uint16_t)button
{
	switch (button) {
	case BTN_DPAD_UP:
		return [_buttons objectForKey: @"West"];
	case BTN_DPAD_DOWN:
		return [_buttons objectForKey: @"East"];
	case BTN_DPAD_LEFT:
		return [_buttons objectForKey: @"South"];
	case BTN_DPAD_RIGHT:
		return [_buttons objectForKey: @"North"];
	case BTN_TL:
		return [_buttons objectForKey: @"L"];
	case BTN_TL2:
		return [_buttons objectForKey: @"ZL"];
	case BTN_THUMBL:
		return [_buttons objectForKey: @"Left Thumbstick"];
	case BTN_SELECT:
		return [_buttons objectForKey: @"-"];
	case BTN_Z:
		return [_buttons objectForKey: @"Capture"];
	case BTN_TR:
		return [_buttons objectForKey: @"SL"];
	case BTN_TR2:
		return [_buttons objectForKey: @"SR"];
	}

	return nil;
}

- (OHGameControllerAxis *)oh_axisForEvdevAxis: (uint16_t)axis
{
	switch (axis) {
	case ABS_X:
		return [[_directionalPads objectForKey: @"Left Thumbstick"]
		    yAxis];
	case ABS_Y:
		return [[_directionalPads objectForKey: @"Left Thumbstick"]
		    xAxis];
	}

	return nil;
}
#endif

#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
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
