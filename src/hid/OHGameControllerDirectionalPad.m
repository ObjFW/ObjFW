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

#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerDirectionalPad+Private.h"
#import "OFNotification.h"
#import "OFNotificationCenter.h"
#import "OHEmulatedGameControllerAxis.h"
#import "OHEmulatedGameControllerButton.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"

const OFNotificationName
    OHGameControllerDirectionalPadValueDidChangeNotification =
    @"OHGameControllerDirectionalPadValueDidChangeNotification";

@interface OHGameControllerDirectionalPad ()
- (void)oh_valueDidChange: (OFNotification *)notification;
@end

@implementation OHGameControllerDirectionalPad
@synthesize xAxis = _xAxis, yAxis = _yAxis;
@synthesize up = _up, down = _down, left = _left, right = _right;

+ (instancetype)oh_padWithName: (OFString *)name
			 xAxis: (OHGameControllerAxis *)xAxis
			 yAxis: (OHGameControllerAxis *)yAxis
			analog: (bool)analog
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] oh_initWithName: name
				    xAxis: xAxis
				    yAxis: yAxis
				   analog: analog]);
}

+ (instancetype)oh_padWithName: (OFString *)name
			    up: (OHGameControllerButton *)up
			  down: (OHGameControllerButton *)down
			  left: (OHGameControllerButton *)left
			 right: (OHGameControllerButton *)right
			analog: (bool)analog
{
	return objc_autoreleaseReturnValue(
	    [[self alloc] oh_initWithName: name
				       up: up
				     down: down
				     left: left
				    right: right
				   analog: analog]);
}

- (instancetype)oh_initWithName: (OFString *)name analog: (bool)analog
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)oh_initWithName: (OFString *)name
			  xAxis: (OHGameControllerAxis *)xAxis
			  yAxis: (OHGameControllerAxis *)yAxis
			 analog: (bool)analog
{
	self = [super oh_initWithName: name analog: analog];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFNotificationCenter *notificationCenter;
		OFNotificationName notificationName;

		_xAxis = objc_retain(xAxis);
		_yAxis = objc_retain(yAxis);
		_type = OHGameControllerDirectionalPadTypeAxes;

		_up = [[OHEmulatedGameControllerButton alloc]
		    oh_initWithAxis: _yAxis
			   positive: false];
		_down = [[OHEmulatedGameControllerButton alloc]
		    oh_initWithAxis: _yAxis
			   positive: true];
		_left = [[OHEmulatedGameControllerButton alloc]
		    oh_initWithAxis: _xAxis
			   positive: false];
		_right = [[OHEmulatedGameControllerButton alloc]
		    oh_initWithAxis: _xAxis
			   positive: true];

		notificationCenter = [OFNotificationCenter defaultCenter];
		notificationName =
		    OHGameControllerAxisValueDidChangeNotification;
		[notificationCenter addObserver: self
				       selector: @selector(oh_valueDidChange:)
					   name: notificationName
					 object: _xAxis];
		[notificationCenter addObserver: self
				       selector: @selector(oh_valueDidChange:)
					   name: notificationName
					 object: _yAxis];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (instancetype)oh_initWithName: (OFString *)name
			     up: (OHGameControllerButton *)up
			   down: (OHGameControllerButton *)down
			   left: (OHGameControllerButton *)left
			  right: (OHGameControllerButton *)right
			 analog: (bool)analog
{
	self = [super oh_initWithName: name analog: analog];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFNotificationCenter *notificationCenter;
		OFNotificationName notificationName;

		_up = objc_retain(up);
		_down = objc_retain(down);
		_left = objc_retain(left);
		_right = objc_retain(right);
		_type = OHGameControllerDirectionalPadTypeButtons;

		_xAxis = [[OHEmulatedGameControllerAxis alloc]
		    oh_initWithNegativeButton: _left
			       positiveButton: _right];
		_yAxis = [[OHEmulatedGameControllerAxis alloc]
		    oh_initWithNegativeButton: _up
			       positiveButton: _down];

		notificationCenter = [OFNotificationCenter defaultCenter];
		notificationName =
		    OHGameControllerButtonValueDidChangeNotification;
		[notificationCenter addObserver: self
				       selector: @selector(oh_valueDidChange:)
					   name: notificationName
					 object: _up];
		[notificationCenter addObserver: self
				       selector: @selector(oh_valueDidChange:)
					   name: notificationName
					 object: _down];
		[notificationCenter addObserver: self
				       selector: @selector(oh_valueDidChange:)
					   name: notificationName
					 object: _left];
		[notificationCenter addObserver: self
				       selector: @selector(oh_valueDidChange:)
					   name: notificationName
					 object: _right];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	void *pool = objc_autoreleasePoolPush();
	OFNotificationCenter *center = [OFNotificationCenter defaultCenter];
	OFNotificationName name;

	switch (_type) {
	case OHGameControllerDirectionalPadTypeAxes:
		name = OHGameControllerAxisValueDidChangeNotification;
		[center removeObserver: self
			      selector: @selector(oh_valueDidChange:)
				  name: name
				object: _xAxis];
		[center removeObserver: self
			      selector: @selector(oh_valueDidChange:)
				  name: name
				object: _yAxis];
		break;
	case OHGameControllerDirectionalPadTypeButtons:
		name = OHGameControllerButtonValueDidChangeNotification;
		[center removeObserver: self
			      selector: @selector(oh_valueDidChange:)
				  name: name
				object: _up];
		[center removeObserver: self
			      selector: @selector(oh_valueDidChange:)
				  name: name
				object: _down];
		[center removeObserver: self
			      selector: @selector(oh_valueDidChange:)
				  name: name
				object: _left];
		[center removeObserver: self
			      selector: @selector(oh_valueDidChange:)
				  name: name
				object: _right];
		break;
	}

	objc_autoreleasePoolPop(pool);

	objc_release(_xAxis);
	objc_release(_yAxis);
	objc_release(_up);
	objc_release(_down);
	objc_release(_left);
	objc_release(_right);

	[super dealloc];
}

- (void)oh_valueDidChange: (OFNotification *)notification
{
	OFNotificationName name =
	    OHGameControllerDirectionalPadValueDidChangeNotification;

	notification = [OFNotification notificationWithName: name
						     object: self];
	[[OFNotificationCenter defaultCenter] postNotification: notification];
}

- (OFString *)description
{
	return [OFString stringWithFormat: @"<%@: %@>", self.class, self.name];
}
@end
