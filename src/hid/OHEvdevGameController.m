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

#import "OHDualSenseGamepad.h"
#import "OHDualSenseGamepad+Private.h"
#import "OHDualShock4Gamepad.h"
#import "OHDualShock4Gamepad+Private.h"
#import "OHEvdevExtendedGamepad.h"
#import "OHExtendedN64Controller.h"
#import "OHGameControllerAxis+Private.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerProfile.h"
#import "OHLeftJoyCon.h"
#import "OHLeftJoyCon+Private.h"
#import "OHN64Controller.h"
#import "OHN64Controller+Private.h"
#import "OHRightJoyCon.h"
#import "OHRightJoyCon+Private.h"
#import "OHStadiaGamepad.h"
#import "OHStadiaGamepad+Private.h"

#include <sys/ioctl.h>
#include <linux/input.h>

#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"

const uint16_t OHEvdevButtonIDs[] = {
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
const size_t OHNumEvdevButtonIDs =
    sizeof(OHEvdevButtonIDs) / sizeof(*OHEvdevButtonIDs);
const uint16_t OHEvdevAxisIDs[] = {
	ABS_X, ABS_Y, ABS_Z, ABS_RX, ABS_RY, ABS_RZ, ABS_THROTTLE, ABS_RUDDER,
	ABS_WHEEL, ABS_GAS, ABS_BRAKE, ABS_HAT0X, ABS_HAT0Y, ABS_HAT1X,
	ABS_HAT1Y, ABS_HAT2X, ABS_HAT2Y, ABS_HAT3X, ABS_HAT3Y
};
const size_t OHNumEvdevAxisIDs =
    sizeof(OHEvdevAxisIDs) / sizeof(*OHEvdevAxisIDs);

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
@synthesize name = _name, profile = _profile;

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
			    initWithPath: path] autorelease];
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

- (instancetype)initWithPath: (OFString *)path
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFStringEncoding encoding = [OFLocale encoding];
		struct input_id inputID;
		char name[128];

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

		if (OFBitSetIsSet(_evBits, EV_ABS)) {
			_absBits = OFAllocZeroedMemory(OFRoundUpToPowerOf2(
			    OF_ULONG_BIT, ABS_MAX) / OF_ULONG_BIT,
			    sizeof(unsigned long));

			if (ioctl(_fd, EVIOCGBIT(EV_ABS, OFRoundUpToPowerOf2(
			    OF_ULONG_BIT, ABS_MAX) / OF_ULONG_BIT *
			    sizeof(unsigned long)), _absBits) == -1)
				@throw [OFInitializationFailedException
				    exception];
		}

		if (_vendorID == OHVendorIDSony &&
		    _productID == OHProductIDDualSense)
			_profile = [[OHDualSenseGamepad alloc] init];
		else if (_vendorID == OHVendorIDSony &&
		    _productID == OHProductIDDualShock4)
			_profile = [[OHDualShock4Gamepad alloc] init];
		else if (_vendorID == OHVendorIDNintendo &&
		    _productID == OHProductIDN64Controller)
			_profile = [[OHExtendedN64Controller alloc] init];
		else if (_vendorID == OHVendorIDNintendo &&
		    _productID == OHProductIDLeftJoyCon)
			_profile = [[OHLeftJoyCon alloc] init];
		else if (_vendorID == OHVendorIDNintendo &&
		    _productID == OHProductIDRightJoyCon)
			_profile = [[OHRightJoyCon alloc] init];
		else if (_vendorID == OHVendorIDGoogle &&
		    _productID == OHProductIDStadiaController)
			_profile = [[OHStadiaGamepad alloc] init];
		else
			_profile = [[OHEvdevExtendedGamepad alloc]
			    initWithKeyBits: _keyBits
				     evBits: _evBits
				    absBits: _absBits
				   vendorID: _vendorID
				  productID: _productID];

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
	[_profile release];

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

	for (size_t i = 0; i < OHNumEvdevButtonIDs; i++) {
		OHGameControllerButton *button;

		if (!OFBitSetIsSet(_keyBits, OHEvdevButtonIDs[i]))
			continue;

		button = [_profile
		    oh_buttonForEvdevButton: OHEvdevButtonIDs[i]];
		if (button == nil)
			continue;

		if (OFBitSetIsSet(keyState, OHEvdevButtonIDs[i]))
			button.value = 1.f;
		else
			button.value = 0.f;
	}

	if (OFBitSetIsSet(_evBits, EV_ABS)) {
		for (size_t i = 0; i < OHNumEvdevAxisIDs; i++) {
			struct input_absinfo info;
			OHGameControllerAxis *axis;

			if (!OFBitSetIsSet(_absBits, OHEvdevAxisIDs[i]))
				continue;

			axis = [_profile
			    oh_axisForEvdevAxis: OHEvdevAxisIDs[i]];
			if (axis == nil)
				continue;

			if (ioctl(_fd, EVIOCGABS(OHEvdevAxisIDs[i]),
			    &info) == -1)
				@throw [OFReadFailedException
				    exceptionWithObject: self
					requestedLength: sizeof(info)
						  errNo: errno];

			axis.oh_minRawValue = info.minimum;
			axis.oh_maxRawValue = info.maximum;
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
		OHGameControllerButton *button;
		OHGameControllerAxis *axis;

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
			button = [_profile oh_buttonForEvdevButton: event.code];
			if (button == nil)
				continue;

			if (event.value)
				button.value = 1.f;
			else
				button.value = 0.f;

			break;
		case EV_ABS:
			axis = [_profile oh_axisForEvdevAxis: event.code];
			if (axis == nil)
				continue;

			axis.value = scale(event.value,
			   axis.oh_minRawValue, axis.oh_maxRawValue);

			break;
		}
	}
}

- (id <OHGamepad>)gamepad
{
	if ([_profile conformsToProtocol: @protocol(OHGamepad)])
		return (id <OHGamepad>)_profile;

	return nil;
}

- (id <OHExtendedGamepad>)extendedGamepad
{
	if ([_profile conformsToProtocol: @protocol(OHExtendedGamepad)])
		return (id <OHExtendedGamepad>)_profile;

	return nil;
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
