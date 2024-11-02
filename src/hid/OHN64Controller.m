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

#import "OHN64Controller.h"
#import "OHN64Controller+Private.h"
#import "OFDictionary.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# include <linux/input.h>
#endif

static OFString *const buttonNames[] = {
	@"A", @"B", @"L", @"R", @"Z", @"Start"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHN64Controller
@synthesize buttons = _buttons, directionalPads = _directionalPads;

- (instancetype)init
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttons =
		    [OFMutableDictionary dictionaryWithCapacity: numButtons];
		OFMutableDictionary *directionalPads;
		OHGameControllerAxis *xAxis, *yAxis;
		OHGameControllerDirectionalPad *directionalPad;
		OHGameControllerButton *up, *down, *left, *right;

		for (size_t i = 0; i < numButtons; i++) {
			OHGameControllerButton *button =
			    [[[OHGameControllerButton alloc]
			    initWithName: buttonNames[i]
				  analog: false] autorelease];
			[buttons setObject: button forKey: buttonNames[i]];
		}
		[buttons makeImmutable];
		_buttons = [buttons retain];

		directionalPads =
		    [OFMutableDictionary dictionaryWithCapacity: 3];

		xAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"X"
			  analog: true] autorelease];
		yAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"Y"
			  analog: true] autorelease];
		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"Thumbstick"
			   xAxis: xAxis
			   yAxis: yAxis
			  analog: true] autorelease];
		[directionalPads setObject: directionalPad
				    forKey: @"Thumbstick"];

		xAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"D-Pad X"
			  analog: false] autorelease];
		yAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"D-Pad Y"
			  analog: false] autorelease];
		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"D-Pad"
			   xAxis: xAxis
			   yAxis: yAxis
			  analog: false] autorelease];
		[directionalPads setObject: directionalPad forKey: @"D-Pad"];

		up = [[[OHGameControllerButton alloc]
		    initWithName: @"C-Up"
			  analog: false] autorelease];
		down = [[[OHGameControllerButton alloc]
		    initWithName: @"C-Down"
			  analog: false] autorelease];
		left = [[[OHGameControllerButton alloc]
		    initWithName: @"C-Left"
			  analog: false] autorelease];
		right = [[[OHGameControllerButton alloc]
		    initWithName: @"C-Right"
			  analog: false] autorelease];
		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"C-Buttons"
			      up: up
			    down: down
			    left: left
			   right: right
			  analog: false] autorelease];
		[directionalPads setObject: directionalPad
				    forKey: @"C-Buttons"];

		[directionalPads makeImmutable];
		_directionalPads = [directionalPads retain];

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
	case BTN_A:
		return [_buttons objectForKey: @"A"];
	case BTN_B:
		return [_buttons objectForKey: @"B"];
	case BTN_TL2:
		return [_buttons objectForKey: @"Z"];
	case BTN_SELECT:
		return [[_directionalPads objectForKey: @"C-Buttons"] up];
	case BTN_X:
		return [[_directionalPads objectForKey: @"C-Buttons"] down];
	case BTN_Y:
		return [[_directionalPads objectForKey: @"C-Buttons"] left];
	case BTN_C:
		return [[_directionalPads objectForKey: @"C-Buttons"] right];
	case BTN_TL:
		return [_buttons objectForKey: @"L"];
	case BTN_TR:
		return [_buttons objectForKey: @"R"];
	case BTN_START:
		return [_buttons objectForKey: @"Start"];
	}

	return nil;
}

- (OHGameControllerAxis *)oh_axisForEvdevAxis: (uint16_t)axis
{
	switch (axis) {
	case ABS_X:
		return [[_directionalPads objectForKey: @"Thumbstick"] xAxis];
	case ABS_Y:
		return [[_directionalPads objectForKey: @"Thumbstick"] yAxis];
	case ABS_HAT0X:
		return [[_directionalPads objectForKey: @"D-Pad"] xAxis];
	case ABS_HAT0Y:
		return [[_directionalPads objectForKey: @"D-Pad"] yAxis];
	}

	return nil;
}
#endif
@end
