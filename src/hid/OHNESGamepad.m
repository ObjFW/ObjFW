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

#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
# import <GameController/GameController.h>
#endif

#import "OHNESGamepad.h"
#import "OHNESGamepad+Private.h"
#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
# import "NSString+OFObject.h"
#endif
#import "OFDictionary.h"
#import "OHEmulatedGameControllerTriggerButton.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerDirectionalPad+Private.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"

static OFString *const buttonNames[] = {
	@"A", @"B", @"X", @"Y", @"L", @"R", @"Start", @"Select"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHNESGamepad
@synthesize buttons = _buttons, directionalPads = _directionalPads;
#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
@synthesize oh_buttonsMap = _buttonsMap;
@synthesize oh_directionalPadsMap = _directionalPadsMap;
#endif

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
		OHGameControllerButton *button;
		OHGameControllerAxis *xAxis, *yAxis;
		OHGameControllerDirectionalPad *directionalPad;

		for (size_t i = 0; i < numButtons; i++) {
			button = [OHGameControllerButton
			    oh_elementWithName: buttonNames[i]
					analog: false];
			[buttons setObject: button forKey: buttonNames[i]];
		}
		[buttons makeImmutable];
		_buttons = [buttons copy];

		xAxis = [OHGameControllerAxis oh_elementWithName: @"D-Pad X"
							  analog: false];
		yAxis = [OHGameControllerAxis oh_elementWithName: @"D-Pad Y"
							  analog: false];
		directionalPad = [OHGameControllerDirectionalPad
		    oh_padWithName: @"D-Pad"
			     xAxis: xAxis
			     yAxis: yAxis
			    analog: false];

		_directionalPads = [[OFDictionary alloc]
		    initWithObject: directionalPad
			    forKey: @"D-Pad"];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

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

				/*
				 * We don't use "Button" as part of a button
				 * name, but GameController.framework likes to
				 * do this.
				 */
				if ([buttonName hasSuffix: @" Button"])
					buttonName = [buttonName
					    substringToIndex:
					    buttonName.length - 7];

				/* Replace these names */
				if ([buttonName isEqual: @"L1"])
					buttonName = @"L";
				else if ([buttonName isEqual: @"R1"])
					buttonName = @"R";
				else if ([buttonName isEqual: @"Menu"])
					buttonName = @"Start";
				/*
				 * Weird mapping on the 8Bitdo NES30 GamePad,
				 * which is currently the only controller
				 * supported for OHNESGamepad with GCF.
				 */
				else if ([buttonName isEqual: @"Home"])
					buttonName = @"Select";

				buttonsMap[element.localizedName] =
				    _buttons[buttonName];
			}

			if ([element conformsToProtocol:
			    @protocol(GCDirectionPadElement)]) {
				OFString *padName = name;

				if ([padName isEqual: @"Direction Pad"])
					padName = @"D-Pad";

				directionalPadsMap[element.localizedName] =
				    _directionalPads[padName];
			}
		}

		[buttonsMap makeImmutable];
		[directionalPadsMap makeImmutable];

		_buttonsMap = [buttonsMap copy];
		_directionalPadsMap = [directionalPadsMap copy];

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

- (OHGameControllerButton *)menuButton
{
	return [_buttons objectForKey: @"Start"];
}

- (OHGameControllerButton *)optionsButton
{
	return [_buttons objectForKey: @"Select"];
}

- (OHGameControllerButton *)homeButton
{
	return [_buttons objectForKey: @"Home"];
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
