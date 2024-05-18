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

#include <errno.h>
#include <fcntl.h>
#include <unistd.h>

#import "OFEvdevGameController.h"
#import "OFArray.h"
#import "OFFileManager.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFSet.h"

#include <sys/ioctl.h>
#include <linux/input.h>

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"

/*
 * Controllers with tested correct mapping:
 *
 *   Microsoft X-Box 360 pad [045E:028E]
 *   Joy-Con (L) [057E:2006]
 *   Joy-Con (R) [057E:2007]
 *   N64 Controller [057E:2019]
 *   Sony Interactive Entertainment DualSense Wireless Controller [054C:0CE6]
 *   8BitDo Pro 2 Wired Controller [2DC8:3106]
 *   Stadia2SZY-0d6c [18D1:9400]
 *   Wireless Controller [054C:09CC]
 */

static const uint16_t vendorIDMicrosoft = 0x045E;
static const uint16_t vendorIDNintendo = 0x057E;
static const uint16_t vendorIDSony = 0x054C;
static const uint16_t vendorIDGoogle = 0x18D1;

/* Microsoft controllers */
static const uint16_t productIDXbox360 = 0x028E;

/* Nintendo controllers */
static const uint16_t productIDLeftJoycon = 0x2006;
static const uint16_t productIDRightJoycon = 0x2007;
static const uint16_t productIDN64Controller = 0x2019;

/* Sony controllers */
static const uint16_t productIDDualSense = 0x0CE6;
static const uint16_t productIDDualShock4 = 0x09CC;

/* Google controllers */
static const uint16_t productIDStadia = 0x9400;

static const uint16_t buttons[] = {
	BTN_A, BTN_B, BTN_C, BTN_X, BTN_Y, BTN_Z, BTN_TL, BTN_TR, BTN_TL2,
	BTN_TR2, BTN_SELECT, BTN_START, BTN_MODE, BTN_THUMBL, BTN_THUMBR,
	BTN_DPAD_UP, BTN_DPAD_DOWN, BTN_DPAD_LEFT, BTN_DPAD_RIGHT,
	BTN_TRIGGER_HAPPY1, BTN_TRIGGER_HAPPY2
};

static OFGameControllerButton
buttonToName(uint16_t button, uint16_t vendorID, uint16_t productID)
{
	if (vendorID == vendorIDNintendo &&
	    productID == productIDLeftJoycon) {
		switch (button) {
		case BTN_SELECT:
			return OFGameControllerMinusButton;
		case BTN_Z:
			return OFGameControllerCaptureButton;
		case BTN_TR:
			return OFGameControllerSLButton;
		case BTN_TR2:
			return OFGameControllerSRButton;
		}
	} else if (vendorID == vendorIDNintendo &&
	    productID == productIDRightJoycon) {
		switch (button) {
		case BTN_NORTH:
			return OFGameControllerNorthButton;
		case BTN_WEST:
			return OFGameControllerWestButton;
		case BTN_START:
			return OFGameControllerPlusButton;
		case BTN_TL:
			return OFGameControllerSLButton;
		case BTN_TL2:
			return OFGameControllerSRButton;
		}
	} else if (vendorID == vendorIDNintendo &&
	    productID == productIDN64Controller) {
		switch (button) {
		case BTN_A:
			return OFGameControllerAButton;
		case BTN_B:
			return OFGameControllerBButton;
		case BTN_SELECT:
			return OFGameControllerCPadUpButton;
		case BTN_X:
			return OFGameControllerCPadDownButton;
		case BTN_Y:
			return OFGameControllerCPadLeftButton;
		case BTN_C:
			return OFGameControllerCPadRightButton;
		case BTN_Z:
			return OFGameControllerCaptureButton;
		}
	} else if (vendorID == vendorIDSony &&
	    (productID == productIDDualSense ||
	    productID == productIDDualShock4)) {
		switch (button) {
		case BTN_NORTH:
			return OFGameControllerNorthButton;
		case BTN_WEST:
			return OFGameControllerWestButton;
		}
	} else if (vendorID == vendorIDGoogle && productID == productIDStadia) {
		switch (button) {
		case BTN_TRIGGER_HAPPY1:
			return OFGameControllerAssistantButton;
		case BTN_TRIGGER_HAPPY2:
			return OFGameControllerCaptureButton;
		}
	}

	switch (button) {
	case BTN_Y:
		return OFGameControllerNorthButton;
	case BTN_A:
		return OFGameControllerSouthButton;
	case BTN_X:
		return OFGameControllerWestButton;
	case BTN_B:
		return OFGameControllerEastButton;
	case BTN_TL2:
		return OFGameControllerLeftTriggerButton;
	case BTN_TR2:
		return OFGameControllerRightTriggerButton;
	case BTN_TL:
		return OFGameControllerLeftShoulderButton;
	case BTN_TR:
		return OFGameControllerRightShoulderButton;
	case BTN_THUMBL:
		return OFGameControllerLeftStickButton;
	case BTN_THUMBR:
		return OFGameControllerRightStickButton;
	case BTN_DPAD_UP:
		return OFGameControllerDPadUpButton;
	case BTN_DPAD_DOWN:
		return OFGameControllerDPadDownButton;
	case BTN_DPAD_LEFT:
		return OFGameControllerDPadLeftButton;
	case BTN_DPAD_RIGHT:
		return OFGameControllerDPadRightButton;
	case BTN_START:
		return OFGameControllerStartButton;
	case BTN_SELECT:
		return OFGameControllerSelectButton;
	case BTN_MODE:
		return OFGameControllerHomeButton;
	case BTN_C:
		return OFGameControllerCButton;
	case BTN_Z:
		return OFGameControllerZButton;
	}

	return nil;
}

static float
scale(float value, float min, float max)
{
	if (value < min)
		value = min;
	if (value > max)
		value = max;

	return ((value - min) / (max - min) * 2) - 1;
}

@implementation OFEvdevGameController
@synthesize name = _name, buttons = _buttons;
@synthesize hasLeftAnalogStick = _hasLeftAnalogStick;
@synthesize hasRightAnalogStick = _hasRightAnalogStick;
@synthesize leftAnalogStickPosition = _leftAnalogStickPosition;
@synthesize rightAnalogStickPosition = _rightAnalogStickPosition;

+ (OFArray OF_GENERIC(OFGameController *) *)controllers
{
	OFMutableArray *controllers = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();

	for (OFString *device in [[OFFileManager defaultManager]
	    contentsOfDirectoryAtPath: @"/dev/input"]) {
		OFString *path;
		OFGameController *controller;

		if (![device hasPrefix: @"event"])
			continue;

		path = [@"/dev/input" stringByAppendingPathComponent: device];

		@try {
			controller = [[[OFEvdevGameController alloc]
			    of_initWithPath: path] autorelease];
		} @catch (OFOpenItemFailedException *e) {
			if (e.errNo == EACCES)
				continue;

			@throw e;
		} @catch (OFInvalidArgumentException *e) {
			/* Not a game controller. */
			continue;
		}

		[controllers addObject: controller];
	}

	[controllers sort];
	[controllers makeImmutable];

	objc_autoreleasePoolPop(pool);

	return controllers;
}

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)of_initWithPath: (OFString *)path
{
	self = [super init];

	@try {
		OFStringEncoding encoding = [OFLocale encoding];
		unsigned long evBits[OFRoundUpToPowerOf2(OF_ULONG_BIT,
		    EV_MAX) / OF_ULONG_BIT] = { 0 };
		unsigned long keyBits[OFRoundUpToPowerOf2(OF_ULONG_BIT,
		    KEY_MAX) / OF_ULONG_BIT] = { 0 };
		unsigned long absBits[OFRoundUpToPowerOf2(OF_ULONG_BIT,
		    ABS_MAX) / OF_ULONG_BIT] = { 0 };
		struct input_id inputID;
		char name[128];

		_path = [path copy];

		if ((_fd = open([_path cStringWithEncoding: encoding],
		    O_RDONLY | O_NONBLOCK)) == -1)
			@throw [OFOpenItemFailedException
			    exceptionWithPath: _path
					 mode: @"r"
					errNo: errno];

		if (ioctl(_fd, EVIOCGBIT(0, sizeof(evBits)), evBits) == -1)
			@throw [OFInitializationFailedException exception];

		if (!OFBitSetIsSet(evBits, EV_KEY))
			@throw [OFInvalidArgumentException exception];

		if (ioctl(_fd, EVIOCGBIT(EV_KEY, sizeof(keyBits)), keyBits) ==
		    -1)
			@throw [OFInitializationFailedException exception];

		if (!OFBitSetIsSet(keyBits, BTN_GAMEPAD) &&
		    !OFBitSetIsSet(keyBits, BTN_DPAD_UP))
			@throw [OFInvalidArgumentException exception];

		if (ioctl(_fd, EVIOCGID, &inputID) == -1)
			@throw [OFInvalidArgumentException exception];

		_vendorID = inputID.vendor;
		_productID = inputID.product;

		if (ioctl(_fd, EVIOCGNAME(sizeof(name)), name) == -1)
			@throw [OFInitializationFailedException exception];

		_name = [[OFString alloc] initWithCString: name
						 encoding: encoding];

		_buttons = [[OFMutableSet alloc] init];
		for (size_t i = 0; i < sizeof(buttons) / sizeof(*buttons);
		    i++) {
			if (OFBitSetIsSet(keyBits, buttons[i])) {
				OFGameControllerButton button = buttonToName(
				    buttons[i], _vendorID, _productID);

				if (button != nil)
					[_buttons addObject: button];
			}
		}

		_pressedButtons = [[OFMutableSet alloc] init];

		if (OFBitSetIsSet(evBits, EV_ABS)) {
			if (ioctl(_fd, EVIOCGBIT(EV_ABS, sizeof(absBits)),
			    absBits) == -1)
				@throw [OFInitializationFailedException
				    exception];

			if (_vendorID == vendorIDGoogle &&
			    _productID == productIDStadia) {
				/*
				 * It's unclear how this can be screwed up
				 * *this* bad.
				 */
				_rightAnalogStickXBit = ABS_Z;
				_rightAnalogStickYBit = ABS_RZ;
				_leftTriggerPressureBit = ABS_BRAKE;
				_rightTriggerPressureBit = ABS_GAS;
			} else {
				_rightAnalogStickXBit = ABS_RX;
				_rightAnalogStickYBit = ABS_RY;
				_leftTriggerPressureBit = ABS_Z;
				_rightTriggerPressureBit = ABS_RZ;
			}

			if (OFBitSetIsSet(absBits, ABS_X) &&
			    OFBitSetIsSet(absBits, ABS_Y)) {
				struct input_absinfo infoX, infoY;

				_hasLeftAnalogStick = true;

				if (ioctl(_fd, EVIOCGABS(ABS_X), &infoX) == -1)
					@throw [OFInitializationFailedException
					    exception];

				if (ioctl(_fd, EVIOCGABS(ABS_Y), &infoY) == -1)
					@throw [OFInitializationFailedException
					    exception];

				_leftAnalogStickMinX = infoX.minimum;
				_leftAnalogStickMaxX = infoX.maximum;
				_leftAnalogStickMinY = infoY.minimum;
				_leftAnalogStickMaxY = infoY.maximum;
			}

			if (OFBitSetIsSet(absBits, _rightAnalogStickXBit) &&
			    OFBitSetIsSet(absBits, _rightAnalogStickYBit)) {
				struct input_absinfo infoX, infoY;

				_hasRightAnalogStick = true;

				if (ioctl(_fd, EVIOCGABS(_rightAnalogStickXBit),
				    &infoX) == -1)
					@throw [OFInitializationFailedException
					    exception];

				if (ioctl(_fd, EVIOCGABS(_rightAnalogStickYBit),
				    &infoY) == -1)
					@throw [OFInitializationFailedException
					    exception];

				_rightAnalogStickMinX = infoX.minimum;
				_rightAnalogStickMaxX = infoX.maximum;
				_rightAnalogStickMinY = infoY.minimum;
				_rightAnalogStickMaxY = infoY.maximum;
			}

			if (OFBitSetIsSet(absBits, ABS_HAT0X) &&
			    OFBitSetIsSet(absBits, ABS_HAT0Y)) {
				[_buttons addObject:
				    OFGameControllerDPadLeftButton];
				[_buttons addObject:
				    OFGameControllerDPadRightButton];
				[_buttons addObject:
				    OFGameControllerDPadUpButton];
				[_buttons addObject:
				    OFGameControllerDPadDownButton];
			}

			if (OFBitSetIsSet(absBits, _leftTriggerPressureBit)) {
				struct input_absinfo info;

				_hasLeftTriggerPressure = true;

				if (ioctl(_fd, EVIOCGABS(
				    _leftTriggerPressureBit), &info) == -1)
					@throw [OFInitializationFailedException
					    exception];

				_leftTriggerMinPressure = info.minimum;
				_leftTriggerMaxPressure = info.maximum;

				[_buttons addObject:
				    OFGameControllerLeftTriggerButton];
			}

			if (OFBitSetIsSet(absBits, _rightTriggerPressureBit)) {
				struct input_absinfo info;

				_hasRightTriggerPressure = true;

				if (ioctl(_fd, EVIOCGABS(
				    _rightTriggerPressureBit), &info) == -1)
					@throw [OFInitializationFailedException
					    exception];

				_rightTriggerMinPressure = info.minimum;
				_rightTriggerMaxPressure = info.maximum;

				[_buttons addObject:
				    OFGameControllerRightTriggerButton];
			}
		}

		[_buttons makeImmutable];

		[self retrieveState];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_path release];

	if (_fd != -1)
		close(_fd);

	[_name release];
	[_buttons release];
	[_pressedButtons release];

	[super dealloc];
}

- (OFNumber *)vendorID
{
	return [OFNumber numberWithUnsignedShort: _vendorID];
}

- (OFNumber *)productID
{
	return [OFNumber numberWithUnsignedShort: _productID];
}

- (void)retrieveState
{
	struct input_event event;

	for (;;) {
		OFGameControllerButton button;

		errno = 0;

		if (read(_fd, &event, sizeof(event)) < (int)sizeof(event)) {
			if (errno == EWOULDBLOCK)
				return;

			@throw [OFReadFailedException
			    exceptionWithObject: self
				requestedLength: sizeof(event)
					  errNo: errno];
		}

		switch (event.type) {
		case EV_KEY:
			if ((button = buttonToName(event.code, _vendorID,
			    _productID)) != nil) {
				if (event.value)
					[_pressedButtons addObject: button];
				else
					[_pressedButtons removeObject: button];
			}
			break;
		case EV_ABS:
			if (event.code == ABS_X)
				_leftAnalogStickPosition.x = scale(event.value,
				    _leftAnalogStickMinX, _leftAnalogStickMaxX);
			else if (event.code == ABS_Y)
				_leftAnalogStickPosition.y = scale(event.value,
				    _leftAnalogStickMinY, _leftAnalogStickMaxY);
			else if (event.code == _rightAnalogStickXBit)
				_rightAnalogStickPosition.x = scale(event.value,
				    _rightAnalogStickMinX,
				    _rightAnalogStickMaxX);
			else if (event.code == _rightAnalogStickYBit)
				_rightAnalogStickPosition.y = scale(event.value,
				    _rightAnalogStickMinY,
				    _rightAnalogStickMaxY);
			else if (event.code == ABS_HAT0X) {
				if (event.value < 0) {
					[_pressedButtons addObject:
					    OFGameControllerDPadLeftButton];
					[_pressedButtons removeObject:
					    OFGameControllerDPadRightButton];
				} else if (event.value > 0) {
					[_pressedButtons addObject:
					    OFGameControllerDPadRightButton];
					[_pressedButtons removeObject:
					    OFGameControllerDPadLeftButton];
				} else {
					[_pressedButtons removeObject:
					    OFGameControllerDPadLeftButton];
					[_pressedButtons removeObject:
					    OFGameControllerDPadRightButton];
				}
			} else if (event.code == ABS_HAT0Y) {
				if (event.value < 0) {
					[_pressedButtons addObject:
					    OFGameControllerDPadUpButton];
					[_pressedButtons removeObject:
					    OFGameControllerDPadDownButton];
				} else if (event.value > 0) {
					[_pressedButtons addObject:
					    OFGameControllerDPadDownButton];
					[_pressedButtons removeObject:
					    OFGameControllerDPadUpButton];
				} else {
					[_pressedButtons removeObject:
					    OFGameControllerDPadUpButton];
					[_pressedButtons removeObject:
					    OFGameControllerDPadDownButton];
				}
			} else if (event.code == _leftTriggerPressureBit) {
				_leftTriggerPressure = scale(event.value,
				    _leftTriggerMinPressure,
				    _leftTriggerMaxPressure);

				if (_leftTriggerPressure > 0)
					[_pressedButtons addObject:
					    OFGameControllerLeftTriggerButton];
				else
					[_pressedButtons removeObject:
					    OFGameControllerLeftTriggerButton];
			} else if (event.code == _rightTriggerPressureBit) {
				_rightTriggerPressure = scale(event.value,
				    _rightTriggerMinPressure,
				    _rightTriggerMaxPressure);

				if (_rightTriggerPressure > 0)
					[_pressedButtons addObject:
					    OFGameControllerRightTriggerButton];
				else
					[_pressedButtons removeObject:
					    OFGameControllerRightTriggerButton];
			}
			break;
		}
	}
}

- (OFComparisonResult)compare: (OFEvdevGameController *)otherController
{
	unsigned long long selfIndex, otherIndex;

	if (![otherController isKindOfClass: [OFEvdevGameController class]])
		@throw [OFInvalidArgumentException exception];

	selfIndex = [_path substringFromIndex: 16].unsignedLongLongValue;
	otherIndex = [otherController->_path substringFromIndex: 16]
	    .unsignedLongLongValue;

	if (selfIndex > otherIndex)
		return OFOrderedDescending;
	if (selfIndex < otherIndex)
		return OFOrderedAscending;

	return OFOrderedSame;
}

- (OFSet *)pressedButtons
{
	return [[_pressedButtons copy] autorelease];
}

- (float)pressureForButton: (OFGameControllerButton)button
{
	if (button == OFGameControllerLeftTriggerButton &&
	    _hasLeftTriggerPressure)
		return _leftTriggerPressure;
	if (button == OFGameControllerRightTriggerButton &&
	    _hasRightTriggerPressure)
		return _rightTriggerPressure;

	return [super pressureForButton: button];
}
@end
