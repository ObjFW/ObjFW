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

#ifdef OBJFWHID_LOCAL_INCLUDES
# import "OFObject.h"
# import "OFString.h"
#else
# if defined(__has_feature) && __has_feature(modules)
@import ObjFW;
# else
#  import <ObjFW/OFObject.h>
#  import <ObjFW/OFString.h>
# endif
#endif

#import "OHGamepad.h"
#import "OHExtendedGamepad.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFNumber;
@class OHGameControllerProfile;

/**
 * @class OHGameController OHGameController.h ObjFWHID/ObjFWHID.h
 *
 * @brief A class for reading state from a game controller.
 */
@interface OHGameController: OFObject
{
	OF_RESERVE_IVARS(OHGameController, 4)
}

#ifdef OF_HAVE_CLASS_PROPERTIES
@property (class, readonly, nonatomic)
    OFArray <OHGameController *> *controllers;
#endif

/**
 * @brief The name of the controller.
 */
@property (readonly, nonatomic, copy) OFString *name;

/**
 * @brief The vendor ID of the controller or `nil` if unavailable.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFNumber *vendorID;

/**
 * @brief The product ID of the controller or `nil` if unavailable.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) OFNumber *productID;

/**
 * @brief The profile for the game controller.
 */
@property (readonly, nonatomic) id <OHGameControllerProfile> profile;

/**
 * @brief The gamepad profile for the game controller, or `nil` if not
 *	  supported.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) id <OHGamepad> gamepad;

/**
 * @brief The extended gamepad profile for the game controller, or `nil` if not
 *	  supported.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic)
    id <OHExtendedGamepad> extendedGamepad;

/**
 * @brief Returns the available controllers.
 *
 * @return The available controllers
 */
+ (OFArray OF_GENERIC(OHGameController *) *)controllers;

- (instancetype)init OF_UNAVAILABLE;

/**
 * @brief Updates the current state from the game controller.
 *
 * The state returned by @ref OHGameController's methods does not change until
 * this method is called.
 *
 * @throw OFReadFailedException The controller's state could not be read
 */
- (void)updateState;
@end

#ifdef __cplusplus
extern "C" {
#endif
extern const uint16_t OHVendorIDSony;
extern const uint16_t OHVendorIDNintendo;
extern const uint16_t OHVendorIDMicrosoft;
extern const uint16_t OHVendorIDGoogle;
extern const uint16_t OHVendorID8BitDo;
extern const uint16_t OHVendorIDDragonRise;
extern const uint16_t OHVendorIDWiseGroup;

extern const uint16_t OHProductIDDualShock4;
extern const uint16_t OHProductIDDualSense;
extern const uint16_t OHProductIDPlayStation3Controller;
extern const uint16_t OHProductIDLeftJoyCon;
extern const uint16_t OHProductIDRightJoyCon;
extern const uint16_t OHProductIDProController;
extern const uint16_t OHProductIDN64Controller;
extern const uint16_t OHProductIDSNESController;
extern const uint16_t OHProductIDXbox360WirelessReceiver;
extern const uint16_t OHProductIDStadiaController;
extern const uint16_t OHProductIDNES30Gamepad;
extern const uint16_t OHProductIDUltimate2CWirelessBT;
extern const uint16_t OHProductIDUltimate2CWirelessUSB;
extern const uint16_t OHProductIDGameCubeControllerAdapter;
extern const uint16_t OHProductIDPlayStationControllerAdapter;
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
