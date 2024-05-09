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
buttonToName(uint16_t button)
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
		return @"L";
	case BTN_TR:
		return @"R";
	case BTN_TL2:
		return @"ZL";
	case BTN_TR2:
		return @"ZR";
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
	}

	return nil;
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

		if (ioctl(_fd, EVIOCGNAME(sizeof(name)), name) == -1)
			@throw [OFInitializationFailedException exception];

		_name = [[OFString alloc] initWithCString: name
						 encoding: encoding];

		_buttons = [[OFMutableSet alloc] init];
		for (size_t i = 0; i < sizeof(buttons) / sizeof(*buttons); i++)
			[_buttons addObject: buttonToName(buttons[i])];

		_pressedButtons = [[OFMutableSet alloc] init];

		if (OFBitSetIsSet(evBits, EV_ABS)) {
			if (ioctl(_fd, EVIOCGBIT(EV_ABS, sizeof(absBits)),
			    absBits) == -1)
				@throw [OFInitializationFailedException
				    exception];

			if (OFBitSetIsSet(absBits, ABS_X) &&
			    OFBitSetIsSet(absBits, ABS_Y))
				_hasLeftAnalogStick = true;

			if (OFBitSetIsSet(absBits, ABS_RX) &&
			    OFBitSetIsSet(absBits, ABS_RY))
				_hasRightAnalogStick = true;

			if (OFBitSetIsSet(absBits, ABS_HAT0X) &&
			    OFBitSetIsSet(absBits, ABS_HAT0Y)) {
				[_buttons addObject: @"D-Pad Left"];
				[_buttons addObject: @"D-Pad Right"];
				[_buttons addObject: @"D-Pad Up"];
				[_buttons addObject: @"D-Pad Down"];
			}

			if (OFBitSetIsSet(absBits, ABS_Z))
				[_buttons addObject: @"ZL"];
			if (OFBitSetIsSet(absBits, ABS_RZ))
				[_buttons addObject: @"ZR"];
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
			if (event.value)
				[_pressedButtons addObject:
				    buttonToName(event.code)];
			else
				[_pressedButtons removeObject:
				    buttonToName(event.code)];
			break;
		case EV_ABS:
			switch (event.code) {
			case ABS_X:
				_leftAnalogStickPosition.x =
				    (float)event.value /
				    (event.value < 0 ? -INT16_MIN : INT16_MAX);
				break;
			case ABS_Y:
				_leftAnalogStickPosition.y =
				    (float)event.value /
				    (event.value < 0 ? -INT16_MIN : INT16_MAX);
				break;
			case ABS_RX:
				_rightAnalogStickPosition.x =
				    (float)event.value /
				    (event.value < 0 ? -INT16_MIN : INT16_MAX);
				break;
			case ABS_RY:
				_rightAnalogStickPosition.y =
				    (float)event.value /
				    (event.value < 0 ? -INT16_MIN : INT16_MAX);
				break;
			case ABS_HAT0X:
				if (event.value < 0) {
					[_pressedButtons addObject:
					    @"D-Pad Left"];
					[_pressedButtons removeObject:
					    @"D-Pad Right"];
				} else if (event.value > 0) {
					[_pressedButtons addObject:
					    @"D-Pad Right"];
					[_pressedButtons removeObject:
					    @"D-Pad Left"];
				} else {
					[_pressedButtons removeObject:
					    @"D-Pad Left"];
					[_pressedButtons removeObject:
					    @"D-Pad Right"];
				}
				break;
			case ABS_HAT0Y:
				if (event.value < 0) {
					[_pressedButtons addObject:
					    @"D-Pad Up"];
					[_pressedButtons removeObject:
					    @"D-Pad Down"];
				} else if (event.value > 0) {
					[_pressedButtons addObject:
					    @"D-Pad Down"];
					[_pressedButtons removeObject:
					    @"D-Pad Up"];
				} else {
					[_pressedButtons removeObject:
					    @"D-Pad Up"];
					[_pressedButtons removeObject:
					    @"D-Pad Down"];
				}
				break;
			case ABS_Z:
				if (event.value > 0)
					[_pressedButtons addObject: @"ZL"];
				else
					[_pressedButtons removeObject: @"ZL"];
				break;
			case ABS_RZ:
				if (event.value > 0)
					[_pressedButtons addObject: @"ZR"];
				else
					[_pressedButtons removeObject: @"ZR"];
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
