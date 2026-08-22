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

#import "OHSensorsLibraryGameController.h"
#import "OFArray.h"
#import "OHGameController.h"
#import "OHGameController+Private.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OFLocale.h"

#import "OFInitializationFailedException.h"

#define USE_INLINE_STDARG
#include <proto/exec.h>
#include <ppcinline/sensors.h>
#include <libraries/sensors.h>
#include <libraries/sensors_hid.h>

struct Library *SensorsBase;

struct OHSensorsList {
	APTR sensors;
	int retainCount;
};

OF_DESTRUCTOR()
{
	if (SensorsBase != NULL)
		CloseLibrary(SensorsBase);
}

static struct OHSensorsList *
OHRetainSensorsList(struct OHSensorsList *list)
{
	Forbid();
	list->retainCount++;
	Permit();

	return list;
}

static void
OHReleaseSensorsList(struct OHSensorsList *list)
{
	Forbid();
	bool release = (--list->retainCount == 0);
	Permit();

	if (release) {
		if (list->sensors != NULL)
			ReleaseSensorsList(list->sensors, NULL);

		OFFreeMemory(list);
	}
}

@implementation OHSensorsLibraryGameController
@synthesize name = _name;

+ (void)initialize
{
	if (self != [OHSensorsLibraryGameController class])
		return;

	if ((SensorsBase = OpenLibrary("sensors.library", 53)) == NULL)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];
}

+ (OFArray OF_GENERIC(OHGameController *) *)controllers
{
	OFMutableArray *controllers = [OFMutableArray array];

	struct OHSensorsList *list = OFAllocMemory(1, sizeof(*list));
	list->sensors = ObtainSensorsListTags(SENSORS_Class, SensorClass_HID,
	    SENSORS_Type, SensorType_HID_Gamepad, TAG_END);
	list->retainCount = 1;

	@try {
		if (list->sensors == NULL) {
			[controllers makeImmutable];
			return controllers;
		}

		APTR sensor = NULL;
		while ((sensor = NextSensor(sensor, list->sensors, NULL)) !=
		    NULL)
			[controllers addObject: objc_autorelease(
			    [[OHSensorsLibraryGameController alloc]
			    oh_initWithSensor: (APTR)sensor
				  sensorsList: list])];
	} @finally {
		OHReleaseSensorsList(list);
	}

	[controllers makeImmutable];

	return controllers;
}

- (instancetype)oh_init
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)oh_initWithSensor: (APTR)sensor
		      sensorsList: (struct OHSensorsList *)sensorsList
{
	self = [super oh_init];

	@try {
		_sensor = sensor;
		_sensorsList = OHRetainSensorsList(sensorsList);

		STRPTR name;
		if (GetSensorAttrTags(_sensor, SENSORS_HID_Name, (IPTR)&name,
		    TAG_END) < 1)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		_name = [[OFString alloc] initWithCString: name
						 encoding: [OFLocale encoding]];
	} @catch (id e) {
		objc_release(self);
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	OHReleaseSensorsList(_sensorsList);
	objc_release(_name);

	[super dealloc];
}
@end
