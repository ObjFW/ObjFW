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

#import <GameController/GameController.h>

#import "OHGCFGameController.h"
#import "NSString+OFObject.h"
#import "OFArray.h"
#import "OFDictionary.h"
#import "OHDualSenseGamepad.h"
#import "OHDualSenseGamepad+Private.h"
#import "OHGCFGameControllerProfile.h"
#import "OHGameController.h"
#import "OHGameController+Private.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHJoyConPair.h"
#import "OHJoyConPair+Private.h"

@implementation OHGCFGameController
@synthesize name = _name;

+ (void)initialize
{
	if (self != OHGCFGameController.class)
		return;

	GCController.shouldMonitorBackgroundEvents = YES;
}

+ (OFArray<OHGameController *> *)controllers
{
	OFMutableArray *controllers = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();

	for (GCController *controller in GCController.controllers)
		[controllers addObject: [[[self alloc]
		    oh_initWithGCController: controller] autorelease]];

	objc_autoreleasePoolPop(pool);

	return controllers;
}

- (instancetype)oh_init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)oh_initWithGCController: (GCController *)controller
{
	self = [super oh_init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		Class profileClass;

		_controller = [controller retain];
		_name = [_controller.vendorName.OFObject copy];

		if ([_name isEqual: @"DualSense Wireless Controller"])
			profileClass = [OHDualSenseGamepad class];
		else if ([_name isEqual: @"Joy-Con (L/R)"])
			profileClass = [OHJoyConPair class];
		else
			profileClass = [OHGCFGameControllerProfile class];

		_profile = [[profileClass alloc]
		    oh_initWithLiveInput: _controller.input.unmappedInput];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_controller release];
	[_profile release];

	[super dealloc];
}

- (void)updateState
{
	void *pool = objc_autoreleasePoolPush();
	id <GCDevicePhysicalInputState> snapshot =
	    [_controller.input.unmappedInput capture];

	for (id <GCPhysicalInputElement> element in snapshot.elements) {
		if ([element conformsToProtocol: @protocol(GCButtonElement)]) {
			OHGameControllerButton *button =
			    _profile.oh_buttonsMap[element.localizedName];

			OFAssert(button != nil);

			button.value = ((id <GCButtonElement>)element)
			    .pressedInput.value;
		}

		if ([element conformsToProtocol: @protocol(GCAxisElement)]) {
			OHGameControllerAxis *axis =
			    _profile.oh_axesMap[element.localizedName];

			OFAssert(axis != nil);

			axis.value = ((id <GCAxisElement>)element)
			    .absoluteInput.value;
		}

		if ([element conformsToProtocol:
		    @protocol(GCDirectionPadElement)]) {
			OHGameControllerDirectionalPad *pad =
			    _profile.oh_directionalPadsMap[
			    element.localizedName];
			id <GCDirectionPadElement> padGC =
			    (id <GCDirectionPadElement>)element;

			OFAssert(pad != nil);

			pad.xAxis.value = padGC.xAxis.value;
			pad.yAxis.value =
			    (padGC.yAxis.value != 0 ? -padGC.yAxis.value : 0);
		}
	}

	objc_autoreleasePoolPop(pool);
}

- (OFNumber *)vendorID
{
	return nil;
}

- (OFNumber *)productID
{
	return nil;
}

- (id <OHGameControllerProfile>)profile
{
	return _profile;
}

- (id <OHGamepad>)gamepad
{
	return nil;
}

- (id <OHExtendedGamepad>)extendedGamepad
{
	return nil;
}
@end
