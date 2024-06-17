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

#import "OHGameControllerAxis.h"

OF_ASSUME_NONNULL_BEGIN

@class OHGameControllerButton;

OF_SUBCLASSING_RESTRICTED
@interface OHEmulatedGameControllerAxis: OHGameControllerAxis
{
	OHGameControllerButton *_negativeButton, *_positiveButton;
}

- (instancetype)initWithName: (OFString *)name OF_UNAVAILABLE;
- (instancetype)
    initWithNegativeButton: (OHGameControllerButton *)negativeButton
	    positiveButton: (OHGameControllerButton *)positiveButton;
@end

OF_ASSUME_NONNULL_END
