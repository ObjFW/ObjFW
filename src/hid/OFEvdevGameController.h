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

#import "OFGameController.h"

OF_ASSUME_NONNULL_BEGIN

@interface OFEvdevGameController: OFGameController
{
	OFString *_path;
	int _fd;
	bool _discardUntilReport;
	unsigned long *_keyBits;
	bool _DPadIsHAT0;
	uint16_t _vendorID, _productID;
	OFString *_name;
	OFMutableSet OF_GENERIC(OFGameControllerButton) *_buttons;
	OFMutableSet OF_GENERIC(OFGameControllerButton) *_pressedButtons;
	bool _hasLeftAnalogStick, _hasRightAnalogStick;
	bool _hasLeftTriggerPressure, _hasRightTriggerPressure;
	unsigned int _leftTriggerPressureBit, _rightTriggerPressureBit;
	OFPoint _leftAnalogStickPosition, _rightAnalogStickPosition;
	float _leftTriggerPressure, _rightTriggerPressure;
	int32_t _leftAnalogStickMinX, _leftAnalogStickMaxX;
	int32_t _leftAnalogStickMinY, _leftAnalogStickMaxY;
	unsigned int _rightAnalogStickXBit, _rightAnalogStickYBit;
	int32_t _rightAnalogStickMinX, _rightAnalogStickMaxX;
	int32_t _rightAnalogStickMinY, _rightAnalogStickMaxY;
	int32_t _leftTriggerMinPressure, _leftTriggerMaxPressure;
	int32_t _rightTriggerMinPressure, _rightTriggerMaxPressure;
}

- (instancetype)of_initWithPath: (OFString *)path OF_METHOD_FAMILY(init);
- (void)of_pollState;
@end

OF_ASSUME_NONNULL_END
