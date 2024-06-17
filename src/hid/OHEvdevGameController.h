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

#import "OHGameController.h"
#import "OHGameControllerProfile.h"

OF_ASSUME_NONNULL_BEGIN

@protocol OHEvdevMapping <OFObject>
- (OHGameControllerButton *)oh_buttonForEvdevButton: (uint16_t)button;
- (OHGameControllerAxis *)oh_axisForEvdevAxis: (uint16_t)axis;
@end

@interface OHEvdevGameController: OHGameController
{
	OFString *_path;
	int _fd;
	bool _discardUntilReport;
	unsigned long *_evBits, *_keyBits, *_absBits;
	uint16_t _vendorID, _productID;
	OFString *_name;
	id <OHGameControllerProfile, OHEvdevMapping> _profile;
}

- (instancetype)initWithPath: (OFString *)path;
- (void)oh_pollState;
@end

extern const uint16_t OHEvdevButtonIDs[];
extern const size_t OHNumEvdevButtonIDs;
extern const uint16_t OHEvdevAxisIDs[];
extern const size_t OHNumEvdevAxisIDs;

OF_ASSUME_NONNULL_END
