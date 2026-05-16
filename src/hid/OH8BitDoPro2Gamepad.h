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

#import "OHExtendedGamepad.h"
#import "OHVIDPID.h"

OF_ASSUME_NONNULL_BEGIN

/**
 * @class OH8BitDoPro2Gamepad OH8BitDoPro2Gamepad.h ObjFWHID/ObjFWHID.h
 *
 * @brief An 8BitDo Pro 2 gamepad.
 */
OF_SUBCLASSING_RESTRICTED
@interface OH8BitDoPro2Gamepad: OFObject <OHExtendedGamepad>
{
	OFDictionary OF_GENERIC(OFString *, OF_KINDOF(OHGameControllerButton *))
	    *_buttons;
	OFDictionary OF_GENERIC(OFString *, OHGameControllerDirectionalPad *)
	    *_directionalPads;
	OHVIDPID _VIDPID;
}

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
