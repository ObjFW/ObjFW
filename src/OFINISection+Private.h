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

#import "OFINISection.h"
#import "OFString.h"

OF_ASSUME_NONNULL_BEGIN

@class OFStream;

OF_DIRECT_MEMBERS
@interface OFINISection ()
- (instancetype)of_initWithName: (OFString *)name OF_METHOD_FAMILY(init);
- (void)of_parseLine: (OFString *)line;
- (bool)of_writeToStream: (OFStream *)stream first: (bool)first;
@end

OF_ASSUME_NONNULL_END
