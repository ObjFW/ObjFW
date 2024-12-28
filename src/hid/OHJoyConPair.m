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

#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
# import <GameController/GameController.h>
#endif

#import "OHJoyConPair.h"
#import "OHJoyConPair+Private.h"
#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
# import "NSString+OFObject.h"
#endif
#import "OFDictionary.h"
#import "OFSet.h"
#import "OHGameController.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerDirectionalPad+Private.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"
#import "OHLeftJoyCon.h"
#import "OHRightJoyCon.h"

#import "OFInvalidArgumentException.h"

static OFString *const buttonNames[] = {
	/* Left JoyCon */
	@"L", @"ZL", @"Left Thumbstick", @"-", @"Capture",
	/* Right JoyCon */
	@"X", @"B", @"A", @"Y", @"R", @"ZR", @"Right Thumbstick", @"+", @"Home"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHJoyConPair
@synthesize buttons = _buttons, directionalPads = _directionalPads;
#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
@synthesize oh_buttonsMap = _buttonsMap;
@synthesize oh_directionalPadsMap = _directionalPadsMap;
@synthesize oh_filteredButtons = _filteredButtons;
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
			OHGameControllerButton *button;

#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
			/* These don't work with GameController.framework */
			if ([buttonNames[i] isEqual: @"Home"] ||
			    [buttonNames[i] isEqual: @"Capture"])
				continue;
#endif

			button = [OHGameControllerButton
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

	_leftJoyCon = [leftJoyCon retain];
	_rightJoyCon = [rightJoyCon retain];

	return self;
}

#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
- (instancetype)oh_initWithLiveInput: (GCControllerLiveInput *)liveInput
{
	self = [self oh_init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttonsMap =
		    [OFMutableDictionary dictionary];
		OFMutableDictionary *directionalPadsMap =
		    [OFMutableDictionary dictionary];
		OFMutableSet *filteredButtons = [OFMutableSet set];

		for (id <GCPhysicalInputElement> element in
		    liveInput.elements) {
			/*
			 * Unfortunately there is no way to get the unlocalized
			 * name or an identifier, but it seems in practice this
			 * is not localized. Let's hope it stays this way.
			 */
			OFString *name = element.localizedName.OFObject;

			if ([element conformsToProtocol:
			    @protocol(GCButtonElement)]) {
				OFString *buttonName = name;
				bool filter = false;

				/*
				 * We don't use "Button" as part of a button
				 * name, but GameController.framework likes to
				 * do this.
				 */
				if ([buttonName hasSuffix: @" Button"])
					buttonName = [buttonName
					    substringToIndex:
					    buttonName.length - 7];

				/* These buttons don't work - filter them. */
				if ([buttonName isEqual: @"HOME"])
					filter = true;
				else if ([buttonName isEqual: @"Share"])
					filter = true;

				/* Replace these names */
				else if ([buttonName isEqual: @"Left Stick"])
					buttonName = @"Left Thumbstick";
				else if ([buttonName isEqual: @"Right Stick"])
					buttonName = @"Right Thumbstick";

				if (filter)
					[filteredButtons addObject:
					    element.localizedName];
				else
					buttonsMap[element.localizedName] =
					    _buttons[buttonName];
			}

			if ([element conformsToProtocol:
			    @protocol(GCDirectionPadElement)]) {
				OFString *padName = name;

				/* Replace these names */
				if ([padName isEqual: @"Directional Buttons"])
					padName = @"D-Pad";
				else if ([padName isEqual: @"Left Stick"])
					padName = @"Left Thumbstick";
				else if ([padName isEqual: @"Right Stick"])
					padName = @"Right Thumbstick";

				directionalPadsMap[element.localizedName] =
				    _directionalPads[padName];
			}
		}

		[buttonsMap makeImmutable];
		[directionalPadsMap makeImmutable];
		[filteredButtons makeImmutable];

		_buttonsMap = [buttonsMap copy];
		_directionalPadsMap = [directionalPadsMap copy];
		_filteredButtons = [filteredButtons copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
#endif

- (void)dealloc
{
	[_leftJoyCon release];
	[_rightJoyCon release];
	[_buttons release];
	[_directionalPads release];
#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
	[_buttonsMap release];
	[_directionalPadsMap release];
#endif

	[super dealloc];
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
- (OFDictionary<NSString *, OHGameControllerAxis *> *)oh_axesMap
{
	return [OFDictionary dictionary];
}
#endif
@end
