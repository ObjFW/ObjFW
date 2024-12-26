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

#import "OHGCFGameControllerProfile.h"
#import "NSString+OFObject.h"
#import "OFDictionary.h"
#import "OHGameControllerDirectionalPad+Private.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerElement+Private.h"
#import "OHGameControllerElement.h"

@implementation OHGCFGameControllerProfile
@synthesize buttons = _buttons, axes = _axes;
@synthesize directionalPads = _directionalPads, oh_buttonsMap = _buttonsMap;
@synthesize oh_axesMap = _axesMap, oh_directionalPadsMap = _directionalPadsMap;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)oh_initWithLiveInput: (GCControllerLiveInput *)liveInput
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttons = [OFMutableDictionary dictionary];
		OFMutableDictionary *axes = [OFMutableDictionary dictionary];
		OFMutableDictionary *directionalPads =
		    [OFMutableDictionary dictionary];
		OFMutableDictionary *buttonsMap =
		    [OFMutableDictionary dictionary];
		OFMutableDictionary *axesMap = [OFMutableDictionary dictionary];
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
				bool analog = ((id <GCButtonElement>)element)
				    .pressedInput.analog;
				OHGameControllerButton *button;

				/*
				 * We don't use "Button" as part of a button
				 * name, but GameController.framework likes to
				 * do this.
				 */
				if ([buttonName hasSuffix: @" Button"])
					buttonName = [buttonName
					    substringToIndex:
					    buttonName.length - 7];

				button = [OHGameControllerButton
				    oh_elementWithName: buttonName
						analog: analog];

				buttons[buttonName] = button;
				buttonsMap[element.localizedName] = button;
			}

			if ([element conformsToProtocol:
			    @protocol(GCAxisElement)]) {
				bool analog = ((id <GCAxisElement>)element)
				    .absoluteInput.analog;
				OHGameControllerAxis *axis =
				    [OHGameControllerAxis
				    oh_elementWithName: name
						analog: analog];

				axes[name] = axis;
				axesMap[element.localizedName] = axis;
			}

			if ([element conformsToProtocol:
			    @protocol(GCDirectionPadElement)]) {
				id <GCDirectionPadElement> padGC =
				    (id <GCDirectionPadElement>)element;
				OFString *xAxisName =
				    [name stringByAppendingString: @" X"];
				OFString *yAxisName =
				    [name stringByAppendingString: @" Y"];
				OHGameControllerAxis *xAxis =
				    [OHGameControllerAxis
				    oh_elementWithName: xAxisName
						analog: padGC.xAxis.analog];
				OHGameControllerAxis *yAxis =
				    [OHGameControllerAxis
				    oh_elementWithName: yAxisName
						analog: padGC.yAxis.analog];
				OHGameControllerDirectionalPad *pad =
				    [OHGameControllerDirectionalPad
				    oh_padWithName: name
					     xAxis: xAxis
					     yAxis: yAxis
					    analog: padGC.xAxis.analog ||
						    padGC.yAxis.analog];

				directionalPads[name] = pad;
				directionalPadsMap[element.localizedName] = pad;
			}
		}

		[buttonsMap makeImmutable];
		[axesMap makeImmutable];
		[directionalPadsMap makeImmutable];
		[buttons makeImmutable];
		[axes makeImmutable];
		[directionalPads makeImmutable];

		_buttons = [buttons copy];
		_axes = [axes copy];
		_directionalPads = [directionalPads copy];
		_buttonsMap = [buttonsMap copy];
		_axesMap = [axesMap copy];
		_directionalPadsMap = [directionalPadsMap copy];

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
	[_directionalPads release];
	[_buttonsMap release];
	[_axesMap release];
	[_directionalPadsMap release];

	[super dealloc];
}
@end
