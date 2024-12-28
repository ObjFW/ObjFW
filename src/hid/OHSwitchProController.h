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

#import "OHExtendedGamepad.h"

OF_ASSUME_NONNULL_BEGIN

@class NSString;

/**
 * @class OHSwitchProController OHSwitchProController.h ObjFWHID/ObjFWHID.h
 *
 * @brief A Nintendo Switch Pro Controller.
 */
OF_SUBCLASSING_RESTRICTED
@interface OHSwitchProController: OFObject <OHExtendedGamepad>
{
	OFDictionary OF_GENERIC(OFString *, OF_KINDOF(OHGameControllerButton *))
	    *_buttons;
	OFDictionary OF_GENERIC(OFString *, OHGameControllerDirectionalPad *)
	    *_directionalPads;
	/* Only used with GameController.framework */
	OFDictionary OF_GENERIC(NSString *, OHGameControllerButton *)
	    *_buttonsMap;
	OFDictionary OF_GENERIC(NSString *, OHGameControllerDirectionalPad *)
	    *_directionalPadsMap;
}

- (instancetype)init OF_UNAVAILABLE;
@end

OF_ASSUME_NONNULL_END
