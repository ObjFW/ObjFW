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

#import "OHGameControllerDirectionalPad.h"
#import "OHEmulatedGameControllerAxis.h"
#import "OHEmulatedGameControllerButton.h"

@implementation OHGameControllerDirectionalPad
@synthesize xAxis = _xAxis, yAxis = _yAxis;
@synthesize up = _up, down = _down, left = _left, right = _right;

- (instancetype)initWithName: (OFString *)name
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithName: (OFString *)name
		       xAxis: (OHGameControllerAxis *)xAxis
		       yAxis: (OHGameControllerAxis *)yAxis
{
	self = [super initWithName: name];

	@try {
		_xAxis = [xAxis retain];
		_yAxis = [yAxis retain];

		_up = [[OHEmulatedGameControllerButton alloc]
		    initWithAxis: _yAxis
			positive: false];
		_down = [[OHEmulatedGameControllerButton alloc]
		    initWithAxis: _yAxis
			positive: true];
		_left = [[OHEmulatedGameControllerButton alloc]
		    initWithAxis: _xAxis
			positive: false];
		_right = [[OHEmulatedGameControllerButton alloc]
		    initWithAxis: _xAxis
			positive: true];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (instancetype)initWithName: (OFString *)name
			  up: (OHGameControllerButton *)up
			down: (OHGameControllerButton *)down
			left: (OHGameControllerButton *)left
		       right: (OHGameControllerButton *)right
{
	self = [super initWithName: name];

	@try {
		_up = [up retain];
		_down = [down retain];
		_left = [left retain];
		_right = [right retain];

		_xAxis = [[OHEmulatedGameControllerAxis alloc]
		    initWithNegativeButton: _left
			    positiveButton: _right];
		_yAxis = [[OHEmulatedGameControllerAxis alloc]
		    initWithNegativeButton: _up
			    positiveButton: _down];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_xAxis release];
	[_yAxis release];
	[_up release];
	[_down release];
	[_left release];
	[_right release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@>", self.class, self.name];
}
@end
