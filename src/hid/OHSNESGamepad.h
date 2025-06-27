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

#import "OHGameControllerProfile.h"
#import "OHGamepad.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OHSNESGamepad OHSNESGamepad.h ObjFWHID/ObjFWHID.h
 *
 * @brief A Super Nintendo gamepad.
 */
@interface OHSNESGamepad: OFObject <OHGamepad>
{
	OFDictionary OF_GENERIC(OFString *, OF_KINDOF(OHGameControllerButton *))
	    *_buttons;
	OFDictionary OF_GENERIC(OFString *, OHGameControllerDirectionalPad *)
	    *_directionalPads;
	OF_RESERVE_IVARS(OHSNESGamepad, 4)
}

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
