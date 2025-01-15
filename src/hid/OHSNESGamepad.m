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

#import "OHSNESGamepad.h"
#import "OHSNESGamepad+Private.h"
#import "OFDictionary.h"
#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
# import "OFString+NSObject.h"
#endif
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerDirectionalPad+Private.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# include <linux/input.h>
#endif

static OFString *const buttonNames[] = {
	@"A", @"B", @"X", @"Y", @"L", @"R", @"Start", @"Select"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
static OFDictionary<OFString *, NSString *> *buttonsMap;
static OFDictionary<OFString *, NSString *> *directionalPadsMap;
#endif

@implementation OHSNESGamepad
@synthesize buttons = _buttons, directionalPads = _directionalPads;

#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
+ (void)initialize
{
	void *pool;

	if (self != [OHSNESGamepad class])
		return;

	pool = objc_autoreleasePoolPush();

	buttonsMap = [[OFDictionary alloc] initWithKeysAndObjects:
	    @"A", @"Button A".NSObject,
	    @"B", @"Button B".NSObject,
	    @"X", @"Button X".NSObject,
	    @"Y", @"Button Y".NSObject,
	    @"L", @"Left Shoulder".NSObject,
	    @"R", @"Right Shoulder".NSObject,
	    @"Start", @"Button Menu".NSObject,
	    @"Select", @"Button Options".NSObject,
	    nil];
	directionalPadsMap = [[OFDictionary alloc] initWithKeysAndObjects:
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

		xAxis = [OHGameControllerAxis oh_elementWithName: @"D-Pad X"
							  analog: false];
		yAxis = [OHGameControllerAxis oh_elementWithName: @"D-Pad Y"
							  analog: false];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"D-Pad"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: false];
		_directionalPads = [[OFDictionary alloc]
		    initWithObject: directionalPad
			    forKey: @"D-Pad"];

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

- (OHGameControllerButton *)northButton
{
	return [_buttons objectForKey: @"X"];
}

- (OHGameControllerButton *)southButton
{
	return [_buttons objectForKey: @"B"];
}

- (OHGameControllerButton *)westButton
{
	return [_buttons objectForKey: @"Y"];
}

- (OHGameControllerButton *)eastButton
{
	return [_buttons objectForKey: @"A"];
}

- (OHGameControllerButton *)leftShoulderButton
{
	return [_buttons objectForKey: @"L"];
}

- (OHGameControllerButton *)rightShoulderButton
{
	return [_buttons objectForKey: @"R"];
}

- (OHGameControllerButton *)menuButton
{
	return [_buttons objectForKey: @"Start"];
}

- (OHGameControllerButton *)optionsButton
{
	return [_buttons objectForKey: @"Select"];
}

- (OHGameControllerDirectionalPad *)dPad
{
	return [_directionalPads objectForKey: @"D-Pad"];
}

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
- (OHGameControllerButton *)oh_buttonForEvdevButton: (uint16_t)button
{
	OFString *name;

	switch (button) {
	case BTN_EAST:
		name = @"A";
		break;
	case BTN_SOUTH:
		name = @"B";
		break;
	case BTN_NORTH:
		name = @"X";
		break;
	case BTN_WEST:
		name = @"Y";
		break;
	case BTN_TL:
		name = @"L";
		break;
	case BTN_TR:
		name = @"R";
		break;
	case BTN_START:
		name = @"Start";
		break;
	case BTN_SELECT:
		name = @"Select";
		break;
	default:
		return nil;
	}

	return [_buttons objectForKey: name];
}

- (OHGameControllerAxis *)oh_axisForEvdevAxis: (uint16_t)axis
{
	switch (axis) {
	case ABS_HAT0X:
		return [[_directionalPads objectForKey: @"D-Pad"] xAxis];
	case ABS_HAT0Y:
		return [[_directionalPads objectForKey: @"D-Pad"] yAxis];
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