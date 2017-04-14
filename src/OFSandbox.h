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

#import "OFObject.h"

OF_ASSUME_NONNULL_BEGIN

#ifndef DOXYGEN
@class OFArray OF_GENERIC(ObjectType);
#endif

/*!
 * @class OFSandbox OFSandbox.h ObjFW/OFSandbox.h
 *
 * @brief A class which describes a sandbox for the application.
 */
@interface OFSandbox: OFObject <OFCopying>
{
	bool _allowsStdIO, _allowsReadingFiles, _allowsWritingFiles;
	bool _allowsCreatingFiles, _allowsCreatingSpecialFiles;
	bool _allowsTemporaryFiles, _allowsIPSockets, _allowsMulticastSockets;
	bool _allowsChangingFileAttributes, _allowsFileOwnerChanges;
	bool _allowsFileLocks, _allowsUNIXSockets, _allowsDNS;
	bool _allowsUserDatabaseReading, _allowsFileDescriptorSending;
	bool _allowsFileDescriptorReceiving, _allowsTape, _allowsTTY;
	bool _allowsProcessOperations, _allowsExec, _allowsProtExec;
	bool _allowsSetTime, _allowsPS, _allowsVMInfo;
	bool _allowsChangingProcessRights, _allowsPF, _allowsAudio, _allowsBPF;
}

/*! Allows IO operations on previously allocated file descriptors. */
@property bool allowsStdIO;

/*! Allows read access to the file system. */
@property bool allowsReadingFiles;

/*! Allows write access to the file system. */
@property bool allowsWritingFiles;

/*! Allows creating files in the file system. */
@property bool allowsCreatingFiles;

/*! Allows creating special files in the file system. */
@property bool allowsCreatingSpecialFiles;

/*! Allows creating, reading and writing temporary files in /tmp. */
@property bool allowsTemporaryFiles;

/*! Allows using IP sockets. */
@property bool allowsIPSockets;

/*! Allows multicast sockets. */
@property bool allowsMulticastSockets;

/*! Allows explicit changes to file attributes. */
@property bool allowsChangingFileAttributes;

/*! Allows changing ownership of files. */
@property bool allowsFileOwnerChanges;

/*! Allows file locks. */
@property bool allowsFileLocks;

/*! Allows UNIX sockets. */
@property bool allowsUNIXSockets;

/*! Allows syscalls necessary for DNS lookups. */
@property bool allowsDNS;

/*! Allows to look up users and groups. */
@property bool allowsUserDatabaseReading;

/*! Allows sending file descriptors via sendmsg(). */
@property bool allowsFileDescriptorSending;

/*! Allows receiving file descriptors via recvmsg(). */
@property bool allowsFileDescriptorReceiving;

/*! Allows MTIOCGET and MTIOCTOP operations on tape devices. */
@property bool allowsTape;

/*! Allows read-write operations and ioctls on the TTY. */
@property bool allowsTTY;

/*! Allows various process relationshop operations. */
@property bool allowsProcessOperations;

/*! Allows execve(). */
@property bool allowsExec;

/*! Allows PROT_EXEC for mmap() and mprotect(). */
@property bool allowsProtExec;

/*! Allows settime(). */
@property bool allowsSetTime;

/*! Allows introspection of processes on the system. */
@property bool allowsPS;

/*! Allows introspection of the system's virtual memory. */
@property bool allowsVMInfo;

/*! Allows changing the rights of process, for example the UID. */
@property bool allowsChangingProcessRights;

/*! Allows certain ioctls on the PF device. */
@property bool allowsPF;

/*! Allows certain ioctls on audio devices. */
@property bool allowsAudio;

/*! Allows BIOCGSTATS to collect statistics from a BPF device. */
@property bool allowsBPF;

/*!
 * @brief Create a new, autorelease OFSandbox.
 */
+ (instancetype)sandbox;

#ifdef OF_HAVE_PLEDGE
/*!
 * @brief Returns the string for OpenBSD's pledge() call.
 *
 * @warning Only available on systems with the pledge() call!
 */
- (OFString*)pledgeString;
#endif
@end

OF_ASSUME_NONNULL_END
