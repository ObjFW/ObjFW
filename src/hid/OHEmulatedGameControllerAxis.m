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

#import "config.h"

#import "OHEmulatedGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"

@implementation OHEmulatedGameControllerAxis
- (instancetype)oh_initWithName: (OFString *)name analog: (bool)analog
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)
    oh_initWithNegativeButton: (OHGameControllerButton *)negativeButton
	       positiveButton: (OHGameControllerButton *)positiveButton
{
	void *pool = objc_autoreleasePoolPush();
	OFString *name;

	@try {
		name = [OFString stringWithFormat:
		    @"%@ and %@ as emulated axis",
		    negativeButton.name, positiveButton.name];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	self = [super oh_initWithName: name analog: false];

	objc_autoreleasePoolPop(pool);

	_negativeButton = [negativeButton retain];
	_positiveButton = [positiveButton retain];

	return self;
}

- (void)dealloc
{
	[_negativeButton release];
	[_positiveButton release];

	[super dealloc];
}

- (void)setValue: (float)value
{
	OF_UNRECOGNIZED_SELECTOR
}

- (float)value
{
	if (_negativeButton.pressed && _positiveButton.pressed)
		return -0;
	if (_negativeButton.pressed)
		return -1;
	if (_positiveButton.pressed)
		return 1;

	return 0;
}
@end
