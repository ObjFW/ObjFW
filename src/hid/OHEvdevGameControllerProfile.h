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

#import "OHEvdevGameController.h"
#import "OHGameControllerProfile.h"

OF_ASSUME_NONNULL_BEGIN

@interface OHEvdevGameControllerProfile: OFObject <OHGameControllerProfile,
    OHEvdevMapping>
{
	OFDictionary OF_GENERIC(OFString *, OF_KINDOF(OHGameControllerButton *))
	    *_buttons;
	OFDictionary OF_GENERIC(OFString *, OHGameControllerAxis *) *_axes;
	uint16_t _vendorID, _productID;
}

- (instancetype)init OF_UNAVAILABLE;

- (instancetype)oh_initWithKeyBits: (unsigned long *)keyBits
			    evBits: (unsigned long *)evBits
			   absBits: (unsigned long *)absBits
			  vendorID: (uint16_t)vendorID
			 productID: (uint16_t)productID
    OF_METHOD_FAMILY(init) OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
