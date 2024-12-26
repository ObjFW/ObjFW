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

@class GCController;
@class OFSet<ObjectType>;
@class OHGCFGameControllerProfile;

__attribute__((__availability__(macOS, introduced=14.0)))
__attribute__((__availability__(iOS, introduced=17.0)))
@protocol OHGCFMapping <OFObject>
@property (readonly, nonatomic)
    OFDictionary<NSString *, OHGameControllerButton *> *oh_buttonsMap;
@property (readonly, nonatomic)
    OFDictionary<NSString *, OHGameControllerAxis *> *oh_axesMap;
@property (readonly, nonatomic) OFDictionary<NSString *,
    OHGameControllerDirectionalPad *> *oh_directionalPadsMap;
@optional
@property (readonly, nonatomic) OFSet<NSString *> *oh_filteredButtons;
@end

__attribute__((__availability__(macOS, introduced=14.0)))
__attribute__((__availability__(iOS, introduced=17.0)))
@interface OHGCFGameController: OHGameController
{
	GCController *_controller;
	OFString *_name;
	id <OHGameControllerProfile, OHGCFMapping> _profile;
}

- (instancetype)oh_init OF_UNAVAILABLE;
- (instancetype)oh_initWithGCController: (GCController *)controller
    OF_METHOD_FAMILY(init);
@end

OF_ASSUME_NONNULL_END
