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

#import "OHGameCubeController.h"

#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
# import "OHEvdevGameController.h"
#endif
#ifdef OF_HAVE_GCF
# import "OHGCFGameController.h"
#endif

OF_ASSUME_NONNULL_BEGIN

OF_DIRECT_MEMBERS
@interface OHGameCubeController ()
#if defined(OF_LINUX) && defined(OF_HAVE_FILES)
    <OHEvdevMapping>
#endif
#ifdef OF_HAVE_GCF
    <OHGCFMapping>
#endif

- (instancetype)oh_init OF_METHOD_FAMILY(init);
@end

OF_ASSUME_NONNULL_END
