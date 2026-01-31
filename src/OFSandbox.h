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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

@class OFArray OF_GENERIC(ObjectType);
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFPair OF_GENERIC(FirstType, SecondType);

typedef OFPair OF_GENERIC(OFString *, OFString *) *OFSandboxUnveilPath;

OF_SUBCLASSING_RESTRICTED
@interface OFSandbox: OFObject <OFCopying>
{
	unsigned int _allowsStdIO: 1;
	unsigned int _allowsReadingFiles: 1;
	unsigned int _allowsWritingFiles: 1;
	unsigned int _allowsCreatingFiles: 1;
	unsigned int _allowsCreatingSpecialFiles: 1;
	unsigned int _allowsTemporaryFiles: 1;
	unsigned int _allowsIPSockets: 1;
	unsigned int _allowsMulticastSockets: 1;
	unsigned int _allowsChangingFileAttributes: 1;
	unsigned int _allowsFileOwnerChanges: 1;
	unsigned int _allowsFileLocks: 1;
	unsigned int _allowsUNIXSockets: 1;
	unsigned int _allowsDNS: 1;
	unsigned int _allowsUserDatabaseReading: 1;
	unsigned int _allowsFileDescriptorSending: 1;
	unsigned int _allowsFileDescriptorReceiving: 1;
	unsigned int _allowsTape: 1;
	unsigned int _allowsTTY: 1;
	unsigned int _allowsProcessOperations: 1;
	unsigned int _allowsExec: 1;
	unsigned int _allowsProtExec: 1;
	unsigned int _allowsSetTime: 1;
	unsigned int _allowsPS: 1;
	unsigned int _allowsVMInfo: 1;
	unsigned int _allowsChangingProcessRights: 1;
	unsigned int _allowsPF: 1;
	unsigned int _allowsAudio: 1;
	unsigned int _allowsBPF: 1;
	unsigned int _allowsUnveil: 1;
	unsigned int _returnsErrors: 1;
	OFMutableArray OF_GENERIC(OFSandboxUnveilPath) *_unveiledPaths;
@public
	size_t _unveiledPathsIndex;
}

@property (nonatomic) bool allowsStdIO;
@property (nonatomic) bool allowsReadingFiles;
@property (nonatomic) bool allowsWritingFiles;
@property (nonatomic) bool allowsCreatingFiles;
@property (nonatomic) bool allowsCreatingSpecialFiles;
@property (nonatomic) bool allowsTemporaryFiles;
@property (nonatomic) bool allowsIPSockets;
@property (nonatomic) bool allowsMulticastSockets;
@property (nonatomic) bool allowsChangingFileAttributes;
@property (nonatomic) bool allowsFileOwnerChanges;
@property (nonatomic) bool allowsFileLocks;
@property (nonatomic) bool allowsUNIXSockets;
@property (nonatomic) bool allowsDNS;
@property (nonatomic) bool allowsUserDatabaseReading;
@property (nonatomic) bool allowsFileDescriptorSending;
@property (nonatomic) bool allowsFileDescriptorReceiving;
@property (nonatomic) bool allowsTape;
@property (nonatomic) bool allowsTTY;
@property (nonatomic) bool allowsProcessOperations;
@property (nonatomic) bool allowsExec;
@property (nonatomic) bool allowsProtExec;
@property (nonatomic) bool allowsSetTime;
@property (nonatomic) bool allowsPS;
@property (nonatomic) bool allowsVMInfo;
@property (nonatomic) bool allowsChangingProcessRights;
@property (nonatomic) bool allowsPF;
@property (nonatomic) bool allowsAudio;
@property (nonatomic) bool allowsBPF;
@property (nonatomic) bool allowsUnveil;
@property (nonatomic) bool returnsErrors;
#ifdef OF_HAVE_PLEDGE
@property (readonly, nonatomic) OFString *pledgeString;
#endif
@property (readonly, nonatomic)
    OFArray OF_GENERIC(OFSandboxUnveilPath) *unveiledPaths;

+ (instancetype)sandbox;
- (void)unveilPath: (OFString *)path permissions: (OFString *)permissions;
@end

OF_ASSUME_NONNULL_END
