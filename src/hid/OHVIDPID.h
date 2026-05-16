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
# import "macros.h"
#else
# if defined(__has_feature) && __has_feature(modules)
@import ObjFW;
# else
#  import <ObjFW/macros.h>
# endif
#endif

OF_ASSUME_NONNULL_BEGIN

typedef struct OF_BOXABLE OHVIDPID {
	uint16_t vendorID;
	uint16_t productID;
} OHVIDPID;

static OF_INLINE bool
OHEqualVIDPIDs(OHVIDPID VIDPID1, OHVIDPID VIDPID2)
{
	if (VIDPID1.vendorID != VIDPID2.vendorID)
		return false;

	if (VIDPID1.productID != VIDPID2.productID)
		return false;

	return true;
}

#ifdef __cplusplus
extern "C" {
#endif
extern const OHVIDPID OHVIDPIDXbox360WirelessReceiver;

extern const OHVIDPID OHVIDPIDSonyDualShock4;
extern const OHVIDPID OHVIDPIDSonyDualSense;
extern const OHVIDPID OHVIDPIDSonyPlayStation3Controller;

extern const OHVIDPID OHVIDPIDLeftNintendoJoyCon;
extern const OHVIDPID OHVIDPIDRightNintendoJoyCon;
extern const OHVIDPID OHVIDPIDNintendoSwitchProController;
extern const OHVIDPID OHVIDPIDNintendo64Controller;
extern const OHVIDPID OHVIDPIDSuperNintendoController;

extern const OHVIDPID OHVIDPIDStadiaController;

extern const OHVIDPID OHVIDPID8BitDoNES30Gamepad;
extern const OHVIDPID OHVIDPID8BitDoUltimate2CWirelessBT;
extern const OHVIDPID OHVIDPID8BitDoUltimate2CWirelessUSB;
extern const OHVIDPID OHVIDPID8BitDoPro2;

extern const OHVIDPID OHVIDPIDDragonRiseGameCubeControllerAdapter;
extern const OHVIDPID OHVIDPIDWiseGroupPlayStationControllerAdapter;
extern const OHVIDPID OHVIDPIDMocute053X;
#ifdef __cplusplus
}
#endif

OF_ASSUME_NONNULL_END
