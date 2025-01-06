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

#import "OHGameControllerAxis.h"

OF_ASSUME_NONNULL_BEGIN

@interface OHGameControllerAxis ()
#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
@property (nonatomic, setter=oh_setMinRawValue:) int32_t oh_minRawValue;
@property (nonatomic, setter=oh_setMaxRawValue:) int32_t oh_maxRawValue;
@property (nonatomic, getter=oh_isInverted, setter=oh_setInverted:)
    bool oh_inverted;
#endif
@end

OF_ASSUME_NONNULL_END
