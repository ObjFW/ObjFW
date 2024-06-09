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

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFReadFailedException.h"

#define asm __asm__
#include <wiiuse/wpad.h>
#undef asm

@interface OHWiiGameControllerProfile: OFObject <OHGameControllerProfile>
{
	OFDictionary OF_GENERIC(OFString *, OHGameControllerButton *) *_buttons;
	OFDictionary OF_GENERIC(OFString *, OHGameControllerDirectionalPad *)
	    *_directionalPads;
}

- (instancetype)initWithType: (uint32_t)type;
@end

static OFString *const buttonNames[] = {
	@"A", @"B", @"1", @"2", @"+", @"-", @"Home"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);
static OFString *const nunchukButtonNames[] = {
	@"C", @"Z"
};
static const size_t numNunchukButtons =
    sizeof(nunchukButtonNames) / sizeof(*nunchukButtonNames);

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
@synthesize rawProfile = _rawProfile;

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
			    initWithIndex: i
				     type: type] autorelease]];
	}

	[controllers makeImmutable];

	objc_autoreleasePoolPop(pool);

	return controllers;
}

- (instancetype)initWithIndex: (int32_t)index type: (uint32_t)type
{
	self = [super init];

	@try {
		_index = index;
		_type = type;

		if (type == WPAD_EXP_CLASSIC)
			_rawProfile = [[OHWiiClassicController alloc] init];
		else
			_rawProfile = [[OHWiiGameControllerProfile alloc]
			    initWithType: type];

		[self retrieveState];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_rawProfile release];

	[super dealloc];
}

- (void)retrieveState
{
	OFDictionary *buttons = _rawProfile.buttons;
	OFDictionary *directionalPads = _rawProfile.directionalPads;
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
		return (id <OHGamepad>)_rawProfile;

	return nil;
}

- (id <OHExtendedGamepad>)extendedGamepad
{
	if (_type == WPAD_EXP_CLASSIC)
		return (id <OHExtendedGamepad>)_rawProfile;

	return nil;
}
@end

@implementation OHWiiGameControllerProfile
@synthesize buttons = _buttons, directionalPads = _directionalPads;

- (instancetype)initWithType: (uint32_t)type
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttons;
		OFMutableDictionary *directionalPads;
		OHGameControllerDirectionalPad *directionalPad;
		OHGameControllerButton *up, *down, *left, *right;
		OHGameControllerAxis *xAxis, *yAxis;

		if (type != WPAD_EXP_NONE && type != WPAD_EXP_NUNCHUK)
			@throw [OFInvalidArgumentException exception];

		buttons = [OFMutableDictionary
		    dictionaryWithCapacity: numButtons + numNunchukButtons];

		for (size_t i = 0; i < numButtons; i++) {
			OHGameControllerButton *button =
			    [[[OHGameControllerButton alloc]
			    initWithName: buttonNames[i]] autorelease];
			[buttons setObject: button forKey: buttonNames[i]];
		}

		directionalPads = [OFMutableDictionary dictionary];

		up = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Up"] autorelease];
		down = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Down"] autorelease];
		left = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Left"] autorelease];
		right = [[[OHGameControllerButton alloc]
		    initWithName: @"D-Pad Right"] autorelease];
		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"D-Pad"
			      up: up
			    down: down
			    left: left
			   right: right] autorelease];
		[directionalPads setObject: directionalPad forKey: @"D-Pad"];

		if (type == WPAD_EXP_NUNCHUK) {
			for (size_t i = 0; i < numNunchukButtons; i++) {
				OHGameControllerButton *button =
				    [[[OHGameControllerButton alloc]
				    initWithName: nunchukButtonNames[i]]
					autorelease];

				[buttons setObject: button
					    forKey: nunchukButtonNames[i]];
			}

			xAxis = [[[OHGameControllerAxis alloc]
			    initWithName: @"X"] autorelease];
			yAxis = [[[OHGameControllerAxis alloc]
			    initWithName: @"Y"] autorelease];
			directionalPad = [[[OHGameControllerDirectionalPad alloc]
			    initWithName: @"Analog Stick"
				   xAxis: xAxis
				   yAxis: yAxis] autorelease];
			[directionalPads setObject: directionalPad
					    forKey: @"Analog Stick"];
		}

		[buttons makeImmutable];
		[directionalPads makeImmutable];
		_buttons = [buttons retain];
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
@end
