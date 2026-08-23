/*
 * Copyright (c) 2008-2026 Jonathan Schleifer <js@nil.im>
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

#include "config.h"

#import "OHSensorsLibraryGameControllerProfile.h"
#import "OFDictionary.h"
#import "OFLocale.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerButton+Private.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerDirectionalPad+Private.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"

#define USE_INLINE_STDARG
#include <proto/exec.h>
#include <ppcinline/sensors.h>
#include <ppcinline/utility.h>
#include <libraries/sensors.h>
#include <libraries/sensors_hid.h>

#import "OFInitializationFailedException.h"

extern struct Library *SensorsBase, *UtilityBase;

static void
addButton(OFMutableDictionary *buttons, OFString *name, bool analog,
    APTR sensor, struct MsgPort *port)
{
	if ([name hasSuffix: @" Button"])
		name = [name substringToIndex: name.length - 7];

	if ([name isEqual: @"Shoulder Button Left"])
		name = @"LB";
	else if ([name isEqual: @"Shoulder Button Right"])
		name = @"RB";
	else if ([name isEqual: @"Left Analog Trigger"])
		name = @"LT";
	else if ([name isEqual: @"Right Analog Trigger"])
		name = @"RT";
	else if ([name isEqual: @"Left Analog Joystick Push"])
		name = @"LSB";
	else if ([name isEqual: @"Right Analog Joystick Push"])
		name = @"RSB";
	else if ([name isEqual: @"Xbox"])
		name = @"Guide";

	OHGameControllerButton *button = [OHGameControllerButton
	    oh_elementWithName: name
			analog: analog];

	[buttons setObject: button forKey: name];

	button.oh_notifier = StartSensorNotifyTags(sensor,
	    SENSORS_Notification_UserData, (IPTR)button,
	    SENSORS_Notification_Destination, (IPTR)port,
	    SENSORS_Notification_SendInitialValue, TRUE,
	    SENSORS_HIDInput_Value, 1, TAG_END);
}

static void
addDirectionalPad(OFMutableDictionary *directionalPads, OFString *name,
    bool analog, APTR sensor, struct MsgPort *port)
{
	if ([name isEqual: @"Left Analog Joystick"])
		name = @"Left Thumbstick";
	else if ([name isEqual: @"Right Analog Joystick"])
		name = @"Right Thumbstick";
	else if ([name isEqual: @"Left Digital Joystick"])
		name = @"D-Pad";

	OHGameControllerAxis *xAxis = [OHGameControllerAxis
	    oh_elementWithName: [name stringByAppendingString: @" X"]
			analog: analog];
	OHGameControllerAxis *yAxis = [OHGameControllerAxis
	    oh_elementWithName: [name stringByAppendingString: @" Y"]
			analog: analog];
	OHGameControllerDirectionalPad *directionalPad =
	    [OHGameControllerDirectionalPad oh_padWithName: name
						     xAxis: xAxis
						     yAxis: yAxis
						    analog: analog];

	[directionalPads setObject: directionalPad forKey: name];

	directionalPad.oh_notifier = StartSensorNotifyTags(sensor,
	    SENSORS_Notification_UserData, (IPTR)directionalPad,
	    SENSORS_Notification_Destination, (IPTR)port,
	    SENSORS_Notification_SendInitialValue, TRUE,
	    SENSORS_HIDInput_EW_Value, 1,
	    SENSORS_HIDInput_NS_Value, 1, TAG_END);
}

@implementation OHSensorsLibraryGameControllerProfile
@synthesize buttons = _buttons, directionalPads = _directionalPads;

- (instancetype)init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)oh_initWithSensorsList: (APTR)list
{
	self = [super init];

	@try {
		void *pool = objc_autoreleasePoolPush();
		OFMutableDictionary *buttons = [OFMutableDictionary dictionary];
		OFMutableDictionary *directionalPads =
		    [OFMutableDictionary dictionary];
		OFMutableDictionary *mapping = [OFMutableDictionary dictionary];
		OFStringEncoding encoding = [OFLocale encoding];

		if ((_port = CreateMsgPort()) == NULL)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		APTR sensor = NULL;
		while ((sensor = NextSensor(sensor, list, NULL)) != NULL) {
			ULONG type = 0;
			STRPTR nameC = NULL;
			GetSensorAttrTags(sensor, SENSORS_Type, (IPTR)&type,
			    SENSORS_HIDInput_Name, (IPTR)&nameC, TAG_END);

			if (nameC == NULL)
				continue;

			OFString *name = [OFString stringWithCString: nameC
							    encoding: encoding];

			switch (type) {
			case SensorType_HIDInput_Trigger:
				addButton(buttons, name, false, sensor, _port);
				break;
			case SensorType_HIDInput_Analog:
				addButton(buttons, name, true, sensor, _port);
				break;
			case SensorType_HIDInput_Stick:
				addDirectionalPad(directionalPads, name, false,
				    sensor, _port);
				break;
			case SensorType_HIDInput_AnalogStick:
				addDirectionalPad(directionalPads, name, true,
				    sensor, _port);
				break;
			}
		}
		[buttons makeImmutable];
		[directionalPads makeImmutable];
		[mapping makeImmutable];

		_buttons = [buttons copy];
		_directionalPads = [directionalPads copy];
		_mapping = [mapping copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	if (_port != NULL)
		DeleteMsgPort(_port);

	objc_release(_buttons);
	objc_release(_directionalPads);
	objc_release(_mapping);

	[super dealloc];
}

- (OFDictionary OF_GENERIC(OFString *, OHGameControllerAxis *) *)axes
{
	return [OFDictionary dictionary];
}

- (struct MsgPort *)oh_port
{
	return _port;
}

- (void)oh_didReceiveSignal: (ULONG)signal
{
	struct SensorsNotificationMessage *msg;
	while ((msg = (struct SensorsNotificationMessage *)GetMsg(_port)) !=
	    NULL) {
		id object = (id)msg->UserData;
		if (object == nil)
			continue;

		struct TagItem *tags = msg->Notifications, *iter;
		while ((iter = NextTagItem(&tags)) != NULL) {
			if (iter->ti_Tag == SENSORS_HIDInput_Value)
				[object setValue: *(DOUBLE *)iter->ti_Data];
			else if (iter->ti_Tag == SENSORS_HIDInput_EW_Value)
				[[object xAxis]
				    setValue: *(DOUBLE *)iter->ti_Data];
			else if (iter->ti_Tag == SENSORS_HIDInput_NS_Value)
				[[object yAxis]
				    setValue: *(DOUBLE *)iter->ti_Data];
		}

		ReplyMsg(&msg->Msg);
	}
}
@end
