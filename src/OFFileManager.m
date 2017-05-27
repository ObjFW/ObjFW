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

#include "config.h"

#include <errno.h>

#ifdef HAVE_DIRENT_H
# include <dirent.h>
#endif
#include "unistd_wrapper.h"

#ifdef HAVE_PWD_H
# include <pwd.h>
#endif
#ifdef HAVE_GRP_H
# include <grp.h>
#endif

#import "OFFileManager.h"
#import "OFFile.h"
#import "OFString.h"
#import "OFArray.h"
#import "OFDate.h"
#import "OFSystemInfo.h"
#import "OFLocalization.h"

#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
#endif

#import "OFChangeCurrentDirectoryPathFailedException.h"
#import "OFChangeOwnerFailedException.h"
#import "OFChangePermissionsFailedException.h"
#import "OFCopyItemFailedException.h"
#import "OFCreateDirectoryFailedException.h"
#import "OFCreateSymbolicLinkFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFLinkFailedException.h"
#import "OFLockFailedException.h"
#import "OFMoveItemFailedException.h"
#import "OFNotImplementedException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfMemoryException.h"
#import "OFReadFailedException.h"
#import "OFRemoveItemFailedException.h"
#import "OFStatItemFailedException.h"
#import "OFUnlockFailedException.h"

#ifdef OF_WINDOWS
# include <windows.h>
# include <direct.h>
# include <ntdef.h>
#endif

#ifndef S_IRGRP
# define S_IRGRP 0
#endif
#ifndef S_IROTH
# define S_IROTH 0
#endif
#ifndef S_IWGRP
# define S_IWGRP 0
#endif
#ifndef S_IWOTH
# define S_IWOTH 0
#endif

#define DEFAULT_MODE S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH
#define DIR_MODE DEFAULT_MODE | S_IXUSR | S_IXGRP | S_IXOTH

static OFFileManager *defaultManager;

#if defined(OF_HAVE_CHOWN) && defined(OF_HAVE_THREADS)
static OFMutex *passwdMutex;
#endif
#if !defined(HAVE_READDIR_R) && !defined(OF_WINDOWS) && defined(OF_HAVE_THREADS)
static OFMutex *readdirMutex;
#endif

#ifdef OF_WINDOWS
static WINAPI BOOLEAN (*func_CreateSymbolicLinkW)(LPCWSTR, LPCWSTR, DWORD);
#endif

int
of_stat(OFString *path, of_stat_t *buffer)
{
#if defined(OF_WINDOWS)
	return _wstat64([path UTF16String], buffer);
#elif defined(OF_HAVE_OFF64_T)
	return stat64([path cStringWithEncoding: [OFLocalization encoding]],
	    buffer);
#else
	return stat([path cStringWithEncoding: [OFLocalization encoding]],
	    buffer);
#endif
}

int
of_lstat(OFString *path, of_stat_t *buffer)
{
#if defined(OF_WINDOWS)
	return _wstat64([path UTF16String], buffer);
#elif defined(HAVE_LSTAT)
# ifdef OF_HAVE_OFF64_T
	return lstat64([path cStringWithEncoding: [OFLocalization encoding]],
	    buffer);
# else
	return lstat([path cStringWithEncoding: [OFLocalization encoding]],
	    buffer);
# endif
#else
# ifdef OF_HAVE_OFF64_T
	return stat64([path cStringWithEncoding: [OFLocalization encoding]],
	    buffer);
# else
	return stat([path cStringWithEncoding: [OFLocalization encoding]],
	    buffer);
# endif
#endif
}

@implementation OFFileManager
+ (void)initialize
{
#ifdef OF_WINDOWS
	HMODULE module;
#endif

	if (self != [OFFileManager class])
		return;

	/*
	 * Make sure OFFile is initialized.
	 * On some systems, this is needed to initialize the file system driver.
	 */
	[OFFile class];

#if defined(OF_HAVE_CHOWN) && defined(OF_HAVE_THREADS)
	passwdMutex = [[OFMutex alloc] init];
#endif
#if !defined(HAVE_READDIR_R) && !defined(OF_WINDOWS) && defined(OF_HAVE_THREADS)
	readdirMutex = [[OFMutex alloc] init];
#endif

#ifdef OF_WINDOWS
	if ((module = LoadLibrary("kernel32.dll")) != NULL)
		func_CreateSymbolicLinkW =
		    (WINAPI BOOLEAN (*)(LPCWSTR, LPCWSTR, DWORD))
		    GetProcAddress(module, "CreateSymbolicLinkW");
#endif

	defaultManager = [[OFFileManager alloc] init];
}

+ (OFFileManager *)defaultManager
{
	return defaultManager;
}

- (OFString *)currentDirectoryPath
{
	OFString *ret;
#ifndef OF_WINDOWS
	char *buffer = getcwd(NULL, 0);
#else
	wchar_t *buffer = _wgetcwd(NULL, 0);
#endif

	@try {
#ifndef OF_WINDOWS
		ret = [OFString
		    stringWithCString: buffer
			     encoding: [OFLocalization encoding]];
#else
		ret = [OFString stringWithUTF16String: buffer];
#endif
	} @finally {
		free(buffer);
	}

	return ret;
}

- (bool)fileExistsAtPath: (OFString *)path
{
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if (of_stat(path, &s) == -1)
		return false;

	if (S_ISREG(s.st_mode))
		return true;

	return false;
}

- (bool)directoryExistsAtPath: (OFString *)path
{
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if (of_stat(path, &s) == -1)
		return false;

	if (S_ISDIR(s.st_mode))
		return true;

	return false;
}

#if defined(OF_HAVE_SYMLINK)
- (bool)symbolicLinkExistsAtPath: (OFString *)path
{
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if (of_lstat(path, &s) == -1)
		return false;

	if (S_ISLNK(s.st_mode))
		return true;

	return false;
}
#elif defined(OF_WINDOWS)
- (bool)symbolicLinkExistsAtPath: (OFString *)path
{
	WIN32_FIND_DATAW data;

	if (!FindFirstFileW([path UTF16String], &data))
		return false;

	if ((data.dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) &&
	    data.dwReserved0 == IO_REPARSE_TAG_SYMLINK)
		return true;

	return false;
}
#endif

- (void)createDirectoryAtPath: (OFString *)path
{
	if (path == nil)
		@throw [OFInvalidArgumentException exception];

#ifndef OF_WINDOWS
	if (mkdir([path cStringWithEncoding: [OFLocalization encoding]],
	    DIR_MODE) != 0)
#else
	if (_wmkdir([path UTF16String]) != 0)
#endif
		@throw [OFCreateDirectoryFailedException
		    exceptionWithPath: path
				errNo: errno];
}

- (void)createDirectoryAtPath: (OFString *)path
		createParents: (bool)createParents
{
	OFString *currentPath = nil;

	if (!createParents) {
		[self createDirectoryAtPath: path];
		return;
	}

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	for (OFString *component in [path pathComponents]) {
		void *pool = objc_autoreleasePoolPush();

		if (currentPath != nil)
			currentPath = [currentPath
			    stringByAppendingPathComponent: component];
		else
			currentPath = component;

		if ([currentPath length] > 0 &&
		    ![self directoryExistsAtPath: currentPath])
			[self createDirectoryAtPath: currentPath];

		[currentPath retain];

		objc_autoreleasePoolPop(pool);

		[currentPath autorelease];
	}
}

- (OFArray *)contentsOfDirectoryAtPath: (OFString *)path
{
	OFMutableArray *files;
#ifndef OF_WINDOWS
	of_string_encoding_t encoding;
#endif

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	files = [OFMutableArray array];

#ifndef OF_WINDOWS
	DIR *dir;

	encoding = [OFLocalization encoding];

	if ((dir = opendir([path cStringWithEncoding: encoding])) == NULL)
		@throw [OFOpenItemFailedException exceptionWithPath: path
							      errNo: errno];

# if !defined(HAVE_READDIR_R) && defined(OF_HAVE_THREADS)
	[readdirMutex lock];
# endif
	@try {
		for (;;) {
			struct dirent *dirent;
# ifdef HAVE_READDIR_R
			struct dirent buffer;
# endif
			void *pool;
			OFString *file;

# ifdef HAVE_READDIR_R
			if (readdir_r(dir, &buffer, &dirent) != 0)
				@throw [OFReadFailedException
				    exceptionWithObject: self
					requestedLength: 0
						  errNo: errno];

			if (dirent == NULL)
				break;
# else
			if ((dirent = readdir(dir)) == NULL) {
				if (errno == 0)
					break;
				else
					@throw [OFReadFailedException
					    exceptionWithObject: self
						requestedLength: 0
							  errNo: errno];
			}
# endif

			if (strcmp(dirent->d_name, ".") == 0 ||
			    strcmp(dirent->d_name, "..") == 0)
				continue;

			pool = objc_autoreleasePoolPush();

			file = [OFString stringWithCString: dirent->d_name
						  encoding: encoding];
			[files addObject: file];

			objc_autoreleasePoolPop(pool);
		}
	} @finally {
		closedir(dir);
# if !defined(HAVE_READDIR_R) && defined(OF_HAVE_THREADS)
		[readdirMutex unlock];
# endif
	}
#else
	void *pool = objc_autoreleasePoolPush();
	HANDLE handle;
	WIN32_FIND_DATAW fd;

	path = [path stringByAppendingString: @"\\*"];

	if ((handle = FindFirstFileW([path UTF16String],
	    &fd)) == INVALID_HANDLE_VALUE) {
		int errNo = 0;

		if (GetLastError() == ERROR_FILE_NOT_FOUND)
			errNo = ENOENT;

		@throw [OFOpenItemFailedException exceptionWithPath: path
							      errNo: errNo];
	}

	@try {
		do {
			void *pool2 = objc_autoreleasePoolPush();
			OFString *file;

			if (!wcscmp(fd.cFileName, L".") ||
			    !wcscmp(fd.cFileName, L".."))
				continue;

			file = [OFString stringWithUTF16String: fd.cFileName];
			[files addObject: file];

			objc_autoreleasePoolPop(pool2);
		} while (FindNextFileW(handle, &fd));

		if (GetLastError() != ERROR_NO_MORE_FILES)
			@throw [OFReadFailedException exceptionWithObject: self
							  requestedLength: 0];
	} @finally {
		FindClose(handle);
	}

	objc_autoreleasePoolPop(pool);
#endif

	[files makeImmutable];

	return files;
}

- (void)changeCurrentDirectoryPath: (OFString *)path
{
	if (path == nil)
		@throw [OFInvalidArgumentException exception];

#ifndef OF_WINDOWS
	if (chdir([path cStringWithEncoding: [OFLocalization encoding]]) != 0)
#else
	if (_wchdir([path UTF16String]) != 0)
#endif
		@throw [OFChangeCurrentDirectoryPathFailedException
		    exceptionWithPath: path
				errNo: errno];
}

- (of_offset_t)sizeOfFileAtPath: (OFString *)path
{
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if (of_stat(path, &s) != 0)
		@throw [OFStatItemFailedException exceptionWithPath: path
							      errNo: errno];

	return s.st_size;
}

- (OFDate *)accessTimeOfItemAtPath: (OFString *)path
{
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if (of_stat(path, &s) != 0)
		@throw [OFStatItemFailedException exceptionWithPath: path
							      errNo: errno];

	/* FIXME: We could be more precise on some OSes */
	return [OFDate dateWithTimeIntervalSince1970: s.st_atime];
}

- (OFDate *)modificationTimeOfItemAtPath: (OFString *)path
{
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if (of_stat(path, &s) != 0)
		@throw [OFStatItemFailedException exceptionWithPath: path
							      errNo: errno];

	/* FIXME: We could be more precise on some OSes */
	return [OFDate dateWithTimeIntervalSince1970: s.st_mtime];
}

- (OFDate *)statusChangeTimeOfItemAtPath: (OFString *)path
{
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if (of_stat(path, &s) != 0)
		@throw [OFStatItemFailedException exceptionWithPath: path
							      errNo: errno];

	/* FIXME: We could be more precise on some OSes */
	return [OFDate dateWithTimeIntervalSince1970: s.st_ctime];
}

#ifdef OF_HAVE_CHMOD
- (mode_t)permissionsOfItemAtPath: (OFString *)path
{
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if (of_stat(path, &s) != 0)
		@throw [OFStatItemFailedException exceptionWithPath: path
							      errNo: errno];

	return s.st_mode;
}

- (void)changePermissionsOfItemAtPath: (OFString *)path
			  permissions: (mode_t)permissions
{
	if (path == nil)
		@throw [OFInvalidArgumentException exception];

# ifndef OF_WINDOWS
	if (chmod([path cStringWithEncoding: [OFLocalization encoding]],
	    permissions) != 0)
# else
	if (_wchmod([path UTF16String], permissions) != 0)
# endif
		@throw [OFChangePermissionsFailedException
		    exceptionWithPath: path
			  permissions: permissions
				errNo: errno];
}
#endif

#ifdef OF_HAVE_CHOWN
- (void)getOwner: (OFString **)owner
	   group: (OFString **)group
    ofItemAtPath: (OFString *)path
{
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if (of_stat(path, &s) != 0)
		@throw [OFStatItemFailedException exceptionWithPath: path
							      errNo: errno];

# ifdef OF_HAVE_THREADS
	[passwdMutex lock];
	@try {
# endif
		of_string_encoding_t encoding = [OFLocalization encoding];

		if (owner != NULL) {
			struct passwd *passwd = getpwuid(s.st_uid);

			*owner = [OFString stringWithCString: passwd->pw_name
						    encoding: encoding];
		}

		if (group != NULL) {
			struct group *group_ = getgrgid(s.st_gid);

			*group = [OFString stringWithCString: group_->gr_name
						    encoding: encoding];
		}
# ifdef OF_HAVE_THREADS
	} @finally {
		[passwdMutex unlock];
	}
#endif
}

- (void)changeOwnerOfItemAtPath: (OFString *)path
			  owner: (OFString *)owner
			  group: (OFString *)group
{
	uid_t uid = -1;
	gid_t gid = -1;
	of_string_encoding_t encoding;

	if (path == nil || (owner == nil && group == nil))
		@throw [OFInvalidArgumentException exception];

	encoding = [OFLocalization encoding];

# ifdef OF_HAVE_THREADS
	[passwdMutex lock];
	@try {
# endif
		if (owner != nil) {
			struct passwd *passwd;

			if ((passwd = getpwnam([owner
			    cStringWithEncoding: encoding])) == NULL)
				@throw [OFChangeOwnerFailedException
				    exceptionWithPath: path
						owner: owner
						group: group
						errNo: errno];

			uid = passwd->pw_uid;
		}

		if (group != nil) {
			struct group *group_;

			if ((group_ = getgrnam([group
			    cStringWithEncoding: encoding])) == NULL)
				@throw [OFChangeOwnerFailedException
				    exceptionWithPath: path
						owner: owner
						group: group
						errNo: errno];

			gid = group_->gr_gid;
		}
# ifdef OF_HAVE_THREADS
	} @finally {
		[passwdMutex unlock];
	}
# endif

	if (chown([path cStringWithEncoding: encoding], uid, gid) != 0)
		@throw [OFChangeOwnerFailedException exceptionWithPath: path
								 owner: owner
								 group: group
								 errNo: errno];
}
#endif

- (void)copyItemAtPath: (OFString *)source
		toPath: (OFString *)destination
{
	void *pool;
	of_stat_t s;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if (of_lstat(destination, &s) == 0)
		@throw [OFCopyItemFailedException
		    exceptionWithSourcePath: source
			    destinationPath: destination
				      errNo: EEXIST];

	if (of_lstat(source, &s) != 0)
		@throw [OFCopyItemFailedException
		    exceptionWithSourcePath: source
			    destinationPath: destination
				      errNo: errno];

	if (S_ISDIR(s.st_mode)) {
		OFArray *contents;

		@try {
			[self createDirectoryAtPath: destination];
#ifdef OF_HAVE_CHMOD
			[self changePermissionsOfItemAtPath: destination
						permissions: s.st_mode];
#endif

			contents = [self contentsOfDirectoryAtPath: source];
		} @catch (id e) {
			/*
			 * Only convert exceptions to OFCopyItemFailedException
			 * that have an errNo property. This covers all I/O
			 * related exceptions from the operations used to copy
			 * an item, all others should be left as is.
			 */
			if ([e respondsToSelector: @selector(errNo)])
				@throw [OFCopyItemFailedException
				    exceptionWithSourcePath: source
					    destinationPath: destination
						      errNo: [e errNo]];

			@throw e;
		}

		for (OFString *item in contents) {
			void *pool2 = objc_autoreleasePoolPush();
			OFString *sourcePath, *destinationPath;

			sourcePath =
			    [source stringByAppendingPathComponent: item];
			destinationPath =
			    [destination stringByAppendingPathComponent: item];

			[self copyItemAtPath: sourcePath
				      toPath: destinationPath];

			objc_autoreleasePoolPop(pool2);
		}
	} else if (S_ISREG(s.st_mode)) {
		size_t pageSize = [OFSystemInfo pageSize];
		OFFile *sourceFile = nil;
		OFFile *destinationFile = nil;
		char *buffer;

		if ((buffer = malloc(pageSize)) == NULL)
			@throw [OFOutOfMemoryException
			    exceptionWithRequestedSize: pageSize];

		@try {
			sourceFile = [OFFile fileWithPath: source
						     mode: @"rb"];
			destinationFile = [OFFile fileWithPath: destination
							  mode: @"wb"];

			while (![sourceFile isAtEndOfStream]) {
				size_t length;

				length = [sourceFile readIntoBuffer: buffer
							     length: pageSize];
				[destinationFile writeBuffer: buffer
						      length: length];
			}

#ifdef OF_HAVE_CHMOD
			[self changePermissionsOfItemAtPath: destination
						permissions: s.st_mode];
#endif
		} @catch (id e) {
			/*
			 * Only convert exceptions to OFCopyItemFailedException
			 * that have an errNo property. This covers all I/O
			 * related exceptions from the operations used to copy
			 * an item, all others should be left as is.
			 */
			if ([e respondsToSelector: @selector(errNo)])
				@throw [OFCopyItemFailedException
				    exceptionWithSourcePath: source
					    destinationPath: destination
						      errNo: [e errNo]];

			@throw e;
		} @finally {
			[sourceFile close];
			[destinationFile close];
			free(buffer);
		}
#ifdef OF_HAVE_SYMLINK
	} else if (S_ISLNK(s.st_mode)) {
		@try {
			source = [self destinationOfSymbolicLinkAtPath: source];

			[self createSymbolicLinkAtPath: destination
				   withDestinationPath: source];
		} @catch (id e) {
			/*
			 * Only convert exceptions to OFCopyItemFailedException
			 * that have an errNo property. This covers all I/O
			 * related exceptions from the operations used to copy
			 * an item, all others should be left as is.
			 */
			if ([e respondsToSelector: @selector(errNo)])
				@throw [OFCopyItemFailedException
				    exceptionWithSourcePath: source
					    destinationPath: destination
						      errNo: [e errNo]];

			@throw e;
		}
#endif
	} else
		@throw [OFCopyItemFailedException
		    exceptionWithSourcePath: source
			    destinationPath: destination
				      errNo: EINVAL];

	objc_autoreleasePoolPop(pool);
}

- (void)moveItemAtPath: (OFString *)source
		toPath: (OFString *)destination
{
	void *pool;
	of_stat_t s;
#ifndef OF_WINDOWS
	of_string_encoding_t encoding;
#endif

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if (of_lstat(destination, &s) == 0)
		@throw [OFCopyItemFailedException
		    exceptionWithSourcePath: source
			    destinationPath: destination
				      errNo: EEXIST];

#ifndef OF_WINDOWS
	encoding = [OFLocalization encoding];

	if (rename([source cStringWithEncoding: encoding],
	    [destination cStringWithEncoding: encoding]) != 0) {
#else
	if (_wrename([source UTF16String], [destination UTF16String]) != 0) {
#endif
		if (errno != EXDEV)
			@throw [OFMoveItemFailedException
			    exceptionWithSourcePath: source
				    destinationPath: destination
					      errNo: errno];

		@try {
			[self copyItemAtPath: source
				      toPath: destination];
		} @catch (OFCopyItemFailedException *e) {
			[self removeItemAtPath: destination];

			@throw [OFMoveItemFailedException
			    exceptionWithSourcePath: source
				    destinationPath: destination
					      errNo: [e errNo]];
		}

		@try {
			[self removeItemAtPath: source];
		} @catch (OFRemoveItemFailedException *e) {
			@throw [OFMoveItemFailedException
			    exceptionWithSourcePath: source
				    destinationPath: destination
					      errNo: [e errNo]];
		}
	}

	objc_autoreleasePoolPop(pool);
}

- (void)removeItemAtPath: (OFString *)path
{
	void *pool;
	of_stat_t s;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if (of_lstat(path, &s) != 0)
		@throw [OFRemoveItemFailedException exceptionWithPath: path
								errNo: errno];

	if (S_ISDIR(s.st_mode)) {
		OFArray *contents;

		@try {
			contents = [self contentsOfDirectoryAtPath: path];
		} @catch (id e) {
			/*
			 * Only convert exceptions to
			 * OFRemoveItemFailedException that have an errNo
			 * property. This covers all I/O related exceptions
			 * from the operations used to remove an item, all
			 * others should be left as is.
			 */
			if ([e respondsToSelector: @selector(errNo)])
				@throw [OFRemoveItemFailedException
				    exceptionWithPath: path
						errNo: [e errNo]];

			@throw e;
		}

		for (OFString *item in contents) {
			void *pool2 = objc_autoreleasePoolPush();

			[self removeItemAtPath:
			    [path stringByAppendingPathComponent: item]];

			objc_autoreleasePoolPop(pool2);
		}

#ifndef OF_WINDOWS
		if (rmdir([path cStringWithEncoding:
		    [OFLocalization encoding]]) != 0)
#else
		if (_wrmdir([path UTF16String]) != 0)
#endif
			@throw [OFRemoveItemFailedException
				exceptionWithPath: path
					    errNo: errno];
	} else {
#ifndef OF_WINDOWS
		if (unlink([path cStringWithEncoding:
		    [OFLocalization encoding]]) != 0)
#else
		if (_wunlink([path UTF16String]) != 0)
#endif
			@throw [OFRemoveItemFailedException
			    exceptionWithPath: path
					errNo: errno];
	}

	objc_autoreleasePoolPop(pool);
}

#if defined(OF_HAVE_LINK)
- (void)linkItemAtPath: (OFString *)source
		toPath: (OFString *)destination
{
	void *pool;
	of_string_encoding_t encoding;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();
	encoding = [OFLocalization encoding];

	if (link([source cStringWithEncoding: encoding],
	    [destination cStringWithEncoding: encoding]) != 0)
		@throw [OFLinkFailedException
		    exceptionWithSourcePath: source
			    destinationPath: destination
				      errNo: errno];

	objc_autoreleasePoolPop(pool);
}
#elif defined(OF_WINDOWS)
- (void)linkItemAtPath: (OFString *)source
		toPath: (OFString *)destination
{
	void *pool;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if (!CreateHardLinkW([destination UTF16String],
	    [source UTF16String], NULL))
		@throw [OFLinkFailedException
		    exceptionWithSourcePath: source
			    destinationPath: destination];

	objc_autoreleasePoolPop(pool);
}
#endif

#if defined(OF_HAVE_SYMLINK)
- (void)createSymbolicLinkAtPath: (OFString *)destination
	     withDestinationPath: (OFString *)source
{
	void *pool;
	of_string_encoding_t encoding;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();
	encoding = [OFLocalization encoding];

	if (symlink([source cStringWithEncoding: encoding],
	    [destination cStringWithEncoding: encoding]) != 0)
		@throw [OFCreateSymbolicLinkFailedException
		    exceptionWithSourcePath: source
			    destinationPath: destination
				      errNo: errno];

	objc_autoreleasePoolPop(pool);
}
#elif defined(OF_WINDOWS)
- (void)createSymbolicLinkAtPath: (OFString *)destination
	     withDestinationPath: (OFString *)source
{
	void *pool;

	if (func_CreateSymbolicLinkW == NULL)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	pool = objc_autoreleasePoolPush();

	if (!func_CreateSymbolicLinkW([destination UTF16String],
	    [source UTF16String], 0))
		@throw [OFCreateSymbolicLinkFailedException
		    exceptionWithSourcePath: source
			    destinationPath: destination];

	objc_autoreleasePoolPop(pool);
}
#endif

#ifdef OF_HAVE_READLINK
- (OFString *)destinationOfSymbolicLinkAtPath: (OFString *)path
{
	char destination[PATH_MAX];
	ssize_t length;
	of_string_encoding_t encoding;

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	encoding = [OFLocalization encoding];
	length = readlink([path cStringWithEncoding: encoding],
	    destination, PATH_MAX);

	if (length < 0)
		@throw [OFStatItemFailedException exceptionWithPath: path
							      errNo: errno];

	return [OFString stringWithCString: destination
				  encoding: encoding
				    length: length];
}
#elif defined(OF_WINDOWS)
- (OFString *)destinationOfSymbolicLinkAtPath: (OFString *)path
{
	HANDLE handle;

	/* Check if we're on a version that actually supports symlinks. */
	if (func_CreateSymbolicLinkW == NULL)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	if (path == nil)
		@throw [OFInvalidArgumentException exception];

	if ((handle = CreateFileW([path UTF16String], 0,
	    (FILE_SHARE_READ | FILE_SHARE_WRITE), NULL, OPEN_EXISTING,
	    FILE_FLAG_OPEN_REPARSE_POINT, NULL)) == INVALID_HANDLE_VALUE)
		@throw [OFStatItemFailedException exceptionWithPath: path];

	@try {
		union {
			char bytes[MAXIMUM_REPARSE_DATA_BUFFER_SIZE];
			REPARSE_DATA_BUFFER data;
		} buffer;
		DWORD size;
		wchar_t *tmp;

		if (!DeviceIoControl(handle, FSCTL_GET_REPARSE_POINT, NULL, 0,
		    buffer.bytes, MAXIMUM_REPARSE_DATA_BUFFER_SIZE, &size,
		    NULL))
			@throw [OFStatItemFailedException
			    exceptionWithPath: path];

		if (buffer.data.ReparseTag != IO_REPARSE_TAG_SYMLINK)
			@throw [OFStatItemFailedException
			    exceptionWithPath: path];

#define slrb buffer.data.SymbolicLinkReparseBuffer
		tmp = slrb.PathBuffer +
		    (slrb.SubstituteNameOffset / sizeof(wchar_t));

		return [OFString
		    stringWithUTF16String: tmp
				   length: slrb.SubstituteNameLength /
					   sizeof(wchar_t)];
#undef slrb
	} @finally {
		CloseHandle(handle);
	}
}
#endif
@end
