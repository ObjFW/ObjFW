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

#import "OHJoyConPair.h"
#import "OHJoyConPair+Private.h"
#import "OFDictionary.h"
#import "OFNotification.h"
#import "OFNotificationCenter.h"
#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
# import "OFString+NSObject.h"
#endif
#import "OHGameController.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerDirectionalPad+Private.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"
#import "OHLeftJoyCon.h"
#import "OHRightJoyCon.h"

#import "OFInvalidArgumentException.h"

@interface OHJoyConPair ()
- (void)oh_leftJoyConButtonValueDidChange: (OFNotification *)notification;
- (void)oh_leftJoyConDirectionalPadValueDidChange:
    (OFNotification *)notification;
- (void)oh_rightJoyConButtonValueDidChange: (OFNotification *)notification;
- (void)oh_rightJoyConDirectionalPadValueDidChange:
    (OFNotification *)notification;
@end

static OFString *const buttonNames[] = {
	@"A", @"B", @"X", @"Y", @"L", @"R", @"ZL", @"ZR", @"Left Thumbstick",
	@"Right Thumbstick", @"+", @"-",
	/* GameController.framework doesn't expose a lot of buttons. */
#ifndef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
	@"Home", @"Capture",
#endif
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
static OFDictionary<OFString *, NSString *> *buttonsMap;
static OFDictionary<OFString *, NSString *> *directionalPadsMap;
#endif

static void
addObserverForButtons(id observer, SEL selector,
    OFDictionary OF_GENERIC(OFString *, OHGameControllerButton *) *buttons)
{
	void *pool = objc_autoreleasePoolPush();
	OFNotificationCenter *notificationCenter =
	    [OFNotificationCenter defaultCenter];
	OFNotificationName notificationName =
	    OHGameControllerButtonValueDidChangeNotification;

	for (OFString *name in buttons) {
		OHGameControllerButton *button = [buttons objectForKey: name];
		OFNotification *notification;

		[notificationCenter addObserver: observer
				       selector: selector
					   name: notificationName
					 object: button];

		/* Manually trigger it once to get the initial state. */
		notification = [OFNotification
		    notificationWithName: notificationName
				  object: button];
		[notificationCenter postNotification: notification];
	}

	objc_autoreleasePoolPop(pool);
}

static void
addObserverForDirectionalPads(id observer, SEL selector,
    OFDictionary OF_GENERIC(OFString *, OHGameControllerDirectionalPad *)
    *directionalPads)
{
	void *pool = objc_autoreleasePoolPush();
	OFNotificationCenter *notificationCenter =
	    [OFNotificationCenter defaultCenter];
	OFNotificationName notificationName =
	    OHGameControllerDirectionalPadValueDidChangeNotification;

	for (OFString *name in directionalPads) {
		OHGameControllerDirectionalPad *directionalPad =
		    [directionalPads objectForKey: name];
		OFNotification *notification;

		[notificationCenter addObserver: observer
				       selector: selector
					   name: notificationName
					 object: directionalPad];

		/* Manually trigger it once to get the initial state. */
		notification = [OFNotification
		    notificationWithName: notificationName
				  object: directionalPad];
		[notificationCenter postNotification: notification];
	}

	objc_autoreleasePoolPop(pool);
}

static void
removeObserverForButtons(id observer, SEL selector,
    OFDictionary OF_GENERIC(OFString *, OHGameControllerButton *) *buttons)
{
	void *pool = objc_autoreleasePoolPush();
	OFNotificationCenter *notificationCenter =
	    [OFNotificationCenter defaultCenter];
	OFNotificationName notificationName =
	    OHGameControllerButtonValueDidChangeNotification;

	for (OFString *name in buttons) {
		OHGameControllerButton *button = [buttons objectForKey: name];

		[notificationCenter removeObserver: observer
					  selector: selector
					      name: notificationName
					    object: button];
	}

	objc_autoreleasePoolPop(pool);
}

static void
removeObserverForDirectionalPads(id observer, SEL selector,
    OFDictionary OF_GENERIC(OFString *, OHGameControllerDirectionalPad *)
    *directionalPads)
{
	void *pool = objc_autoreleasePoolPush();
	OFNotificationCenter *notificationCenter =
	    [OFNotificationCenter defaultCenter];
	OFNotificationName notificationName =
	    OHGameControllerDirectionalPadValueDidChangeNotification;

	for (OFString *name in directionalPads) {
		OHGameControllerDirectionalPad *directionalPad =
		    [directionalPads objectForKey: name];

		[notificationCenter removeObserver: observer
					  selector: selector
					      name: notificationName
					    object: directionalPad];
	}

	objc_autoreleasePoolPop(pool);
}

@implementation OHJoyConPair
@synthesize buttons = _buttons, directionalPads = _directionalPads;

#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
+ (void)initialize
{
	void *pool;

	if (self != [OHJoyConPair class])
		return;

	pool = objc_autoreleasePoolPush();

	buttonsMap = [[OFDictionary alloc] initWithKeysAndObjects:
	    @"A", @"Button A".NSObject,
	    @"B", @"Button B".NSObject,
	    @"X", @"Button X".NSObject,
	    @"Y", @"Button Y".NSObject,
	    @"L", @"Left Shoulder".NSObject,
	    @"R", @"Right Shoulder".NSObject,
	    @"ZL", @"Left Trigger".NSObject,
	    @"ZR", @"Right Trigger".NSObject,
	    @"Left Thumbstick", @"Left Thumbstick".NSObject,
	    @"Right Thumbstick", @"Right Thumbstick".NSObject,
	    @"+", @"Button Menu".NSObject,
	    @"-", @"Button Options".NSObject,
	    nil];
	directionalPadsMap = [[OFDictionary alloc] initWithKeysAndObjects:
	    @"Left Thumbstick", @"Left Thumbstick".NSObject,
	    @"Right Thumbstick", @"Right Thumbstick".NSObject,
	    @"D-Pad", @"Direction Pad".NSObject,
	    nil];

	objc_autoreleasePoolPop(pool);
}
#endif

+ (instancetype)gamepadWithLeftJoyCon: (OHLeftJoyCon *)leftJoyCon
			  rightJoyCon: (OHRightJoyCon *)rightJoyCon
{
	return [[[self alloc] initWithLeftJoyCon: leftJoyCon
				     rightJoyCon: rightJoyCon] autorelease];
}

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
		OFMutableDictionary *directionalPads;
		OHGameControllerAxis *xAxis, *yAxis;
		OHGameControllerDirectionalPad *directionalPad;
#ifndef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
		OHGameControllerButton *up, *down, *left, *right;
#endif

		for (size_t i = 0; i < numButtons; i++) {
			OHGameControllerButton *button = [OHGameControllerButton
			    oh_elementWithName: buttonNames[i]
					analog: false];
			[buttons setObject: button forKey: buttonNames[i]];
		}
		[buttons makeImmutable];
		_buttons = [buttons copy];

		directionalPads =
		    [OFMutableDictionary dictionaryWithCapacity: 2];

		xAxis = [OHGameControllerAxis oh_elementWithName: @"X"
							  analog: true];
		yAxis = [OHGameControllerAxis oh_elementWithName: @"Y"
							  analog: true];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"Left Thumbstick"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: true];
		[directionalPads setObject: directionalPad
				    forKey: @"Left Thumbstick"];

		xAxis = [OHGameControllerAxis oh_elementWithName: @"X"
							  analog: true];
		yAxis = [OHGameControllerAxis oh_elementWithName: @"Y"
							  analog: true];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"Right Thumbstick"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: true];
		[directionalPads setObject: directionalPad
				    forKey: @"Right Thumbstick"];

#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
		xAxis = [OHGameControllerAxis oh_elementWithName: @"D-Pad X"
							  analog: false];
		yAxis = [OHGameControllerAxis oh_elementWithName: @"D-Pad Y"
							  analog: false];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"D-Pad"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: false];
#else
		up = [OHGameControllerButton oh_elementWithName: @"D-Pad Up"
							 analog: false];
		down = [OHGameControllerButton oh_elementWithName: @"D-Pad Down"
							   analog: false];
		left = [OHGameControllerButton oh_elementWithName: @"D-Pad Left"
							   analog: false];
		right = [OHGameControllerButton
		    oh_elementWithName: @"D-Pad Right"
				analog: false];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"D-Pad"
				up: up
			      down: down
			      left: left
			     right: right
			    analog: false];
#endif
		[directionalPads setObject: directionalPad forKey: @"D-Pad"];

		[directionalPads makeImmutable];
		_directionalPads = [directionalPads copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithLeftJoyCon: (OHLeftJoyCon *)leftJoyCon
		       rightJoyCon: (OHRightJoyCon *)rightJoyCon
{
	self = [self oh_init];

	@try {
		void *pool = objc_autoreleasePoolPush();

		_leftJoyCon = [leftJoyCon retain];
		_rightJoyCon = [rightJoyCon retain];

		addObserverForButtons(self,
		    @selector(oh_leftJoyConButtonValueDidChange:),
		    _leftJoyCon.buttons);
		addObserverForDirectionalPads(self,
		    @selector(oh_leftJoyConDirectionalPadValueDidChange:),
		    _leftJoyCon.directionalPads);
		addObserverForButtons(self,
		    @selector(oh_rightJoyConButtonValueDidChange:),
		    _rightJoyCon.buttons);
		addObserverForDirectionalPads(self,
		    @selector(oh_rightJoyConDirectionalPadValueDidChange:),
		    _rightJoyCon.directionalPads);

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	removeObserverForButtons(self,
	    @selector(oh_leftJoyConButtonValueDidChange:),
	    _leftJoyCon.buttons);
	removeObserverForDirectionalPads(self,
	    @selector(oh_leftJoyConDirectionalPadValueDidChange:),
	    _leftJoyCon.directionalPads);
	removeObserverForButtons(self,
	    @selector(oh_rightJoyConButtonValueDidChange:),
	    _rightJoyCon.buttons);
	removeObserverForDirectionalPads(self,
	    @selector(oh_rightJoyConDirectionalPadValueDidChange:),
	    _rightJoyCon.directionalPads);

	[_leftJoyCon release];
	[_rightJoyCon release];
	[_buttons release];
	[_directionalPads release];

	[super dealloc];
}

- (void)oh_leftJoyConButtonValueDidChange: (OFNotification *)notification
{
	OHGameControllerButton *triggeringButton = notification.object;
	OFString *name = triggeringButton.name;
	OHGameControllerButton *button = nil;

	if ([name isEqual: @"North"])
		button = [[_directionalPads objectForKey: @"D-Pad"] right];
	else if ([name isEqual: @"South"])
		button = [[_directionalPads objectForKey: @"D-Pad"] left];
	else if ([name isEqual: @"West"])
		button = [[_directionalPads objectForKey: @"D-Pad"] up];
	else if ([name isEqual: @"East"])
		button = [[_directionalPads objectForKey: @"D-Pad"] down];
	else
		button = [_buttons objectForKey: name];

	button.value = triggeringButton.value;
}

- (void)oh_leftJoyConDirectionalPadValueDidChange:
    (OFNotification *)notification
{
	OHGameControllerDirectionalPad *triggeringPad = notification.object;
	OFString *name = triggeringPad.name;
	OHGameControllerDirectionalPad *pad = nil;

	if ([name isEqual: @"Left Thumbstick"])
		pad = [_directionalPads objectForKey: @"Left Thumbstick"];

	pad.xAxis.value = -triggeringPad.yAxis.value;
	pad.yAxis.value = triggeringPad.xAxis.value;
}

- (void)oh_rightJoyConButtonValueDidChange: (OFNotification *)notification
{
	OHGameControllerButton *triggeringButton = notification.object;
	OFString *name = triggeringButton.name;
	OHGameControllerButton *button = nil;

	if ([name isEqual: @"Left Thumbstick"])
		button = [_buttons objectForKey: @"Right Thumbstick"];
	else
		button = [_buttons objectForKey: name];

	button.value = triggeringButton.value;
}

- (void)oh_rightJoyConDirectionalPadValueDidChange:
    (OFNotification *)notification
{
	OHGameControllerDirectionalPad *triggeringPad = notification.object;
	OFString *name = triggeringPad.name;
	OHGameControllerDirectionalPad *pad = nil;

	if ([name isEqual: @"Left Thumbstick"])
		pad = [_directionalPads objectForKey: @"Right Thumbstick"];

	pad.xAxis.value = triggeringPad.yAxis.value;
	pad.yAxis.value = -triggeringPad.xAxis.value;
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

- (OHGameControllerButton *)leftTriggerButton
{
	return [_buttons objectForKey: @"ZL"];
}

- (OHGameControllerButton *)rightTriggerButton
{
	return [_buttons objectForKey: @"ZR"];
}

- (OHGameControllerButton *)leftThumbstickButton
{
	return [_buttons objectForKey: @"Left Thumbstick"];
}

- (OHGameControllerButton *)rightThumbstickButton
{
	return [_buttons objectForKey: @"Right Thumbstick"];
}

- (OHGameControllerButton *)menuButton
{
	return [_buttons objectForKey: @"+"];
}

- (OHGameControllerButton *)optionsButton
{
	return [_buttons objectForKey: @"-"];
}

- (OHGameControllerButton *)homeButton
{
	return [_buttons objectForKey: @"Home"];
}

- (OHGameControllerDirectionalPad *)leftThumbstick
{
	return [_directionalPads objectForKey: @"Left Thumbstick"];
}

- (OHGameControllerDirectionalPad *)rightThumbstick
{
	return [_directionalPads objectForKey: @"Right Thumbstick"];
}

- (OHGameControllerDirectionalPad *)dPad
{
	return [_directionalPads objectForKey: @"D-Pad"];
}

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
