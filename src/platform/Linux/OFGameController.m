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

#import "OFGameController.h"
#import "OFArray.h"
#import "OFFileManager.h"
#import "OFLocale.h"
#import "OFSet.h"

#include <sys/ioctl.h>
#include <linux/input.h>

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"

static const uint16_t vendorIDMicrosoft = 0x045E;
static const uint16_t vendorIDNintendo = 0x057E;

static const uint16_t productIDXbox360Controller = 0x028E;
static const uint16_t productIDN64Controller = 0x2019;

@interface OFGameController ()
- (instancetype)of_initWithPath: (OFString *)path OF_METHOD_FAMILY(init);
- (void)of_processEvents;
@end

static const uint16_t buttons[] = {
	BTN_A, BTN_B, BTN_C, BTN_X, BTN_Y, BTN_Z, BTN_TL, BTN_TR, BTN_TL2,
	BTN_TR2, BTN_SELECT, BTN_START, BTN_MODE, BTN_THUMBL, BTN_THUMBR,
	BTN_DPAD_UP, BTN_DPAD_DOWN, BTN_DPAD_LEFT, BTN_DPAD_RIGHT
};

static OFString *
buttonToName(uint16_t button, uint16_t vendorID, uint16_t productID)
{
	if (vendorID == vendorIDMicrosoft &&
	    productID == productIDXbox360Controller) {
		switch (button) {
		case BTN_C:
		case BTN_Z:
			return nil;
		}
	} else if (vendorID == vendorIDNintendo &&
	    productID == productIDN64Controller) {
		switch (button) {
		case BTN_TL2:
			return OFGameControllerButtonZ;
		case BTN_Y:
			return OFGameControllerButtonCPadLeft;
		case BTN_C:
			return OFGameControllerButtonCPadRight;
		case BTN_SELECT:
			return OFGameControllerButtonCPadUp;
		case BTN_X:
			return OFGameControllerButtonCPadDown;
		case BTN_MODE:
			return OFGameControllerButtonHome;
		case BTN_Z:
			return OFGameControllerButtonCapture;
		case BTN_THUMBL:
		case BTN_THUMBR:
			return nil;
		}
	}

	switch (button) {
	case BTN_A:
		return OFGameControllerButtonA;
	case BTN_B:
		return OFGameControllerButtonB;
	case BTN_C:
		return OFGameControllerButtonC;
	case BTN_X:
		return OFGameControllerButtonX;
	case BTN_Y:
		return OFGameControllerButtonY;
	case BTN_Z:
		return OFGameControllerButtonZ;
	case BTN_TL:
		return OFGameControllerButtonL;
	case BTN_TR:
		return OFGameControllerButtonR;
	case BTN_TL2:
		return OFGameControllerButtonZL;
	case BTN_TR2:
		return OFGameControllerButtonZR;
	case BTN_SELECT:
		return OFGameControllerButtonSelect;
	case BTN_START:
		return OFGameControllerButtonStart;
	case BTN_MODE:
		return OFGameControllerButtonHome;
	case BTN_THUMBL:
		return OFGameControllerButtonLeftStick;
	case BTN_THUMBR:
		return OFGameControllerButtonRightStick;
	case BTN_DPAD_UP:
		return OFGameControllerButtonDPadUp;
	case BTN_DPAD_DOWN:
		return OFGameControllerButtonDPadDown;
	case BTN_DPAD_LEFT:
		return OFGameControllerButtonDPadLeft;
	case BTN_DPAD_RIGHT:
		return OFGameControllerButtonDPadRight;
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

@implementation OFGameController
@synthesize name = _name, buttons = _buttons;
@synthesize hasLeftAnalogStick = _hasLeftAnalogStick;
@synthesize hasRightAnalogStick = _hasRightAnalogStick;

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
			controller = [[[OFGameController alloc]
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

		if (!OFBitSetIsSet(keyBits, BTN_GAMEPAD))
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
			OFString *buttonName =
			    buttonToName(buttons[i], _vendorID, _productID);

			if (buttonName != nil)
				[_buttons addObject: buttonName];
		}

		_pressedButtons = [[OFMutableSet alloc] init];

		if (OFBitSetIsSet(evBits, EV_ABS)) {
			if (ioctl(_fd, EVIOCGBIT(EV_ABS, sizeof(absBits)),
			    absBits) == -1)
				@throw [OFInitializationFailedException
				    exception];

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

			if (OFBitSetIsSet(absBits, ABS_RX) &&
			    OFBitSetIsSet(absBits, ABS_RY)) {
				struct input_absinfo infoX, infoY;

				_hasRightAnalogStick = true;

				if (ioctl(_fd, EVIOCGABS(ABS_RX), &infoX) == -1)
					@throw [OFInitializationFailedException
					    exception];

				if (ioctl(_fd, EVIOCGABS(ABS_RY), &infoY) == -1)
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
				    OFGameControllerButtonDPadLeft];
				[_buttons addObject:
				    OFGameControllerButtonDPadRight];
				[_buttons addObject:
				    OFGameControllerButtonDPadUp];
				[_buttons addObject:
				    OFGameControllerButtonDPadDown];
			}

			if (OFBitSetIsSet(absBits, ABS_Z))
				[_buttons addObject: OFGameControllerButtonZL];
			if (OFBitSetIsSet(absBits, ABS_RZ))
				[_buttons addObject: OFGameControllerButtonZR];
		}

		[_buttons makeImmutable];
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

- (void)of_processEvents
{
	struct input_event event;

	for (;;) {
		OFString *name;

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
			if ((name = buttonToName(event.code, _vendorID,
			    _productID)) != nil) {
				if (event.value)
					[_pressedButtons addObject: name];
				else
					[_pressedButtons removeObject: name];
			}
			break;
		case EV_ABS:
			switch (event.code) {
			case ABS_X:
				_leftAnalogStickPosition.x = scale(event.value,
				    _leftAnalogStickMinX, _leftAnalogStickMaxX);
				break;
			case ABS_Y:
				_leftAnalogStickPosition.y = scale(event.value,
				    _leftAnalogStickMinY, _leftAnalogStickMaxY);
				break;
			case ABS_RX:
				_rightAnalogStickPosition.x = scale(event.value,
				    _rightAnalogStickMinX,
				    _rightAnalogStickMaxX);
				break;
			case ABS_RY:
				_rightAnalogStickPosition.y = scale(event.value,
				    _rightAnalogStickMinY,
				    _rightAnalogStickMaxY);
				break;
			case ABS_HAT0X:
				if (event.value < 0) {
					[_pressedButtons addObject:
					    OFGameControllerButtonDPadLeft];
					[_pressedButtons removeObject:
					    OFGameControllerButtonDPadRight];
				} else if (event.value > 0) {
					[_pressedButtons addObject:
					    OFGameControllerButtonDPadRight];
					[_pressedButtons removeObject:
					    OFGameControllerButtonDPadLeft];
				} else {
					[_pressedButtons removeObject:
					    OFGameControllerButtonDPadLeft];
					[_pressedButtons removeObject:
					    OFGameControllerButtonDPadRight];
				}
				break;
			case ABS_HAT0Y:
				if (event.value < 0) {
					[_pressedButtons addObject:
					    OFGameControllerButtonDPadUp];
					[_pressedButtons removeObject:
					    OFGameControllerButtonDPadDown];
				} else if (event.value > 0) {
					[_pressedButtons addObject:
					    OFGameControllerButtonDPadDown];
					[_pressedButtons removeObject:
					    OFGameControllerButtonDPadUp];
				} else {
					[_pressedButtons removeObject:
					    OFGameControllerButtonDPadUp];
					[_pressedButtons removeObject:
					    OFGameControllerButtonDPadDown];
				}
				break;
			case ABS_Z:
				if (event.value > 0)
					[_pressedButtons addObject:
					    OFGameControllerButtonZL];
				else
					[_pressedButtons removeObject:
					    OFGameControllerButtonZL];
				break;
			case ABS_RZ:
				if (event.value > 0)
					[_pressedButtons addObject:
					    OFGameControllerButtonZR];
				else
					[_pressedButtons removeObject:
					    OFGameControllerButtonZR];
				break;
			}

			break;
		}
	}
}

- (OFComparisonResult)compare: (OFGameController *)otherController
{
	unsigned long long selfIndex, otherIndex;

	if (![otherController isKindOfClass: [OFGameController class]])
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
	[self of_processEvents];
	return [[_pressedButtons copy] autorelease];
}

- (OFPoint)leftAnalogStickPosition
{
	[self of_processEvents];
	return _leftAnalogStickPosition;
}

- (OFPoint)rightAnalogStickPosition
{
	[self of_processEvents];
	return _rightAnalogStickPosition;
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@>", self.class, self.name];
}
@end
