/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019, 2020
 *   Jonathan Schleifer <js@nil.im>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#import "OFZIPArchive.h"

OF_ASSUME_NONNULL_BEGIN

@interface OFZIPArchiveEntry ()
@property (readonly, nonatomic)
    uint16_t of_lastModifiedFileTime, of_lastModifiedFileDate;
@property (readonly, nonatomic) int64_t of_localFileHeaderOffset;

- (instancetype)of_initWithStream: (OFStream *)stream
    OF_METHOD_FAMILY(init) OF_DIRECT;
- (uint64_t)of_writeToStream: (OFStream *)stream OF_DIRECT;
@end

@interface OFMutableZIPArchiveEntry ()
@property (readwrite, nonatomic, setter=of_setLocalFileHeaderOffset:)
    int64_t of_localFileHeaderOffset;
@end

OF_ASSUME_NONNULL_END
