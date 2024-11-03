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

#import "OHWiiGameController.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHWiiClassicController.h"
#import "OHWiiClassicController+Private.h"
#import "OHWiimote.h"
#import "OHWiimote+Private.h"
#import "OHWiimoteWithNunchuk.h"

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFReadFailedException.h"

#define asm __asm__
#include <wiiuse/wpad.h>
#undef asm

static float
scale(float value, float min, float max, float center)
{
	if (value < min)
		value = min;
	if (value > max)
		value = max;

	if (value >= center)
		return (value - center) / (max - center);
	else
		return (value - center) / (center - min);
}

@implementation OHWiiGameController
@synthesize profile = _profile;

+ (void)initialize
{
	if (self != [OHWiiGameController class])
		return;

	if (WPAD_Init() != WPAD_ERR_NONE)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

+ (OFArray OF_GENERIC(OHGameController *) *)controllers
{
	OFMutableArray *controllers = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();

	for (int32_t i = 0; i < WPAD_MAX_WIIMOTES; i++) {
		uint32_t type;

		if (WPAD_Probe(i, &type) == WPAD_ERR_NONE &&
		    (type == WPAD_EXP_NONE || type == WPAD_EXP_NUNCHUK ||
		    type == WPAD_EXP_CLASSIC))
			[controllers addObject: [[[OHWiiGameController alloc]
			    oh_initWithIndex: i
					type: type] autorelease]];
	}

	[controllers makeImmutable];

	objc_autoreleasePoolPop(pool);

	return controllers;
}

- (instancetype)oh_init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)oh_initWithIndex: (int32_t)index type: (uint32_t)type
{
	self = [super oh_init];

	@try {
		_index = index;
		_type = type;

		if (type == WPAD_EXP_CLASSIC)
			_profile = [[OHWiiClassicController alloc] oh_init];
		else if (type == WPAD_EXP_NUNCHUK)
			_profile = [[OHWiimoteWithNunchuk alloc] oh_init];
		else
			_profile = [[OHWiimote alloc] oh_init];

		[self updateState];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_profile release];

	[super dealloc];
}

- (void)updateState
{
	OFDictionary *buttons = _profile.buttons;
	OFDictionary *directionalPads = _profile.directionalPads;
	WPADData *data;

	if (WPAD_ReadPending(_index, NULL) < WPAD_ERR_NONE)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: sizeof(WPADData)
				  errNo: 0];

	data = WPAD_Data(_index);

	if (_type == WPAD_EXP_NONE || _type == WPAD_EXP_NUNCHUK) {
		OHGameControllerDirectionalPad *dPad =
		    [directionalPads objectForKey: @"D-Pad"];

		[[buttons objectForKey: @"A"]
		    setValue: !!(data->btns_h & WPAD_BUTTON_A)];
		[[buttons objectForKey: @"B"]
		    setValue: !!(data->btns_h & WPAD_BUTTON_B)];
		[[buttons objectForKey: @"1"]
		    setValue: !!(data->btns_h & WPAD_BUTTON_1)];
		[[buttons objectForKey: @"2"]
		    setValue: !!(data->btns_h & WPAD_BUTTON_2)];
		[[buttons objectForKey: @"+"]
		    setValue: !!(data->btns_h & WPAD_BUTTON_PLUS)];
		[[buttons objectForKey: @"-"]
		    setValue: !!(data->btns_h & WPAD_BUTTON_MINUS)];
		[[buttons objectForKey: @"Home"]
		    setValue: !!(data->btns_h & WPAD_BUTTON_HOME)];

		[dPad.up setValue: !!(data->btns_h & WPAD_BUTTON_UP)];
		[dPad.down setValue: !!(data->btns_h & WPAD_BUTTON_DOWN)];
		[dPad.left setValue: !!(data->btns_h & WPAD_BUTTON_LEFT)];
		[dPad.right setValue: !!(data->btns_h & WPAD_BUTTON_RIGHT)];
	}

	if (_type == WPAD_EXP_NUNCHUK) {
		joystick_t *js = &data->exp.nunchuk.js;
		OHGameControllerDirectionalPad *directionalPad;

		[[buttons objectForKey: @"C"]
		    setValue: !!(data->btns_h & WPAD_NUNCHUK_BUTTON_C)];
		[[buttons objectForKey: @"Z"]
		    setValue: !!(data->btns_h & WPAD_NUNCHUK_BUTTON_Z)];

		directionalPad =
		    [directionalPads objectForKey: @"Analog Stick"];
		directionalPad.xAxis.value =
		    scale(js->pos.x, js->min.x, js->max.x, js->center.x);
		directionalPad.yAxis.value =
		    -scale(js->pos.y, js->min.y, js->max.y, js->center.y);
	}

	if (_type == WPAD_EXP_CLASSIC) {
		joystick_t *ljs = &data->exp.classic.ljs;
		joystick_t *rjs = &data->exp.classic.rjs;
		OHGameControllerDirectionalPad *directionalPad;

		[[buttons objectForKey: @"X"]
		    setValue: !!(data->btns_h & WPAD_CLASSIC_BUTTON_X)];
		[[buttons objectForKey: @"B"]
		    setValue: !!(data->btns_h & WPAD_CLASSIC_BUTTON_B)];
		[[buttons objectForKey: @"Y"]
		    setValue: !!(data->btns_h & WPAD_CLASSIC_BUTTON_Y)];
		[[buttons objectForKey: @"A"]
		    setValue: !!(data->btns_h & WPAD_CLASSIC_BUTTON_A)];
		[[buttons objectForKey: @"ZL"]
		    setValue: !!(data->btns_h & WPAD_CLASSIC_BUTTON_ZL)];
		[[buttons objectForKey: @"ZR"]
		    setValue: !!(data->btns_h & WPAD_CLASSIC_BUTTON_ZR)];
		[[buttons objectForKey: @"+"]
		    setValue: !!(data->btns_h & WPAD_CLASSIC_BUTTON_PLUS)];
		[[buttons objectForKey: @"-"]
		    setValue: !!(data->btns_h & WPAD_CLASSIC_BUTTON_MINUS)];
		[[buttons objectForKey: @"Home"]
		    setValue: !!(data->btns_h & WPAD_CLASSIC_BUTTON_HOME)];

		directionalPad =
		    [directionalPads objectForKey: @"Left Thumbstick"];
		directionalPad.xAxis.value =
		    scale(ljs->pos.x, ljs->min.x, ljs->max.x, ljs->center.x);
		directionalPad.yAxis.value =
		    -scale(ljs->pos.y, ljs->min.y, ljs->max.y, ljs->center.y);

		directionalPad =
		    [directionalPads objectForKey: @"Right Thumbstick"];
		directionalPad.xAxis.value =
		    scale(rjs->pos.x, rjs->min.x, rjs->max.x, rjs->center.x);
		directionalPad.yAxis.value =
		    -scale(rjs->pos.y, rjs->min.y, rjs->max.y, rjs->center.y);

		[[buttons objectForKey: @"L"]
		    setValue: data->exp.classic.l_shoulder];
		[[buttons objectForKey: @"R"]
		    setValue: data->exp.classic.r_shoulder];

		directionalPad = [directionalPads objectForKey: @"D-Pad"];
		[directionalPad.up
		    setValue: !!(data->btns_h & WPAD_CLASSIC_BUTTON_UP)];
		[directionalPad.down
		    setValue: !!(data->btns_h & WPAD_CLASSIC_BUTTON_DOWN)];
		[directionalPad.left
		    setValue: !!(data->btns_h & WPAD_CLASSIC_BUTTON_LEFT)];
		[directionalPad.right
		    setValue:  !!(data->btns_h & WPAD_CLASSIC_BUTTON_RIGHT)];
	}
}

- (OFString *)name
{
	if (_type == WPAD_EXP_NUNCHUK)
		return @"Wiimote with Nunchuk";
	else if (_type == WPAD_EXP_CLASSIC)
		return @"Wiimote with Classic Controller";
	else
		return @"Wiimote";
}

- (id <OHGamepad>)gamepad
{
	if (_type == WPAD_EXP_CLASSIC)
		return (id <OHGamepad>)_profile;

	return nil;
}

- (id <OHExtendedGamepad>)extendedGamepad
{
	if (_type == WPAD_EXP_CLASSIC)
		return (id <OHExtendedGamepad>)_profile;

	return nil;
}
@end
