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
#import "OHGameControllerDirectionalPad.h"
#import "OHGameControllerDirectionalPad+Private.h"
#import "OHGameControllerElement.h"
#import "OHGameControllerElement+Private.h"

#define USE_INLINE_STDARG
#include <proto/exec.h>
#include <ppcinline/sensors.h>
#include <libraries/sensors.h>
#include <libraries/sensors_hid.h>

#import "OFInitializationFailedException.h"

extern struct Library *SensorsBase;

static void
addButton(OFMutableDictionary *buttons, OFString *name, bool analog,
    APTR sensor)
{
	OHGameControllerButton *button = [OHGameControllerButton
	    oh_elementWithName: name
			analog: analog];

	[buttons setObject: button forKey: name];
}

static void
addDirectionalPad(OFMutableDictionary *directionalPads, OFString *name,
    bool analog, APTR sensor)
{
	OHGameControllerAxis *xAxis = [OHGameControllerAxis
	    oh_elementWithName: [name stringByAppendingString: @" X"]
			analog: analog];
	OHGameControllerAxis *yAxis = [OHGameControllerAxis
	    oh_elementWithName: [name stringByAppendingString: @" X"]
			analog: analog];
	OHGameControllerDirectionalPad *directionalPad =
	    [OHGameControllerDirectionalPad oh_padWithName: name
						     xAxis: xAxis
						     yAxis: yAxis
						    analog: analog];

	[directionalPads setObject: directionalPad forKey: name];
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
		OFStringEncoding encoding = [OFLocale encoding];

		APTR sensor = NULL;
		while ((sensor = NextSensor(sensor, list, NULL)) != NULL) {
			void *pool2 = objc_autoreleasePoolPush();

			ULONG type = 0;
			STRPTR nameC = NULL;
			GetSensorAttrTags(sensor, SENSORS_Type, (IPTR)&type,
			    SENSORS_HIDInput_Name, (IPTR)&nameC, TAG_END);

			if (nameC == NULL) {
				objc_autoreleasePoolPop(pool);
				continue;
			}

			OFString *name = [OFString stringWithCString: nameC
							    encoding: encoding];

			switch (type) {
			case SensorType_HIDInput_Trigger:
				addButton(buttons, name, false, sensor);
				break;
			case SensorType_HIDInput_Analog:
				addButton(buttons, name, false, sensor);
				break;
			case SensorType_HIDInput_Stick:
				addDirectionalPad(directionalPads, name, false,
				    sensor);
				break;
			case SensorType_HIDInput_AnalogStick:
				addDirectionalPad(directionalPads, name, true,
				    sensor);
				break;
			}

			objc_autoreleasePoolPop(pool2);
		}
		[buttons makeImmutable];
		[directionalPads makeImmutable];

		_buttons = [buttons copy];
		_directionalPads = [directionalPads copy];

		objc_autoreleasePoolPop(pool);
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	objc_release(_buttons);
	objc_release(_directionalPads);

	[super dealloc];
}

- (OFDictionary OF_GENERIC(OFString *, OHGameControllerAxis *) *)axes
{
	return [OFDictionary dictionary];
}
@end
