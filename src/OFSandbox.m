/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017
 *   Jonathan Schleifer <js@heap.zone>
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

#import "OFSandbox.h"
#import "OFString.h"
#import "OFArray.h"

@implementation OFSandbox
@synthesize allowsStdIO = _allowsStdIO;
@synthesize allowsReadingFiles = _allowsReadingFiles;
@synthesize allowsWritingFiles = _allowsWritingFiles;
@synthesize allowsCreatingFiles = _allowsCreatingFiles;
@synthesize allowsCreatingSpecialFiles = _allowsCreatingSpecialFiles;
@synthesize allowsTemporaryFiles = _allowsTemporaryFiles;
@synthesize allowsIPSockets = _allowsIPSockets;
@synthesize allowsMulticastSockets = _allowsMulticastSockets;
@synthesize allowsChangingFileAttributes = _allowsChangingFileAttributes;
@synthesize allowsFileOwnerChanges = _allowsFileOwnerChanges;
@synthesize allowsFileLocks = _allowsFileLocks;
@synthesize allowsUNIXSockets = _allowsUNIXSockets;
@synthesize allowsDNS = _allowsDNS;
@synthesize allowsUserDatabaseReading = _allowsUserDatabaseReading;
@synthesize allowsFileDescriptorSending = _allowsFileDescriptorSending;
@synthesize allowsFileDescriptorReceiving = _allowsFileDescriptorReceiving;
@synthesize allowsTape = _allowsTape;
@synthesize allowsTTY = _allowsTTY;
@synthesize allowsProcessOperations = _allowsProcessOperations;
@synthesize allowsExec = _allowsExec;
@synthesize allowsProtExec = _allowsProtExec;
@synthesize allowsSetTime = _allowsSetTime;
@synthesize allowsPS = _allowsPS;
@synthesize allowsVMInfo = _allowsVMInfo;
@synthesize allowsChangingProcessRights = _allowsChangingProcessRights;
@synthesize allowsPF = _allowsPF;
@synthesize allowsAudio = _allowsAudio;
@synthesize allowsBPF = _allowsBPF;

+ (instancetype)sandbox
{
	return [[[self alloc] init] autorelease];
}

- copy
{
	OFSandbox *copy = [[OFSandbox alloc] init];

	copy->_allowsStdIO = _allowsStdIO;
	copy->_allowsReadingFiles = _allowsReadingFiles;
	copy->_allowsWritingFiles = _allowsWritingFiles;
	copy->_allowsCreatingFiles = _allowsCreatingFiles;
	copy->_allowsCreatingSpecialFiles = _allowsCreatingSpecialFiles;
	copy->_allowsTemporaryFiles = _allowsTemporaryFiles;
	copy->_allowsIPSockets = _allowsIPSockets;
	copy->_allowsMulticastSockets = _allowsMulticastSockets;
	copy->_allowsChangingFileAttributes = _allowsChangingFileAttributes;
	copy->_allowsFileOwnerChanges = _allowsFileOwnerChanges;
	copy->_allowsFileLocks = _allowsFileLocks;
	copy->_allowsUNIXSockets = _allowsUNIXSockets;
	copy->_allowsDNS = _allowsDNS;
	copy->_allowsUserDatabaseReading = _allowsUserDatabaseReading;
	copy->_allowsFileDescriptorSending = _allowsFileDescriptorSending;
	copy->_allowsFileDescriptorReceiving = _allowsFileDescriptorReceiving;
	copy->_allowsTape = _allowsTape;
	copy->_allowsTTY = _allowsTTY;
	copy->_allowsProcessOperations = _allowsProcessOperations;
	copy->_allowsExec = _allowsExec;
	copy->_allowsProtExec = _allowsProtExec;
	copy->_allowsSetTime = _allowsSetTime;
	copy->_allowsPS = _allowsPS;
	copy->_allowsVMInfo = _allowsVMInfo;
	copy->_allowsChangingProcessRights = _allowsChangingProcessRights;
	copy->_allowsPF = _allowsPF;
	copy->_allowsAudio = _allowsAudio;
	copy->_allowsBPF = _allowsBPF;

	return copy;
}

- (bool)isEqual: (id)otherObject
{
	OFSandbox *otherSandbox;

	if (![otherObject isKindOfClass: [OFSandbox class]])
		return false;

	otherSandbox = otherObject;

	if (otherSandbox->_allowsStdIO != _allowsStdIO)
		return false;
	if (otherSandbox->_allowsReadingFiles != _allowsReadingFiles)
		return false;
	if (otherSandbox->_allowsWritingFiles != _allowsWritingFiles)
		return false;
	if (otherSandbox->_allowsCreatingFiles != _allowsCreatingFiles)
		return false;
	if (otherSandbox->_allowsCreatingSpecialFiles !=
	    _allowsCreatingSpecialFiles)
		return false;
	if (otherSandbox->_allowsTemporaryFiles != _allowsTemporaryFiles)
		return false;
	if (otherSandbox->_allowsIPSockets != _allowsIPSockets)
		return false;
	if (otherSandbox->_allowsMulticastSockets != _allowsMulticastSockets)
		return false;
	if (otherSandbox->_allowsChangingFileAttributes !=
	    _allowsChangingFileAttributes)
		return false;
	if (otherSandbox->_allowsFileOwnerChanges != _allowsFileOwnerChanges)
		return false;
	if (otherSandbox->_allowsFileLocks != _allowsFileLocks)
		return false;
	if (otherSandbox->_allowsUNIXSockets != _allowsUNIXSockets)
		return false;
	if (otherSandbox->_allowsDNS != _allowsDNS)
		return false;
	if (otherSandbox->_allowsUserDatabaseReading !=
	    _allowsUserDatabaseReading)
		return false;
	if (otherSandbox->_allowsFileDescriptorSending !=
	    _allowsFileDescriptorSending)
		return false;
	if (otherSandbox->_allowsFileDescriptorReceiving !=
	    _allowsFileDescriptorReceiving)
		return false;
	if (otherSandbox->_allowsTape != _allowsTape)
		return false;
	if (otherSandbox->_allowsTTY != _allowsTTY)
		return false;
	if (otherSandbox->_allowsProcessOperations != _allowsProcessOperations)
		return false;
	if (otherSandbox->_allowsExec != _allowsExec)
		return false;
	if (otherSandbox->_allowsProtExec != _allowsProtExec)
		return false;
	if (otherSandbox->_allowsSetTime != _allowsSetTime)
		return false;
	if (otherSandbox->_allowsPS != _allowsPS)
		return false;
	if (otherSandbox->_allowsVMInfo != _allowsVMInfo)
		return false;
	if (otherSandbox->_allowsChangingProcessRights !=
	    _allowsChangingProcessRights)
		return false;
	if (otherSandbox->_allowsPF != _allowsPF)
		return false;
	if (otherSandbox->_allowsAudio != _allowsAudio)
		return false;
	if (otherSandbox->_allowsBPF != _allowsBPF)
		return false;

	return true;
}

- (uint32_t)hash
{
	uint32_t hash;

	OF_HASH_INIT(hash);

	OF_HASH_ADD(hash, _allowsStdIO);
	OF_HASH_ADD(hash, _allowsReadingFiles);
	OF_HASH_ADD(hash, _allowsWritingFiles);
	OF_HASH_ADD(hash, _allowsCreatingFiles);
	OF_HASH_ADD(hash, _allowsCreatingSpecialFiles);
	OF_HASH_ADD(hash, _allowsTemporaryFiles);
	OF_HASH_ADD(hash, _allowsIPSockets);
	OF_HASH_ADD(hash, _allowsMulticastSockets);
	OF_HASH_ADD(hash, _allowsChangingFileAttributes);
	OF_HASH_ADD(hash, _allowsFileOwnerChanges);
	OF_HASH_ADD(hash, _allowsFileLocks);
	OF_HASH_ADD(hash, _allowsUNIXSockets);
	OF_HASH_ADD(hash, _allowsDNS);
	OF_HASH_ADD(hash, _allowsUserDatabaseReading);
	OF_HASH_ADD(hash, _allowsFileDescriptorSending);
	OF_HASH_ADD(hash, _allowsFileDescriptorReceiving);
	OF_HASH_ADD(hash, _allowsTape);
	OF_HASH_ADD(hash, _allowsTTY);
	OF_HASH_ADD(hash, _allowsProcessOperations);
	OF_HASH_ADD(hash, _allowsExec);
	OF_HASH_ADD(hash, _allowsProtExec);
	OF_HASH_ADD(hash, _allowsSetTime);
	OF_HASH_ADD(hash, _allowsPS);
	OF_HASH_ADD(hash, _allowsVMInfo);
	OF_HASH_ADD(hash, _allowsChangingProcessRights);
	OF_HASH_ADD(hash, _allowsPF);
	OF_HASH_ADD(hash, _allowsAudio);
	OF_HASH_ADD(hash, _allowsBPF);

	OF_HASH_FINALIZE(hash);

	return hash;
}

#ifdef OF_HAVE_PLEDGE
- (OFString *)pledgeString
{
	void *pool = objc_autoreleasePoolPush();
	OFMutableArray *pledges = [OFMutableArray array];
	OFString *ret;

	if (_allowsStdIO)
		[pledges addObject: @"stdio"];
	if (_allowsReadingFiles)
		[pledges addObject: @"rpath"];
	if (_allowsWritingFiles)
		[pledges addObject: @"wpath"];
	if (_allowsCreatingFiles)
		[pledges addObject: @"cpath"];
	if (_allowsCreatingSpecialFiles)
		[pledges addObject: @"dpath"];
	if (_allowsTemporaryFiles)
		[pledges addObject: @"tmppath"];
	if (_allowsIPSockets)
		[pledges addObject: @"inet"];
	if (_allowsMulticastSockets)
		[pledges addObject: @"mcast"];
	if (_allowsChangingFileAttributes)
		[pledges addObject: @"fattr"];
	if (_allowsFileOwnerChanges)
		[pledges addObject: @"chown"];
	if (_allowsFileLocks)
		[pledges addObject: @"flock"];
	if (_allowsUNIXSockets)
		[pledges addObject: @"unix"];
	if (_allowsDNS)
		[pledges addObject: @"dns"];
	if (_allowsUserDatabaseReading)
		[pledges addObject: @"getpw"];
	if (_allowsFileDescriptorSending)
		[pledges addObject: @"sendfd"];
	if (_allowsFileDescriptorReceiving)
		[pledges addObject: @"recvfd"];
	if (_allowsTape)
		[pledges addObject: @"tape"];
	if (_allowsTTY)
		[pledges addObject: @"tty"];
	if (_allowsProcessOperations)
		[pledges addObject: @"proc"];
	if (_allowsExec)
		[pledges addObject: @"exec"];
	if (_allowsProtExec)
		[pledges addObject: @"prot_exec"];
	if (_allowsSetTime)
		[pledges addObject: @"settime"];
	if (_allowsPS)
		[pledges addObject: @"ps"];
	if (_allowsVMInfo)
		[pledges addObject: @"vminfo"];
	if (_allowsChangingProcessRights)
		[pledges addObject: @"id"];
	if (_allowsPF)
		[pledges addObject: @"pf"];
	if (_allowsAudio)
		[pledges addObject: @"audio"];
	if (_allowsBPF)
		[pledges addObject: @"bpf"];

	ret = [pledges componentsJoinedByString: @" "];

	[ret retain];

	objc_autoreleasePoolPop(pool);

	return [ret autorelease];
}
#endif
@end
