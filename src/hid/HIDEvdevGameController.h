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

#import "HIDGameController.h"

OF_ASSUME_NONNULL_BEGIN

@interface HIDEvdevGameController: HIDGameController
{
	OFString *_path;
	int _fd;
	bool _discardUntilReport;
	unsigned long *_evBits, *_keyBits, *_absBits;
	uint16_t _vendorID, _productID;
	OFString *_name;
	OFDictionary OF_GENERIC(OFString *, HIDGameControllerButton *)
	    *_buttons;
	OFDictionary OF_GENERIC(OFString *, HIDGameControllerAxis *) *_axes;
}

- (instancetype)of_initWithPath: (OFString *)path OF_METHOD_FAMILY(init);
- (void)of_pollState;
@end

OF_ASSUME_NONNULL_END
