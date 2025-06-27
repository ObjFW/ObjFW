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

#import "OHGameControllerElement.h"

#ifdef OBJFWHID_LOCAL_INCLUDES
# import "OFNotification.h"
#else
# if defined(__has_feature) && __has_feature(modules)
@import ObjFW;
# else
#  import <ObjFW/OFNotification.h>
# endif
#endif

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OHGameControllerAxis OHGameControllerAxis.h ObjFWHID/ObjFWHID.h
 *
 * @brief An axis of a game controller.
 */
@interface OHGameControllerAxis: OHGameControllerElement
{
	float _value;
#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
	int32_t _minRawValue, _maxRawValue;
	uintptr_t _inverted;	/* Change to a smaller type on ABI bump */
#endif
	OF_RESERVE_IVARS(OHGameControllerButton, 3)
}

/**
 * @brief The value of the axis.
 */
@property (nonatomic) float value;
@end

#ifdef __cplusplus
extern "C" {
#endif
/**
* @brief A notification that will be sent when an axis value changed.
*/
extern const OFNotificationName OHGameControllerAxisValueDidChangeNotification;
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
