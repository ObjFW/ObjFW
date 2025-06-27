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

#import <GameController/GameController.h>

#import "OHGameControllerProfile.h"
#import "OHGCFGameController.h"

OF_ASSUME_NONNULL_BEGIN

@class GCControllerLiveInput;

__attribute__((__availability__(macOS, introduced=14.0)))
__attribute__((__availability__(iOS, introduced=17.0)))
@interface OHGCFGameControllerProfile: OFObject <OHGameControllerProfile,
    OHGCFMapping>
{
	OFDictionary<OFString *, OHGameControllerButton *> *_buttons;
	OFDictionary<OFString *, OHGameControllerAxis *> *_axes;
	OFDictionary<OFString *, OHGameControllerDirectionalPad *>
	    *_directionalPads;
	OFDictionary<OFString *, NSString *> *_buttonsMap;
	OFDictionary<OFString *, NSString *> *_axesMap;
	OFDictionary<OFString *, NSString *> *_directionalPadsMap;
}

- (instancetype)init OF_UNAVAILABLE;
- (instancetype)oh_initWithLiveInput: (GCControllerLiveInput *)liveInput
    OF_METHOD_FAMILY(init);
@end

OF_ASSUME_NONNULL_END
