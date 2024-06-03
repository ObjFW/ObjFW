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

OF_ASSUME_NONNULL_BEGIN

@class OHGameControllerMapping;

@interface OHEvdevGameController: OHGameController
{
	OFString *_path;
	int _fd;
	bool _discardUntilReport;
	unsigned long *_evBits, *_keyBits, *_absBits;
	uint16_t _vendorID, _productID;
	OFString *_name;
	OHGameControllerMapping *_mapping;
}

- (instancetype)of_initWithPath: (OFString *)path OF_METHOD_FAMILY(init);
- (void)of_pollState;
@end

OF_ASSUME_NONNULL_END
