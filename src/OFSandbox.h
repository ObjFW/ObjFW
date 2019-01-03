/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017,
 *               2018, 2019
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

/*! @file */

@class OFArray OF_GENERIC(ObjectType);
@class OFMutableArray OF_GENERIC(ObjectType);
@class OFPair OF_GENERIC(FirstType, SecondType);

/*!
 * @brief An @ref OFPair for a path to unveil, with the first string being the
 *	  path and the second the permissions.
 */
typedef OFPair OF_GENERIC(OFString *, OFString *) *of_sandbox_unveil_path_t;

/*!
 * @class OFSandbox OFSandbox.h ObjFW/OFSandbox.h
 *
 * @brief A class which describes a sandbox for the application.
 */
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
	OFMutableArray OF_GENERIC(of_sandbox_unveil_path_t) *_unveiledPaths;
@public
	size_t _unveiledPathsIndex;
}

/*!
 * @brief Allows IO operations on previously allocated file descriptors.
 */
@property (nonatomic) bool allowsStdIO;

/*!
 * @brief Allows read access to the file system.
 */
@property (nonatomic) bool allowsReadingFiles;

/*!
 * @brief Allows write access to the file system.
 */
@property (nonatomic) bool allowsWritingFiles;

/*!
 * @brief Allows creating files in the file system.
 */
@property (nonatomic) bool allowsCreatingFiles;

/*!
 * @brief Allows creating special files in the file system.
 */
@property (nonatomic) bool allowsCreatingSpecialFiles;

/*!
 * @brief Allows creating, reading and writing temporary files in `/tmp`.
 */
@property (nonatomic) bool allowsTemporaryFiles;

/*!
 * @brief Allows using IP sockets.
 */
@property (nonatomic) bool allowsIPSockets;

/*!
 * @brief Allows multicast sockets.
 */
@property (nonatomic) bool allowsMulticastSockets;

/*!
 * @brief Allows explicit changes to file attributes.
 */
@property (nonatomic) bool allowsChangingFileAttributes;

/*!
 * @brief Allows changing ownership of files.
 */
@property (nonatomic) bool allowsFileOwnerChanges;

/*!
 * @brief Allows file locks.
 */
@property (nonatomic) bool allowsFileLocks;

/*!
 * @brief Allows UNIX sockets.
 */
@property (nonatomic) bool allowsUNIXSockets;

/*!
 * @brief Allows syscalls necessary for DNS lookups.
 */
@property (nonatomic) bool allowsDNS;

/*!
 * @brief Allows to look up users and groups.
 */
@property (nonatomic) bool allowsUserDatabaseReading;

/*!
 * @brief Allows sending file descriptors via sendmsg().
 */
@property (nonatomic) bool allowsFileDescriptorSending;

/*!
 * @brief Allows receiving file descriptors via recvmsg().
 */
@property (nonatomic) bool allowsFileDescriptorReceiving;

/*!
 * @brief Allows MTIOCGET and MTIOCTOP operations on tape devices.
 */
@property (nonatomic) bool allowsTape;

/*!
 * @brief Allows read-write operations and ioctls on the TTY.
 */
@property (nonatomic) bool allowsTTY;

/*!
 * @brief Allows various process relationshop operations.
 */
@property (nonatomic) bool allowsProcessOperations;

/*!
 * @brief Allows execve().
 */
@property (nonatomic) bool allowsExec;

/*!
 * @brief Allows PROT_EXEC for `mmap()` and `mprotect()`.
 */
@property (nonatomic) bool allowsProtExec;

/*!
 * @brief Allows `settime()`.
 */
@property (nonatomic) bool allowsSetTime;

/*!
 * @brief Allows introspection of processes on the system.
 */
@property (nonatomic) bool allowsPS;

/*!
 * @brief Allows introspection of the system's virtual memory.
 */
@property (nonatomic) bool allowsVMInfo;

/*!
 * @brief Allows changing the rights of process, for example the UID.
 */
@property (nonatomic) bool allowsChangingProcessRights;

/*!
 * @brief Allows certain ioctls on the PF device.
 */
@property (nonatomic) bool allowsPF;

/*!
 * @brief Allows certain ioctls on audio devices.
 */
@property (nonatomic) bool allowsAudio;

/*!
 * @brief Allows BIOCGSTATS to collect statistics from a BPF device.
 */
@property (nonatomic) bool allowsBPF;

/*!
 * @brief Allows unveiling more paths.
 */
@property (nonatomic) bool allowsUnveil;

/*!
 * @brief Returns errors instead of killing the process.
 */
@property (nonatomic) bool returnsErrors;

#ifdef OF_HAVE_PLEDGE
/*!
 * The string for OpenBSD's pledge() call.
 *
 * @warning Only available on systems with the pledge() call!
 */
@property (readonly, nonatomic) OFString *pledgeString;
#endif

/*!
 * @brief A list of unveiled paths.
 */
@property (readonly, nonatomic)
    OFArray OF_GENERIC(of_sandbox_unveil_path_t) *unveiledPaths;

/*!
 * @brief Create a new, autorelease OFSandbox.
 */
+ (instancetype)sandbox;

/*!
 * @brief "Unveils" the specified path, meaning that it becomes visible from
 *	  the sandbox with the specified permissions.
 *
 * @param path The path to unveil
 * @param permissions The permissions for the path. The following permissions
 *		      can be combined:
 *		      Permission | Description
 *		      -----------|--------------------
 *		      r          | Make the path available for reading, like
 *		                 | @ref allowsReadingFiles
 *		      w          | Make the path available for writing, like
 *		                 | @ref allowsWritingFiles
 *		      x          | Make the path available for executing, like
 *		                 | @ref allowsExec
 *		      c          | Make the path available for creation and
 *		                 | deletion, like @ref allowsCreatingFiles
 */
- (void)unveilPath: (OFString *)path
       permissions: (OFString *)permissions;
@end

OF_ASSUME_NONNULL_END
