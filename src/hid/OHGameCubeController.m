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

#import "OHGameCubeController.h"
#import "OHGameCubeController+Private.h"
#import "OFDictionary.h"
#ifdef OF_HAVE_GCF
# import "OFString+NSObject.h"
#endif
#import "OHEmulatedGameControllerTriggerButton.h"
#import "OHGameController.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerAxis+Private.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerDirectionalPad+Private.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# include <linux/input.h>
#endif

static OFString *const buttonNames[] = {
	@"A", @"B", @"X", @"Y", @"L", @"R", @"Z", @"Start"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

#ifdef OF_HAVE_GCF
static OFDictionary<OFString *, NSString *> *buttonsMap;
static OFDictionary<OFString *, NSString *> *directionalPadsMap;
#endif

@implementation OHGameCubeController
@synthesize buttons = _buttons, directionalPads = _directionalPads;

#ifdef OF_HAVE_GCF
+ (void)initialize
{
	void *pool;

	if (self != [OHGameCubeController class])
		return;

	pool = objc_autoreleasePoolPush();

	buttonsMap = [[OFDictionary alloc] initWithKeysAndObjects:
	    @"A", @"Button A".NSObject,
	    @"B", @"Button X".NSObject,
	    @"X", @"Button B".NSObject,
	    @"Y", @"Button Y".NSObject,
	    @"L", @"Left Trigger".NSObject,
	    @"R", @"Right Trigger".NSObject,
	    @"Z", @"Right Shoulder".NSObject,
	    @"Start", @"Button Menu".NSObject,
	    nil];
	directionalPadsMap = [[OFDictionary alloc] initWithKeysAndObjects:
	    @"Left Thumbstick", @"Left Thumbstick".NSObject,
	    @"Right Thumbstick", @"Right Thumbstick".NSObject,
	    @"D-Pad", @"Direction Pad".NSObject,
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
		OHGameControllerButton *button;
		OFMutableDictionary *directionalPads;
#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
		OHGameControllerAxis *axis;
#endif
		OHGameControllerAxis *xAxis, *yAxis;
		OHGameControllerDirectionalPad *directionalPad;

		for (size_t i = 0; i < numButtons; i++) {
			button = [OHGameControllerButton
			    oh_elementWithName: buttonNames[i]
					analog: false];
			[buttons setObject: button forKey: buttonNames[i]];
		}

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
		axis = [OHGameControllerAxis oh_elementWithName: @"L"
							 analog: true];
		button = [OHEmulatedGameControllerTriggerButton
		    oh_buttonWithName: @"L"
				 axis: axis];
		[buttons setObject: button forKey: @"L"];

		axis = [OHGameControllerAxis oh_elementWithName: @"R"
							 analog: true];
		button = [OHEmulatedGameControllerTriggerButton
		    oh_buttonWithName: @"R"
				 axis: axis];
		[buttons setObject: button forKey: @"R"];
#else
		button = [OHGameControllerButton oh_elementWithName: @"L"
							     analog: true];
		[buttons setObject: button forKey: @"L"];
		button = [OHGameControllerButton oh_elementWithName: @"R"
							     analog: true];
		[buttons setObject: button forKey: @"R"];
#endif

		[buttons makeImmutable];
		_buttons = [buttons copy];

		directionalPads =
		    [OFMutableDictionary dictionaryWithCapacity: 3];

		xAxis = [OHGameControllerAxis
		    oh_elementWithName: @"Left Thumbstick X"
				analog: true];
		yAxis = [OHGameControllerAxis
		    oh_elementWithName: @"Left Thumbstick Y"
				analog: true];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"Left Thumbstick"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: true];
		[directionalPads setObject: directionalPad
				    forKey: @"Left Thumbstick"];

		xAxis = [OHGameControllerAxis
		    oh_elementWithName: @"Right Thumbstick X"
				analog: true];
		yAxis = [OHGameControllerAxis
		    oh_elementWithName: @"Right Thumbstick Y"
				analog: true];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"Right Thumbstick"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: true];
		[directionalPads setObject: directionalPad
				    forKey: @"Right Thumbstick"];

		xAxis = [OHGameControllerAxis oh_elementWithName: @"D-Pad X"
							  analog: false];
		yAxis = [OHGameControllerAxis oh_elementWithName: @"D-Pad Y"
							  analog: false];
#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
		xAxis.oh_inverted = true;
		yAxis.oh_inverted = true;
#endif
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"D-Pad"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: false];
		[directionalPads setObject: directionalPad forKey: @"D-Pad"];

		[directionalPads makeImmutable];
		_directionalPads = objc_retain(directionalPads);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_buttons);
	objc_release(_directionalPads);

	[super dealloc];
}

- (OFDictionary OF_GENERIC(OFString *, OHGameControllerAxis *) *)axes
{
	return [OFDictionary dictionary];
}

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
- (OHGameControllerButton *)oh_buttonForEvdevButton: (uint16_t)button
{
	OFString *name;

	switch (button) {
	case BTN_THUMB:
		name = @"A";
		break;
	case BTN_THUMB2:
		name = @"B";
		break;
	case BTN_TRIGGER:
		name = @"X";
		break;
	case BTN_TOP:
		name = @"Y";
		break;
	case BTN_TOP2:
		name = @"L";
		break;
	case BTN_PINKIE:
		name = @"R";
		break;
	case BTN_BASE2:
		name = @"Z";
		break;
	case BTN_BASE4:
		name = @"Start";
		break;
	default:
		return nil;
	}

	return [_buttons objectForKey: name];
}

- (OHGameControllerAxis *)oh_axisForEvdevAxis: (uint16_t)axis
{
	switch (axis) {
	case ABS_X:
		return [[_directionalPads objectForKey: @"Left Thumbstick"]
		    xAxis];
	case ABS_Y:
		return [[_directionalPads objectForKey: @"Left Thumbstick"]
		    yAxis];
	case ABS_RZ:
		return [[_directionalPads objectForKey:
		    @"Right Thumbstick"] xAxis];
	case ABS_Z:
		return [[_directionalPads objectForKey:
		    @"Right Thumbstick"] yAxis];
	case ABS_HAT0X:
		return [[_directionalPads objectForKey: @"D-Pad"] xAxis];
	case ABS_HAT0Y:
		return [[_directionalPads objectForKey: @"D-Pad"] yAxis];
	default:
		return nil;
	}
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
