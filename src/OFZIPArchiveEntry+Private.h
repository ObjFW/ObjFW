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

#import "OFZIPArchive.h"

OF_ASSUME_NONNULL_BEGIN

OF_DIRECT_MEMBERS
@interface OFZIPArchiveEntry ()
@property (readonly, nonatomic)
    uint16_t of_lastModifiedFileTime, of_lastModifiedFileDate;
@property (nonatomic, setter=of_setStartDiskNumber:)
    uint32_t of_startDiskNumber;
@property (nonatomic, setter=of_setLocalFileHeaderOffset:)
    int64_t of_localFileHeaderOffset;

- (instancetype)of_init OF_METHOD_FAMILY(init);
- (instancetype)of_initWithStream: (OFStream *)stream OF_METHOD_FAMILY(init);
- (uint64_t)of_writeToStream: (OFStream *)stream;
@end

OF_ASSUME_NONNULL_END
