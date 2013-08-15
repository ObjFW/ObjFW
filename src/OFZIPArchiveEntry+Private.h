/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013
 *   Jonathan Schleifer <js@webkeks.org>
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

#import "macros.h"

@interface OFZIPArchiveEntry (OF_PRIVATE_CATEGORY)
- (instancetype)OF_initWithFile: (OFFile*)file;
- (uint16_t)OF_madeWithVersion;
- (uint16_t)OF_minVersion;
- (uint16_t)OF_generalPurposeBitFlag;
- (uint16_t)OF_compressionMethod;
- (uint16_t)OF_lastModifiedFileTime;
- (uint16_t)OF_lastModifiedFileDate;
- (OFDataArray*)OF_extraFieldNoCopy;
- (uint16_t)OF_startDiskNumber;
- (uint16_t)OF_internalAttributes;
- (uint32_t)OF_externalAttributes;
- (uint32_t)OF_localFileHeaderOffset;
@end
