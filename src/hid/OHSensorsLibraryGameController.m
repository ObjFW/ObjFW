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
#import "OFDictionary.h"
#import "OFLocale.h"
#import "OHGameController.h"
#import "OHGameController+Private.h"
#import "OHGameControllerAxis.h"
#import "OHGameControllerButton.h"
#import "OHGameControllerDirectionalPad.h"
#import "OHSensorsLibraryExtendedGamepad.h"

#define USE_INLINE_STDARG
#include <proto/exec.h>
#include <libraries/poseidon.h>
#include <libraries/sensors.h>
#include <libraries/sensors_hid.h>
#include <ppcinline/poseidon.h>
#include <ppcinline/sensors.h>

#import "OFInitializationFailedException.h"

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
@synthesize name = _name, profile = _profile;

+ (void)initialize
{
	if (self != [OHSensorsLibraryGameController class])
		return;

	if ((SensorsBase = OpenLibrary("sensors.library", 53)) == NULL)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];

	struct Library *PsdBase = OpenLibrary("poseidon.library", 1);
	if (PsdBase == NULL)
		@throw [OFInitializationFailedException
		    exceptionWithClass: self];

	Forbid();

	struct List *classList;
	struct TagItem tags[] = {
		{ PA_ClassList, (IPTR)&classList },
		{ TAG_END }
	};
	psdGetAttrsA(PGA_STACK, NULL, tags);

	bool loadXBox360Class = true;
	for (struct Node *node = classList->lh_Head; node->ln_Succ != NULL;
	    node = node->ln_Succ) {
		if (strcmp(node->ln_Name, "xbox360.class") == 0) {
			loadXBox360Class = false;
			break;
		}
	}

	Permit();

	if (loadXBox360Class) {
		psdAddClass((STRPTR)"MOSSYS:Classes/USB/xbox360.class", 0);
		psdClassScan();
	}

	CloseLibrary(PsdBase);
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

		_childSensorsList = ObtainSensorsListTags(
		    SENSORS_Parent, (IPTR)_sensor,
		    SENSORS_Class, SensorClass_HID, TAG_END);
		if (_childSensorsList == NULL)
			@throw [OFInitializationFailedException
			    exceptionWithClass: self.class];

		_profile = [[OHSensorsLibraryExtendedGamepad alloc]
		    oh_initWithSensorsList: _childSensorsList];

		[self updateState];
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

	if (_childSensorsList != NULL)
		ReleaseSensorsList(_childSensorsList, NULL);

	objc_release(_profile);

	[super dealloc];
}

- (void)updateState
{
	void *pool = objc_autoreleasePoolPush();
	OFStringEncoding encoding = [OFLocale encoding];

	APTR sensor = NULL;
	while ((sensor = NextSensor(sensor, _childSensorsList, NULL)) != NULL) {
		ULONG type = 0;
		STRPTR nameC = NULL;
		DOUBLE value = 0.0, x = 0.0, y = 0.0;
		GetSensorAttrTags(sensor, SENSORS_Type, (IPTR)&type,
		    SENSORS_HIDInput_Name, (IPTR)&nameC,
		    SENSORS_HIDInput_Value, (IPTR)&value,
		    SENSORS_HIDInput_EW_Value, (IPTR)&x,
		    SENSORS_HIDInput_NS_Value, (IPTR)&y,
		    TAG_END);

		if (nameC == NULL)
			continue;

		OFString *name = [OFString stringWithCString: nameC
						    encoding: encoding];
		name = [_profile oh_mappedNameForName: name];

		switch (type) {
		case SensorType_HIDInput_Trigger:
		case SensorType_HIDInput_Analog:
			[[_profile.buttons objectForKey: name] setValue: value];
			break;
		case SensorType_HIDInput_Stick:
		case SensorType_HIDInput_AnalogStick:;
			OHGameControllerDirectionalPad *pad =
			    [_profile.directionalPads objectForKey: name];
			pad.xAxis.value = x;
			pad.yAxis.value = y;
			break;
		}
	}

	objc_autoreleasePoolPop(pool);
}
@end
