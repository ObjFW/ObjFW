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

#import "OHWiimoteWithNunchuk.h"
#import "OFDictionary.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"

static OFString *const buttonNames[] = {
	@"C", @"Z"
};
static const size_t numButtons = sizeof(buttonNames) / sizeof(*buttonNames);

@implementation OHWiimoteWithNunchuk
- (instancetype)init
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttons =
		    [[_buttons mutableCopy] autorelease];
		OFMutableDictionary *directionalPads =
		    [[_directionalPads mutableCopy] autorelease];
		OHGameControllerAxis *xAxis, *yAxis;
		OHGameControllerDirectionalPad *directionalPad;

		for (size_t i = 0; i < numButtons; i++) {
			OHGameControllerButton *button =
			    [[[OHGameControllerButton alloc]
			    initWithName: buttonNames[i]] autorelease];

			[buttons setObject: button forKey: buttonNames[i]];
		}

		xAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"X"] autorelease];
		yAxis = [[[OHGameControllerAxis alloc]
		    initWithName: @"Y"] autorelease];
		directionalPad = [[[OHGameControllerDirectionalPad alloc]
		    initWithName: @"Analog Stick"
			   xAxis: xAxis
			   yAxis: yAxis] autorelease];
		[directionalPads setObject: directionalPad
				    forKey: @"Analog Stick"];

		[buttons makeImmutable];
		[_buttons release];
		_buttons = [buttons retain];

		[directionalPads makeImmutable];
		[_directionalPads release];
		_directionalPads = [directionalPads retain];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}
@end
