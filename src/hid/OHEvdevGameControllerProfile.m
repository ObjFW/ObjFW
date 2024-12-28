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

#import "OHEvdevGameControllerProfile.h"
#import "OFDictionary.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"

#include <linux/input.h>

#import "evdev_compat.h"

static OFString *
buttonToName(uint16_t button, uint16_t vendorID, uint16_t productID)
{
	switch (button) {
	case BTN_A:
		return @"A";
	case BTN_B:
		return @"B";
	case BTN_C:
		return @"C";
	case BTN_X:
		return @"X";
	case BTN_Y:
		return @"Y";
	case BTN_Z:
		return @"Z";
	case BTN_TL:
		return @"LB";
	case BTN_TR:
		return @"RB";
	case BTN_TL2:
		return @"LT";
	case BTN_TR2:
		return @"RT";
	case BTN_SELECT:
		return @"Back";
	case BTN_START:
		return @"Start";
	case BTN_MODE:
		return @"Guide";
	case BTN_THUMBL:
		return @"LSB";
	case BTN_THUMBR:
		return @"RSB";
	case BTN_DPAD_UP:
		return @"D-Pad Up";
	case BTN_DPAD_DOWN:
		return @"D-Pad Down";
	case BTN_DPAD_LEFT:
		return @"D-Pad Left";
	case BTN_DPAD_RIGHT:
		return @"D-Pad Right";
	case BTN_TRIGGER_HAPPY1:
		return @"Trigger Happy 1";
	case BTN_TRIGGER_HAPPY2:
		return @"Trigger Happy 2";
	case BTN_TRIGGER_HAPPY3:
		return @"Trigger Happy 3";
	case BTN_TRIGGER_HAPPY4:
		return @"Trigger Happy 4";
	case BTN_TRIGGER_HAPPY5:
		return @"Trigger Happy 5";
	case BTN_TRIGGER_HAPPY6:
		return @"Trigger Happy 6";
	case BTN_TRIGGER_HAPPY7:
		return @"Trigger Happy 7";
	case BTN_TRIGGER_HAPPY8:
		return @"Trigger Happy 8";
	case BTN_TRIGGER_HAPPY9:
		return @"Trigger Happy 9";
	case BTN_TRIGGER_HAPPY10:
		return @"Trigger Happy 10";
	case BTN_TRIGGER_HAPPY11:
		return @"Trigger Happy 11";
	case BTN_TRIGGER_HAPPY12:
		return @"Trigger Happy 12";
	case BTN_TRIGGER_HAPPY13:
		return @"Trigger Happy 13";
	case BTN_TRIGGER_HAPPY14:
		return @"Trigger Happy 14";
	case BTN_TRIGGER_HAPPY15:
		return @"Trigger Happy 15";
	case BTN_TRIGGER_HAPPY16:
		return @"Trigger Happy 16";
	case BTN_TRIGGER_HAPPY17:
		return @"Trigger Happy 17";
	case BTN_TRIGGER_HAPPY18:
		return @"Trigger Happy 18";
	case BTN_TRIGGER_HAPPY19:
		return @"Trigger Happy 19";
	case BTN_TRIGGER_HAPPY20:
		return @"Trigger Happy 20";
	case BTN_TRIGGER_HAPPY21:
		return @"Trigger Happy 21";
	case BTN_TRIGGER_HAPPY22:
		return @"Trigger Happy 22";
	case BTN_TRIGGER_HAPPY23:
		return @"Trigger Happy 23";
	case BTN_TRIGGER_HAPPY24:
		return @"Trigger Happy 24";
	case BTN_TRIGGER_HAPPY25:
		return @"Trigger Happy 25";
	case BTN_TRIGGER_HAPPY26:
		return @"Trigger Happy 26";
	case BTN_TRIGGER_HAPPY27:
		return @"Trigger Happy 27";
	case BTN_TRIGGER_HAPPY28:
		return @"Trigger Happy 28";
	case BTN_TRIGGER_HAPPY29:
		return @"Trigger Happy 29";
	case BTN_TRIGGER_HAPPY30:
		return @"Trigger Happy 30";
	case BTN_TRIGGER_HAPPY31:
		return @"Trigger Happy 31";
	case BTN_TRIGGER_HAPPY32:
		return @"Trigger Happy 32";
	case BTN_TRIGGER_HAPPY33:
		return @"Trigger Happy 33";
	case BTN_TRIGGER_HAPPY34:
		return @"Trigger Happy 34";
	case BTN_TRIGGER_HAPPY35:
		return @"Trigger Happy 35";
	case BTN_TRIGGER_HAPPY36:
		return @"Trigger Happy 36";
	case BTN_TRIGGER_HAPPY37:
		return @"Trigger Happy 37";
	case BTN_TRIGGER_HAPPY38:
		return @"Trigger Happy 38";
	case BTN_TRIGGER_HAPPY39:
		return @"Trigger Happy 39";
	case BTN_TRIGGER_HAPPY40:
		return @"Trigger Happy 40";
	default:
		return nil;
	}
}

static OFString *
axisToName(uint16_t axis)
{
	switch (axis) {
	case ABS_X:
		return @"X";
	case ABS_Y:
		return @"Y";
	case ABS_Z:
		return @"Z";
	case ABS_RX:
		return @"RX";
	case ABS_RY:
		return @"RY";
	case ABS_RZ:
		return @"RZ";
	case ABS_THROTTLE:
		return @"Throttle";
	case ABS_RUDDER:
		return @"Rudder";
	case ABS_WHEEL:
		return @"Wheel";
	case ABS_GAS:
		return @"Gas";
	case ABS_BRAKE:
		return @"Brake";
	case ABS_HAT0X:
		return @"HAT0X";
	case ABS_HAT0Y:
		return @"HAT0Y";
	case ABS_HAT1X:
		return @"HAT1X";
	case ABS_HAT1Y:
		return @"HAT1Y";
	case ABS_HAT2X:
		return @"HAT2X";
	case ABS_HAT2Y:
		return @"HAT2Y";
	case ABS_HAT3X:
		return @"HAT3X";
	case ABS_HAT3Y:
		return @"HAT3Y";
	default:
		return nil;
	}
}

@implementation OHEvdevGameControllerProfile
@synthesize buttons = _buttons, axes = _axes;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)oh_initWithKeyBits: (unsigned long *)keyBits
			    evBits: (unsigned long *)evBits
			   absBits: (unsigned long *)absBits
			  vendorID: (uint16_t)vendorID
			 productID: (uint16_t)productID
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttons, *axes;

		buttons = [OFMutableDictionary dictionary];
		for (size_t i = 0; i < OHNumEvdevButtonIDs; i++) {
			if (OFBitSetIsSet(keyBits, OHEvdevButtonIDs[i])) {
				OFString *buttonName;
				OHGameControllerButton *button;

				buttonName = buttonToName(OHEvdevButtonIDs[i],
				    vendorID, productID);
				if (buttonName == nil)
					continue;

				button = [OHGameControllerButton
				    oh_elementWithName: buttonName
						analog: false];

				[buttons setObject: button forKey: buttonName];
			}
		}
		[buttons makeImmutable];

		axes = [OFMutableDictionary dictionary];
		if (OFBitSetIsSet(evBits, EV_ABS)) {
			for (size_t i = 0; i < OHNumEvdevAxisIDs; i++) {
				if (OFBitSetIsSet(absBits, OHEvdevAxisIDs[i])) {
					OFString *axisName;
					OHGameControllerAxis *axis;

					axisName =
					    axisToName(OHEvdevAxisIDs[i]);
					if (axisName == nil)
						continue;

					axis = [OHGameControllerAxis
					    oh_elementWithName: axisName
							analog: true];

					[axes setObject: axis forKey: axisName];
				}
			}
		}
		[axes makeImmutable];

		_buttons = [buttons copy];
		_axes = [axes copy];
		_vendorID = vendorID;
		_productID = productID;

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
	[_axes release];

	[super dealloc];
}

- (OFDictionary OF_GENERIC(OFString *, OHGameControllerDirectionalPad *) *)
    directionalPads
{
	return [OFDictionary dictionary];
}

- (OHGameControllerButton *)oh_buttonForEvdevButton: (uint16_t)button
{
	OFString *name;

	if ((name = buttonToName(button, _vendorID, _productID)) == nil)
		return nil;

	return [_buttons objectForKey: name];
}

- (OHGameControllerAxis *)oh_axisForEvdevAxis: (uint16_t)axis
{
	OFString *name;

	if ((name = axisToName(axis)) == nil)
		return nil;

	return [_axes objectForKey: name];
}
@end
