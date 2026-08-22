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

#import "OHGameController.h"

#include <exec/types.h>

OF_ASSUME_NONNULL_BEGIN

OF_SUBCLASSING_RESTRICTED
@interface OHSensorsLibraryGameController: OHGameController
{
	APTR _sensor;
	struct OHSensorsList *_Nonnull _sensorsList;
	OFString *_Nonnull _name;
	APTR _childSensorsList;
	id <OHGameControllerProfile> _Nonnull _profile;
}

- (instancetype)oh_init OF_UNAVAILABLE;
- (instancetype)oh_initWithSensor: (APTR)sensor
		      sensorsList: (struct OHSensorsList *)sensorsList
    OF_METHOD_FAMILY(init);
@end

OF_ASSUME_NONNULL_END
