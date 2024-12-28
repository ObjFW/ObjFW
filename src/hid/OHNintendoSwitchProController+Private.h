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

#import "OHNintendoSwitchProController.h"

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# import "OHEvdevGameController.h"
#endif
#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
# import "OHGCFGameController.h"
#endif

OF_ASSUME_NONNULL_BEGIN

#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
@class GCGameControllerLiveInput;
#endif

@interface OHNintendoSwitchProController ()
#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
    <OHEvdevMapping>
#endif
#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
    <OHGCFMapping>
#endif

- (instancetype)oh_init OF_METHOD_FAMILY(init);
#ifdef HAVE_GAMECONTROLLER_GAMECONTROLLER_H
- (instancetype)oh_initWithLiveInput: (GCGameControllerLiveInput *)liveInput
    OF_METHOD_FAMILY(init)
    __attribute__((__availability__(macOS, introduced=14.0)))
    __attribute__((__availability__(iOS, introduced=17.0)));
#endif
@end

OF_ASSUME_NONNULL_END
