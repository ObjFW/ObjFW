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

#import "OHEvdevGameController.h"

#import "OFArray.h"
#import "OFDictionary.h"
#import "OFFileManager.h"
#import "OFLocale.h"
#import "OFNumber.h"

#import "OHEvdevDualSense.h"
#import "OHEvdevGamepad.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerProfile.h"

#include <sys/ioctl.h>
#include <linux/input.h>

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"

@interface OHEvdevGameControllerAxis: OHGameControllerAxis
{
@public
	int32_t _minValue, _maxValue;
}
@end

@interface OHEvdevGameControllerProfile: OHGameControllerProfile
- (instancetype)oh_initWithButtons: (OFDictionary *)buttons
			      axes: (OFDictionary *)axes OF_METHOD_FAMILY(init);
@end

static const uint16_t buttonIDs[] = {
	BTN_A, BTN_B, BTN_C, BTN_X, BTN_Y, BTN_Z, BTN_TL, BTN_TR, BTN_TL2,
	BTN_TR2, BTN_SELECT, BTN_START, BTN_MODE, BTN_THUMBL, BTN_THUMBR,
	BTN_DPAD_UP, BTN_DPAD_DOWN, BTN_DPAD_LEFT, BTN_DPAD_RIGHT,
	BTN_TRIGGER_HAPPY1, BTN_TRIGGER_HAPPY2, BTN_TRIGGER_HAPPY3,
	BTN_TRIGGER_HAPPY4, BTN_TRIGGER_HAPPY5, BTN_TRIGGER_HAPPY6,
	BTN_TRIGGER_HAPPY7, BTN_TRIGGER_HAPPY8, BTN_TRIGGER_HAPPY9,
	BTN_TRIGGER_HAPPY10, BTN_TRIGGER_HAPPY11, BTN_TRIGGER_HAPPY12,
	BTN_TRIGGER_HAPPY13, BTN_TRIGGER_HAPPY14, BTN_TRIGGER_HAPPY15,
	BTN_TRIGGER_HAPPY16, BTN_TRIGGER_HAPPY17, BTN_TRIGGER_HAPPY18,
	BTN_TRIGGER_HAPPY19, BTN_TRIGGER_HAPPY20, BTN_TRIGGER_HAPPY21,
	BTN_TRIGGER_HAPPY22, BTN_TRIGGER_HAPPY23, BTN_TRIGGER_HAPPY24,
	BTN_TRIGGER_HAPPY25, BTN_TRIGGER_HAPPY26, BTN_TRIGGER_HAPPY27,
	BTN_TRIGGER_HAPPY28, BTN_TRIGGER_HAPPY29, BTN_TRIGGER_HAPPY30,
	BTN_TRIGGER_HAPPY31, BTN_TRIGGER_HAPPY32, BTN_TRIGGER_HAPPY33,
	BTN_TRIGGER_HAPPY34, BTN_TRIGGER_HAPPY35, BTN_TRIGGER_HAPPY36,
	BTN_TRIGGER_HAPPY37, BTN_TRIGGER_HAPPY38, BTN_TRIGGER_HAPPY39,
	BTN_TRIGGER_HAPPY40
};
static const uint16_t axisIDs[] = {
	ABS_X, ABS_Y, ABS_Z, ABS_RX, ABS_RY, ABS_RZ, ABS_THROTTLE, ABS_RUDDER,
	ABS_WHEEL, ABS_GAS, ABS_BRAKE, ABS_HAT0X, ABS_HAT0Y, ABS_HAT1X,
	ABS_HAT1Y, ABS_HAT2X, ABS_HAT2Y, ABS_HAT3X, ABS_HAT3Y
};

static OFString *
buttonToName(uint16_t button, uint16_t vendorID, uint16_t productID)
{
	if (vendorID == OHVendorIDSony && productID == OHProductIDDualSense) {
		switch (button) {
		case BTN_NORTH:
			return @"Triangle";
		case BTN_SOUTH:
			return @"Cross";
		case BTN_WEST:
			return @"Square";
		case BTN_EAST:
			return @"Circle";
		case BTN_TL:
			return @"L1";
		case BTN_TR:
			return @"R1";
		case BTN_TL2:
			return @"L2";
		case BTN_TR2:
			return @"R2";
		case BTN_THUMBL:
			return @"L3";
		case BTN_THUMBR:
			return @"R3";
		case BTN_START:
			return @"Options";
		case BTN_SELECT:
			return @"Create";
		case BTN_MODE:
			return @"PS";
		}
	}

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
		return @"TL";
	case BTN_TR:
		return @"TR";
	case BTN_TL2:
		return @"TL2";
	case BTN_TR2:
		return @"TR2";
	case BTN_SELECT:
		return @"Select";
	case BTN_START:
		return @"Start";
	case BTN_MODE:
		return @"Mode";
	case BTN_THUMBL:
		return @"Thumb L";
	case BTN_THUMBR:
		return @"Thumb R";
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

static float
scale(float value, float min, float max)
{
	if (value < min)
		value = min;
	if (value > max)
		value = max;

	return ((value - min) / (max - min) * 2) - 1;
}

@implementation OHEvdevGameController
@synthesize name = _name, rawProfile = _rawProfile;

+ (OFArray OF_GENERIC(OHGameController *) *)controllers
{
	OFMutableArray *controllers = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();

	for (OFString *device in [[OFFileManager defaultManager]
	    contentsOfDirectoryAtPath: @"/dev/input"]) {
		OFString *path;
		OHGameController *controller;

		if (![device hasPrefix: @"event"])
			continue;

		path = [@"/dev/input" stringByAppendingPathComponent: device];

		@try {
			controller = [[[OHEvdevGameController alloc]
			    oh_initWithPath: path] autorelease];
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

- (instancetype)oh_initWithPath: (OFString *)path
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFStringEncoding encoding = [OFLocale encoding];
		struct input_id inputID;
		char name[128];
		OFMutableDictionary *buttons, *axes;

		_path = [path copy];

		if ((_fd = open([_path cStringWithEncoding: encoding],
		    O_RDONLY | O_NONBLOCK)) == -1)
			@throw [OFOpenItemFailedException
			    exceptionWithPath: _path
					 mode: @"r"
					errNo: errno];

		_evBits = OFAllocZeroedMemory(OFRoundUpToPowerOf2(OF_ULONG_BIT,
		    EV_MAX) / OF_ULONG_BIT, sizeof(unsigned long));

		if (ioctl(_fd, EVIOCGBIT(0, OFRoundUpToPowerOf2(
		    OF_ULONG_BIT, EV_MAX) / OF_ULONG_BIT *
		    sizeof(unsigned long)), _evBits) == -1)
			@throw [OFInitializationFailedException exception];

		if (!OFBitSetIsSet(_evBits, EV_KEY))
			@throw [OFInvalidArgumentException exception];

		_keyBits = OFAllocZeroedMemory(OFRoundUpToPowerOf2(OF_ULONG_BIT,
		    KEY_MAX) / OF_ULONG_BIT, sizeof(unsigned long));

		if (ioctl(_fd, EVIOCGBIT(EV_KEY, OFRoundUpToPowerOf2(
		    OF_ULONG_BIT, KEY_MAX) / OF_ULONG_BIT *
		    sizeof(unsigned long)), _keyBits) == -1)
			@throw [OFInitializationFailedException exception];

		if (!OFBitSetIsSet(_keyBits, BTN_GAMEPAD) &&
		    !OFBitSetIsSet(_keyBits, BTN_DPAD_UP))
			@throw [OFInvalidArgumentException exception];

		if (ioctl(_fd, EVIOCGID, &inputID) == -1)
			@throw [OFInvalidArgumentException exception];

		_vendorID = inputID.vendor;
		_productID = inputID.product;

		if (ioctl(_fd, EVIOCGNAME(sizeof(name)), name) == -1)
			@throw [OFInitializationFailedException exception];

		_name = [[OFString alloc] initWithCString: name
						 encoding: encoding];

		buttons = [OFMutableDictionary dictionary];
		for (size_t i = 0; i < sizeof(buttonIDs) / sizeof(*buttonIDs);
		    i++) {
			if (OFBitSetIsSet(_keyBits, buttonIDs[i])) {
				OFString *buttonName;
				OHGameControllerButton *button;

				buttonName = buttonToName(buttonIDs[i],
				    _vendorID, _productID);
				if (buttonName == nil)
					continue;

				button = [[[OHGameControllerButton alloc]
				    initWithName: buttonName] autorelease];

				[buttons setObject: button forKey: buttonName];
			}
		}
		[buttons makeImmutable];

		axes = [OFMutableDictionary dictionary];
		if (OFBitSetIsSet(_evBits, EV_ABS)) {
			_absBits = OFAllocZeroedMemory(OFRoundUpToPowerOf2(
			    OF_ULONG_BIT, ABS_MAX) / OF_ULONG_BIT,
			    sizeof(unsigned long));

			if (ioctl(_fd, EVIOCGBIT(EV_ABS, OFRoundUpToPowerOf2(
			    OF_ULONG_BIT, ABS_MAX) / OF_ULONG_BIT *
			    sizeof(unsigned long)), _absBits) == -1)
				@throw [OFInitializationFailedException
				    exception];

			for (size_t i = 0;
			    i < sizeof(axisIDs) / sizeof(*axisIDs); i++) {
				if (OFBitSetIsSet(_absBits, axisIDs[i])) {
					OFString *axisName;
					OHEvdevGameControllerAxis *axis;

					axisName = axisToName(axisIDs[i]);
					if (axisName == nil)
						continue;

					axis = [[[OHEvdevGameControllerAxis
					    alloc] initWithName: axisName]
					    autorelease];

					[axes setObject: axis forKey: axisName];
				}
			}
		}
		[axes makeImmutable];

		_rawProfile = [[OHEvdevGameControllerProfile alloc]
		    oh_initWithButtons: buttons
				  axes: axes];

		[self oh_pollState];

		objc_autoreleasePoolPop(pool);
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

	OFFreeMemory(_evBits);
	OFFreeMemory(_keyBits);
	OFFreeMemory(_absBits);

	[_name release];
	[_rawProfile release];

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

- (void)oh_pollState
{
	unsigned long keyState[OFRoundUpToPowerOf2(OF_ULONG_BIT, KEY_MAX) /
	    OF_ULONG_BIT] = { 0 };

	if (ioctl(_fd, EVIOCGKEY(sizeof(keyState)), &keyState) == -1)
		@throw [OFReadFailedException
		    exceptionWithObject: self
			requestedLength: sizeof(keyState)
				  errNo: errno];

	for (size_t i = 0; i < sizeof(buttonIDs) / sizeof(*buttonIDs);
	    i++) {
		OFString *name;
		OHGameControllerButton *button;

		if (!OFBitSetIsSet(_keyBits, buttonIDs[i]))
			continue;

		name = buttonToName(buttonIDs[i], _vendorID, _productID);
		if (name == nil)
			continue;

		button = [_rawProfile.buttons objectForKey: name];
		if (button == nil)
			continue;

		if (OFBitSetIsSet(keyState, buttonIDs[i]))
			button.value = 1.f;
		else
			button.value = 0.f;
	}

	if (OFBitSetIsSet(_evBits, EV_ABS)) {
		for (size_t i = 0; i < sizeof(axisIDs) / sizeof(*axisIDs);
		    i++) {
			struct input_absinfo info;
			OFString *name;
			OHEvdevGameControllerAxis *axis;

			if (!OFBitSetIsSet(_absBits, axisIDs[i]))
				continue;

			name = axisToName(axisIDs[i]);
			if (name == nil)
				continue;

			axis = (OHEvdevGameControllerAxis *)
			    [_rawProfile.axes objectForKey: name];
			if (axis == nil)
				continue;

			if (ioctl(_fd, EVIOCGABS(axisIDs[i]), &info) == -1)
				@throw [OFReadFailedException
				    exceptionWithObject: self
					requestedLength: sizeof(info)
						  errNo: errno];

			axis->_minValue = info.minimum;
			axis->_maxValue = info.maximum;
			axis.value = scale(info.value,
			    info.minimum, info.maximum);
		}
	}
}

- (void)retrieveState
{
	void *pool = objc_autoreleasePoolPush();
	struct input_event event;

	for (;;) {
		OFString *name;
		OHGameControllerButton *button;
		OHEvdevGameControllerAxis *axis;

		errno = 0;

		if (read(_fd, &event, sizeof(event)) < (int)sizeof(event)) {
			if (errno == EWOULDBLOCK) {
				objc_autoreleasePoolPop(pool);
				return;
			}

			@throw [OFReadFailedException
			    exceptionWithObject: self
				requestedLength: sizeof(event)
					  errNo: errno];
		}

		if (_discardUntilReport) {
			if (event.type == EV_SYN && event.value == SYN_REPORT) {
				_discardUntilReport = false;
				[self oh_pollState];
			}

			continue;
		}

		switch (event.type) {
		case EV_SYN:
			if (event.value == SYN_DROPPED) {
				_discardUntilReport = true;
				continue;
			}
			break;
		case EV_KEY:
			name = buttonToName(event.code, _vendorID, _productID);
			if (name == nil)
				continue;

			button = [_rawProfile.buttons objectForKey: name];
			if (button == nil)
				continue;

			if (event.value)
				button.value = 1.f;
			else
				button.value = 0.f;

			break;
		case EV_ABS:
			name = axisToName(event.code);
			if (name == nil)
				continue;

			axis = (OHEvdevGameControllerAxis *)
			    [_rawProfile.axes objectForKey: name];
			if (axis == nil)
				continue;

			axis.value = scale(event.value,
			   axis->_minValue, axis->_maxValue);

			break;
		}
	}
}

- (OHGamepad *)gamepad
{
	@try {
		if (_vendorID == OHVendorIDSony &&
		    _productID == OHProductIDDualSense)
			return [[[OHEvdevDualSense alloc]
			    initWithController: self] autorelease];
		else
			return [[[OHEvdevGamepad alloc]
			    initWithController: self] autorelease];
	} @catch (OFInvalidArgumentException *e) {
		return nil;
	}
}

- (OFComparisonResult)compare: (OHEvdevGameController *)otherController
{
	unsigned long long selfIndex, otherIndex;

	if (![otherController isKindOfClass: [OHEvdevGameController class]])
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
@end

@implementation OHEvdevGameControllerAxis
@end

@implementation OHEvdevGameControllerProfile
- (instancetype)oh_initWithButtons: (OFDictionary *)buttons
			      axes: (OFDictionary *)axes
{
	self = [super init];

	@try {
		_buttons = [buttons retain];
		_axes = [axes retain];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
@end
