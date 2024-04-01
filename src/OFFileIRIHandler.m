/*
 * Copyright (c) 2008-2024 Jonathan Schleifer <js@nil.im>
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

#ifndef _LARGEFILE64_SOURCE
# define _LARGEFILE64_SOURCE 1
#endif

#include <errno.h>
#include <math.h>

#ifdef HAVE_DIRENT_H
# include <dirent.h>
#endif
#include "unistd_wrapper.h"

#include "platform.h"
#ifdef HAVE_SYS_STAT_H
# include <sys/stat.h>
#endif
#include <sys/time.h>
#if defined(OF_LINUX) || defined(OF_MACOS)
# include <sys/xattr.h>
#endif
#ifdef OF_WINDOWS
# include <utime.h>
#endif
#ifdef OF_DJGPP
# include <syslimits.h>
#endif

#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif
#ifdef HAVE_PWD_H
# include <pwd.h>
#endif
#ifdef HAVE_GRP_H
# include <grp.h>
#endif

#import "OFFileIRIHandler.h"
#import "OFArray.h"
#import "OFData.h"
#import "OFDate.h"
#import "OFFile.h"
#import "OFFileManager.h"
#import "OFIRI.h"
#import "OFLocale.h"
#import "OFNumber.h"
#import "OFSystemInfo.h"

#ifdef OF_HAVE_THREADS
# import "OFMutex.h"
#endif

#import "OFCreateDirectoryFailedException.h"
#import "OFCreateSymbolicLinkFailedException.h"
#import "OFGetItemAttributesFailedException.h"
#import "OFInitializationFailedException.h"
#import "OFInvalidArgumentException.h"
#import "OFLinkItemFailedException.h"
#import "OFMoveItemFailedException.h"
#import "OFNotImplementedException.h"
#import "OFOpenItemFailedException.h"
#import "OFOutOfRangeException.h"
#import "OFReadFailedException.h"
#import "OFRemoveItemFailedException.h"
#import "OFSetItemAttributesFailedException.h"

#ifdef OF_WINDOWS
# include <windows.h>
# include <direct.h>
# include <ntdef.h>
# include <wchar.h>
#endif

#ifdef OF_AMIGAOS
# define Class IntuitionClass
# include <proto/exec.h>
# include <proto/dos.h>
# include <proto/locale.h>
# undef Class
# ifdef OF_AMIGAOS4
#  define DeleteFile(path) Delete(path)
# endif
#endif

#if defined(OF_WINDOWS) || defined(OF_AMIGAOS)
typedef struct {
	OFStreamOffset st_size;
	unsigned int st_mode;
	OFTimeInterval st_atime, st_mtime, st_ctime;
# ifdef OF_WINDOWS
#  define HAVE_STRUCT_STAT_ST_BIRTHTIME
	OFTimeInterval st_birthtime;
	DWORD fileAttributes;
# endif
} Stat;
#elif defined(HAVE_STAT64)
typedef struct stat64 Stat;
#else
typedef struct stat Stat;
#endif

#ifdef OF_WINDOWS
# define S_IFLNK 0x10000
# define S_ISLNK(mode) (mode & S_IFLNK)
#endif

#if defined(OF_FILE_MANAGER_SUPPORTS_OWNER) && defined(OF_HAVE_THREADS)
static OFMutex *passwdMutex;

static void
releasePasswdMutex(void)
{
	[passwdMutex release];
}
#endif
#if !defined(HAVE_READDIR_R) && defined(OF_HAVE_THREADS) && !defined(OF_WINDOWS)
static OFMutex *readdirMutex;

static void
releaseReaddirMutex(void)
{
	[readdirMutex release];
}
#endif

#ifdef OF_WINDOWS
static int (*_wutime64FuncPtr)(const wchar_t *, struct __utimbuf64 *);
static WINAPI BOOLEAN (*createSymbolicLinkWFuncPtr)(LPCWSTR, LPCWSTR, DWORD);
static WINAPI BOOLEAN (*createHardLinkWFuncPtr)(LPCWSTR, LPCWSTR,
    LPSECURITY_ATTRIBUTES);
#endif

#ifdef OF_WINDOWS
static OFTimeInterval
filetimeToTimeInterval(const FILETIME *filetime)
{
	return (double)((int64_t)filetime->dwHighDateTime << 32 |
	    filetime->dwLowDateTime) / 10000000.0 - 11644473600.0;
}

static int
lastError(void)
{
	switch (GetLastError()) {
	case ERROR_FILE_NOT_FOUND:
	case ERROR_PATH_NOT_FOUND:
	case ERROR_NO_MORE_FILES:
		return ENOENT;
	case ERROR_ACCESS_DENIED:
		return EACCES;
	case ERROR_PRIVILEGE_NOT_HELD:
		return EPERM;
	case ERROR_DIRECTORY:
		return ENOTDIR;
	case ERROR_NOT_READY:
		return EBUSY;
	default:
		return EIO;
	}
}
#endif

#ifdef OF_AMIGAOS
static int
lastError(void)
{
	switch (IoErr()) {
	case ERROR_DELETE_PROTECTED:
	case ERROR_READ_PROTECTED:
	case ERROR_WRITE_PROTECTED:
		return EACCES;
	case ERROR_DISK_NOT_VALIDATED:
	case ERROR_OBJECT_IN_USE:
		return EBUSY;
	case ERROR_OBJECT_EXISTS:
		return EEXIST;
	case ERROR_DIR_NOT_FOUND:
	case ERROR_NO_MORE_ENTRIES:
	case ERROR_OBJECT_NOT_FOUND:
		return ENOENT;
	case ERROR_NO_FREE_STORE:
		return ENOMEM;
	case ERROR_DISK_FULL:
		return ENOSPC;
	case ERROR_DIRECTORY_NOT_EMPTY:
		return ENOTEMPTY;
	case ERROR_DISK_WRITE_PROTECTED:
		return EROFS;
	case ERROR_RENAME_ACROSS_DEVICES:
		return EXDEV;
	default:
		return EIO;
	}
}
#endif

static int
statWrapper(OFString *path, Stat *buffer)
{
#if defined(OF_WINDOWS)
	WIN32_FILE_ATTRIBUTE_DATA data;
	bool success;

	if ([OFSystemInfo isWindowsNT])
		success = GetFileAttributesExW(path.UTF16String,
		    GetFileExInfoStandard, &data);
	else
		success = GetFileAttributesExA(
		    [path cStringWithEncoding: [OFLocale encoding]],
		    GetFileExInfoStandard, &data);

	if (!success)
		return lastError();

	buffer->st_size = (uint64_t)data.nFileSizeHigh << 32 |
	    data.nFileSizeLow;

	if (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
		buffer->st_mode = S_IFDIR;
	else if (data.dwFileAttributes & FILE_ATTRIBUTE_REPARSE_POINT) {
		/*
		 * No need to use A functions in this branch: This is only
		 * available on NTFS (and hence Windows NT) anyway.
		 */
		WIN32_FIND_DATAW findData;
		HANDLE findHandle;

		if ((findHandle = FindFirstFileW(path.UTF16String,
		    &findData)) == INVALID_HANDLE_VALUE)
			return lastError();

		@try {
			if (!(findData.dwFileAttributes &
			    FILE_ATTRIBUTE_REPARSE_POINT))
				/* Race? Indicate to try again. */
				return EAGAIN;

			buffer->st_mode =
			    (findData.dwReserved0 == IO_REPARSE_TAG_SYMLINK
			    ? S_IFLNK : S_IFREG);
		} @finally {
			FindClose(findHandle);
		}
	} else
		buffer->st_mode = S_IFREG;

	buffer->st_mode |= (data.dwFileAttributes & FILE_ATTRIBUTE_READONLY
	    ? (S_IRUSR | S_IXUSR) : (S_IRUSR | S_IWUSR | S_IXUSR));

	buffer->st_atime = filetimeToTimeInterval(&data.ftLastAccessTime);
	buffer->st_mtime = filetimeToTimeInterval(&data.ftLastWriteTime);
	buffer->st_ctime = buffer->st_birthtime =
	    filetimeToTimeInterval(&data.ftCreationTime);
	buffer->fileAttributes = data.dwFileAttributes;

	return 0;
#elif defined(OF_AMIGAOS)
	BPTR lock;
# ifdef OF_AMIGAOS4
	struct ExamineData *ed;
# else
	struct FileInfoBlock fib;
# endif
	OFTimeInterval timeInterval;
	struct Locale *locale;
	struct DateStamp *date;

	if ((lock = Lock([path cStringWithEncoding: [OFLocale encoding]],
	    SHARED_LOCK)) == 0)
		return lastError();

# if defined(OF_MORPHOS)
	if (!Examine64(lock, &fib, TAG_DONE)) {
# elif defined(OF_AMIGAOS4)
	if ((ed = ExamineObjectTags(EX_FileLockInput, lock, TAG_END)) == NULL) {
# else
	if (!Examine(lock, &fib)) {
# endif
		int error = lastError();
		UnLock(lock);
		return error;
	}

	UnLock(lock);

# if defined(OF_MORPHOS)
	buffer->st_size = fib.fib_Size64;
# elif defined(OF_AMIGAOS4)
	buffer->st_size = ed->FileSize;
# else
	buffer->st_size = fib.fib_Size;
# endif
# ifdef OF_AMIGAOS4
	buffer->st_mode = (EXD_IS_DIRECTORY(ed) ? S_IFDIR : S_IFREG);
# else
	buffer->st_mode = (fib.fib_DirEntryType > 0 ? S_IFDIR : S_IFREG);
# endif

	timeInterval = 252460800;	/* 1978-01-01 */

	locale = OpenLocale(NULL);
	/*
	 * FIXME: This does not take DST into account. But unfortunately, there
	 * is no way to figure out if DST was in effect when the file was
	 * modified.
	 */
	timeInterval += locale->loc_GMTOffset * 60.0;
	CloseLocale(locale);

# ifdef OF_AMIGAOS4
	date = &ed->Date;
# else
	date = &fib.fib_Date;
# endif
	timeInterval += date->ds_Days * 86400.0;
	timeInterval += date->ds_Minute * 60.0;
	timeInterval += date->ds_Tick / (OFTimeInterval)TICKS_PER_SECOND;

	buffer->st_atime = buffer->st_mtime = buffer->st_ctime = timeInterval;

# ifdef OF_AMIGAOS4
	FreeDosObject(DOS_EXAMINEDATA, ed);
# endif

	return 0;
#elif defined(HAVE_STAT64)
	if (stat64([path cStringWithEncoding: [OFLocale encoding]],
	    buffer) != 0)
		return errno;

	return 0;
#else
	if (stat([path cStringWithEncoding: [OFLocale encoding]], buffer) != 0)
		return errno;

	return 0;
#endif
}

static int
lstatWrapper(OFString *path, Stat *buffer)
{
#if defined(HAVE_LSTAT) && !defined(OF_WINDOWS) && !defined(OF_AMIGAOS) && \
    !defined(OF_NINTENDO_3DS) && !defined(OF_WII)
# ifdef HAVE_LSTAT64
	if (lstat64([path cStringWithEncoding: [OFLocale encoding]],
	    buffer) != 0)
		return errno;
# else
	if (lstat([path cStringWithEncoding: [OFLocale encoding]], buffer) != 0)
		return errno;
# endif

	return 0;
#else
	return statWrapper(path, buffer);
#endif
}

static void
setTypeAttribute(OFMutableFileAttributes attributes, Stat *s)
{
	if (S_ISREG(s->st_mode))
		[attributes setObject: OFFileTypeRegular forKey: OFFileType];
	else if (S_ISDIR(s->st_mode))
		[attributes setObject: OFFileTypeDirectory forKey: OFFileType];
#ifdef S_ISLNK
	else if (S_ISLNK(s->st_mode))
		[attributes setObject: OFFileTypeSymbolicLink
			       forKey: OFFileType];
#endif
#ifdef S_ISFIFO
	else if (S_ISFIFO(s->st_mode))
		[attributes setObject: OFFileTypeFIFO forKey: OFFileType];
#endif
#ifdef S_ISCHR
	else if (S_ISCHR(s->st_mode))
		[attributes setObject: OFFileTypeCharacterSpecial
			       forKey: OFFileType];
#endif
#ifdef S_ISBLK
	else if (S_ISBLK(s->st_mode))
		[attributes setObject: OFFileTypeBlockSpecial
			       forKey: OFFileType];
#endif
#ifdef S_ISSOCK
	else if (S_ISSOCK(s->st_mode))
		[attributes setObject: OFFileTypeSocket forKey: OFFileType];
#endif
	else
		[attributes setObject: OFFileTypeUnknown forKey: OFFileType];
}

static void
setDateAttributes(OFMutableFileAttributes attributes, Stat *s)
{
	/* FIXME: We could be more precise on some OSes */
	[attributes
	    setObject: [OFDate dateWithTimeIntervalSince1970: s->st_atime]
	       forKey: OFFileLastAccessDate];
	[attributes
	    setObject: [OFDate dateWithTimeIntervalSince1970: s->st_mtime]
	       forKey: OFFileModificationDate];
	[attributes
	    setObject: [OFDate dateWithTimeIntervalSince1970: s->st_ctime]
	       forKey: OFFileStatusChangeDate];
#ifdef HAVE_STRUCT_STAT_ST_BIRTHTIME
	[attributes
	    setObject: [OFDate dateWithTimeIntervalSince1970: s->st_birthtime]
	       forKey: OFFileCreationDate];
#endif
}

static void
setOwnerAndGroupAttributes(OFMutableFileAttributes attributes, Stat *s)
{
#ifdef OF_FILE_MANAGER_SUPPORTS_OWNER
	[attributes setObject: [NSNumber numberWithUnsignedLong: s->st_uid]
		       forKey: OFFileOwnerAccountID];
	[attributes setObject: [NSNumber numberWithUnsignedLong: s->st_gid]
		       forKey: OFFileGroupOwnerAccountID];

# ifdef OF_HAVE_THREADS
	[passwdMutex lock];
	@try {
# endif
		OFStringEncoding encoding = [OFLocale encoding];
		struct passwd *passwd = getpwuid(s->st_uid);
		struct group *group_ = getgrgid(s->st_gid);

		if (passwd != NULL) {
			OFString *owner = [OFString
			    stringWithCString: passwd->pw_name
				     encoding: encoding];

			[attributes setObject: owner
				       forKey: OFFileOwnerAccountName];
		}

		if (group_ != NULL) {
			OFString *group = [OFString
			    stringWithCString: group_->gr_name
				     encoding: encoding];

			[attributes setObject: group
				       forKey: OFFileGroupOwnerAccountName];
		}
# ifdef OF_HAVE_THREADS
	} @finally {
		[passwdMutex unlock];
	}
# endif
#endif
}

#ifdef OF_FILE_MANAGER_SUPPORTS_SYMLINKS
static void
setSymbolicLinkDestinationAttribute(OFMutableFileAttributes attributes,
    OFIRI *IRI)
{
	OFString *path = IRI.fileSystemRepresentation;
# ifdef OF_WINDOWS
	HANDLE handle;
	OFString *destination;

	if (createSymbolicLinkWFuncPtr == NULL)
		return;

	if ((handle = CreateFileW(path.UTF16String, 0, (FILE_SHARE_READ |
	    FILE_SHARE_WRITE), NULL, OPEN_EXISTING,
	    FILE_FLAG_OPEN_REPARSE_POINT, NULL)) == INVALID_HANDLE_VALUE)
		@throw [OFGetItemAttributesFailedException
		    exceptionWithIRI: IRI
			       errNo: lastError()];

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
			@throw [OFGetItemAttributesFailedException
			    exceptionWithIRI: IRI
				       errNo: lastError()];

		if (buffer.data.ReparseTag != IO_REPARSE_TAG_SYMLINK)
			@throw [OFGetItemAttributesFailedException
			    exceptionWithIRI: IRI
				       errNo: lastError()];

#  define slrb buffer.data.SymbolicLinkReparseBuffer
		tmp = slrb.PathBuffer +
		    (slrb.SubstituteNameOffset / sizeof(wchar_t));

		destination = [OFString
		    stringWithUTF16String: tmp
				   length: slrb.SubstituteNameLength /
					   sizeof(wchar_t)];

		[attributes setObject: OFFileTypeSymbolicLink
			       forKey: OFFileType];
		[attributes setObject: destination
			       forKey: OFFileSymbolicLinkDestination];
#  undef slrb
	} @finally {
		CloseHandle(handle);
	}
# elif defined(OF_HURD)
	OFStringEncoding encoding = [OFLocale encoding];
	int fd;
	OFMutableData *destinationData;
	OFString *destination;

	fd = open([path cStringWithEncoding: encoding], O_RDONLY | O_NOLINK);
	if (fd == -1)
		@throw [OFGetItemAttributesFailedException
		    exceptionWithIRI: IRI
			       errNo: errno];

	@try {
		char buffer[512];
		ssize_t length;

		destinationData = [OFMutableData data];
		while ((length = read(fd, buffer, 512)) > 0)
			[destinationData addItems: buffer count: length];
	} @finally {
		close(fd);
	}

	destination = [OFString stringWithCString: destinationData.items
					 encoding: encoding
					   length: destinationData.count];

	[attributes setObject: destination
		       forKey: OFFileSymbolicLinkDestination];
# else
	OFStringEncoding encoding = [OFLocale encoding];
	char destinationC[PATH_MAX];
	ssize_t length;
	OFString *destination;

	length = readlink([path cStringWithEncoding: encoding], destinationC,
	    PATH_MAX);

	if (length < 0)
		@throw [OFGetItemAttributesFailedException
		    exceptionWithIRI: IRI
			       errNo: errno];

	destination = [OFString stringWithCString: destinationC
					 encoding: encoding
					   length: length];

	[attributes setObject: destination
		       forKey: OFFileSymbolicLinkDestination];
# endif
}
#endif

#ifdef OF_FILE_MANAGER_SUPPORTS_EXTENDED_ATTRIBUTES
static void
setExtendedAttributes(OFMutableFileAttributes attributes, OFIRI *IRI)
{
	OFString *path = IRI.fileSystemRepresentation;
	OFStringEncoding encoding = [OFLocale encoding];
	const char *cPath = [path cStringWithEncoding: encoding];
# if defined(OF_LINUX)
	ssize_t size = llistxattr(cPath, NULL, 0);
# elif defined(OF_MACOS)
	ssize_t size = listxattr(cPath, NULL, 0, XATTR_NOFOLLOW);
# endif
	char *list = OFAllocMemory(1, size);
	OFMutableArray *names = nil;

	@try {
		char *name;

# if defined(OF_LINUX)
		if ((size = llistxattr(cPath, list, size)) < 0)
# elif defined(OF_MACOS)
		if ((size = listxattr(cPath, list, size, XATTR_NOFOLLOW)) < 0)
# endif
			return;

		names = [OFMutableArray array];
		name = list;

		while (size > 0) {
			size_t length = strlen(name);

			[names addObject: [OFString stringWithCString: name
							     encoding: encoding
							       length: length]];

			name += length + 1;
			size -= length + 1;
		}
	} @finally {
		OFFreeMemory(list);
	}

	[attributes setObject: names forKey: OFFileExtendedAttributesNames];
}
#endif

@implementation OFFileIRIHandler
+ (void)initialize
{
#ifdef OF_WINDOWS
	HMODULE module;
#endif

	if (self != [OFFileIRIHandler class])
		return;

#if defined(OF_FILE_MANAGER_SUPPORTS_OWNER) && defined(OF_HAVE_THREADS)
	passwdMutex = [[OFMutex alloc] init];
	atexit(releasePasswdMutex);
#endif
#if !defined(HAVE_READDIR_R) && !defined(OF_WINDOWS) && defined(OF_HAVE_THREADS)
	readdirMutex = [[OFMutex alloc] init];
	atexit(releaseReaddirMutex);
#endif

#ifdef OF_WINDOWS
	if ((module = GetModuleHandle("msvcrt.dll")) != NULL)
		_wutime64FuncPtr = (int (*)(const wchar_t *,
		    struct __utimbuf64 *))GetProcAddress(module, "_wutime64");

	if ((module = GetModuleHandleA("kernel32.dll")) != NULL) {
		createSymbolicLinkWFuncPtr =
		    (WINAPI BOOLEAN (*)(LPCWSTR, LPCWSTR, DWORD))
		    GetProcAddress(module, "CreateSymbolicLinkW");
		createHardLinkWFuncPtr =
		    (WINAPI BOOLEAN (*)(LPCWSTR, LPCWSTR,
		    LPSECURITY_ATTRIBUTES))
		    GetProcAddress(module, "CreateHardLinkW");
	}
#endif

	/*
	 * Make sure OFFile is initialized.
	 * On some systems, this is needed to initialize the file system driver.
	 */
	[OFFile class];
}

+ (bool)of_directoryExistsAtPath: (OFString *)path
{
	Stat s;

	if (statWrapper(path, &s) != 0)
		return false;

	return S_ISDIR(s.st_mode);
}

- (OFStream *)openItemAtIRI: (OFIRI *)IRI mode: (OFString *)mode
{
	void *pool = objc_autoreleasePoolPush();
	OFFile *file;

	@try {
		file = [OFFile fileWithPath: IRI.fileSystemRepresentation
				       mode: mode];
	} @catch (OFOpenItemFailedException *e) {
		/* The thrown one has a path instead of an IRI set. */
		@throw [OFOpenItemFailedException exceptionWithIRI: IRI
							      mode: mode
							     errNo: e.errNo];
	}

	[file retain];

	objc_autoreleasePoolPop(pool);

	return [file autorelease];
}

- (OFFileAttributes)attributesOfItemAtIRI: (OFIRI *)IRI
{
	OFMutableFileAttributes ret = [OFMutableDictionary dictionary];
	void *pool = objc_autoreleasePoolPush();
	OFString *path;
	int error;
	Stat s;

	if (IRI == nil)
		@throw [OFInvalidArgumentException exception];

	if (![[IRI scheme] isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	path = IRI.fileSystemRepresentation;

	if ((error = lstatWrapper(path, &s)) != 0)
		@throw [OFGetItemAttributesFailedException
		    exceptionWithIRI: IRI
			       errNo: error];

	if (s.st_size < 0)
		@throw [OFOutOfRangeException exception];

	[ret setObject: [NSNumber numberWithUnsignedLongLong: s.st_size]
		forKey: OFFileSize];

	setTypeAttribute(ret, &s);

	[ret setObject: [NSNumber numberWithUnsignedLong: s.st_mode]
		forKey: OFFilePOSIXPermissions];

	setOwnerAndGroupAttributes(ret, &s);
	setDateAttributes(ret, &s);

#ifdef OF_FILE_MANAGER_SUPPORTS_SYMLINKS
	if (S_ISLNK(s.st_mode))
		setSymbolicLinkDestinationAttribute(ret, IRI);
#endif

#ifdef OF_FILE_MANAGER_SUPPORTS_EXTENDED_ATTRIBUTES
	setExtendedAttributes(ret, IRI);
#endif

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (void)of_setLastAccessDate: (OFDate *)lastAccessDate
	 andModificationDate: (OFDate *)modificationDate
		 ofItemAtIRI: (OFIRI *)IRI
		  attributes: (OFFileAttributes)attributes OF_DIRECT
{
	OFString *path = IRI.fileSystemRepresentation;
	OFFileAttributeKey attributeKey = (modificationDate != nil
	    ? OFFileModificationDate : OFFileLastAccessDate);

	if (lastAccessDate == nil)
		lastAccessDate = modificationDate;
	if (modificationDate == nil)
		modificationDate = lastAccessDate;

#if defined(OF_WINDOWS)
	if (_wutime64FuncPtr != NULL) {
		struct __utimbuf64 times = {
			.actime =
			    (__time64_t)lastAccessDate.timeIntervalSince1970,
			.modtime =
			    (__time64_t)modificationDate.timeIntervalSince1970
		};

		if (_wutime64FuncPtr([path UTF16String], &times) != 0) {
			int errNo = errno;

			if (errNo == EACCES && [self directoryExistsAtIRI: IRI])
				errNo = EISDIR;

			@throw [OFSetItemAttributesFailedException
			    exceptionWithIRI: IRI
				  attributes: attributes
			     failedAttribute: attributeKey
				       errNo: errNo];
		}
	} else {
		struct _utimbuf times = {
			.actime = (time_t)lastAccessDate.timeIntervalSince1970,
			.modtime =
			    (time_t)modificationDate.timeIntervalSince1970
		};
		int status;

		if ([OFSystemInfo isWindowsNT])
			status = _wutime([path UTF16String], &times);
		else
			status = _utime(
			    [path cStringWithEncoding: [OFLocale encoding]],
			    &times);

		if (status != 0) {
			int errNo = errno;

			if (errNo == EACCES && [self directoryExistsAtIRI: IRI])
				errNo = EISDIR;

			@throw [OFSetItemAttributesFailedException
			    exceptionWithIRI: IRI
				  attributes: attributes
			     failedAttribute: attributeKey
				       errNo: errNo];
		}
	}
#elif defined(OF_AMIGAOS)
	/* AmigaOS does not support access time. */
	OFTimeInterval modificationTime =
	    modificationDate.timeIntervalSince1970;
	struct Locale *locale;
	struct DateStamp date;

	modificationTime -= 252460800;	/* 1978-01-01 */

	if (modificationTime < 0)
		@throw [OFOutOfRangeException exception];

	locale = OpenLocale(NULL);
	/*
	 * FIXME: This does not take DST into account. But unfortunately, there
	 *	  is no way to figure out if DST should be in effect for the
	 *	  timestamp.
	 */
	modificationTime -= locale->loc_GMTOffset * 60.0;
	CloseLocale(locale);

	date.ds_Days = modificationTime / 86400;
	date.ds_Minute = ((LONG)modificationTime % 86400) / 60;
	date.ds_Tick = fmod(modificationTime, 60) * TICKS_PER_SECOND;

# ifdef OF_AMIGAOS4
	if (!SetDate([path cStringWithEncoding: [OFLocale encoding]],
	    &date) != 0)
# else
	if (!SetFileDate([path cStringWithEncoding: [OFLocale encoding]],
	    &date) != 0)
# endif
		@throw [OFSetItemAttributesFailedException
		    exceptionWithIRI: IRI
			  attributes: attributes
		     failedAttribute: attributeKey
			       errNo: lastError()];
#else
	OFTimeInterval lastAccessTime = lastAccessDate.timeIntervalSince1970;
	OFTimeInterval modificationTime =
	    modificationDate.timeIntervalSince1970;
	struct timeval times[2] = {
		{
			.tv_sec = (time_t)lastAccessTime,
			.tv_usec = (int)((lastAccessTime -
			    (time_t)lastAccessTime) * 1000000)
		},
		{
			.tv_sec = (time_t)modificationTime,
			.tv_usec = (int)((modificationTime -
			    (time_t)modificationTime) * 1000000)
		},
	};

	if (utimes([path cStringWithEncoding: [OFLocale encoding]], times) != 0)
		@throw [OFSetItemAttributesFailedException
		    exceptionWithIRI: IRI
			  attributes: attributes
		     failedAttribute: attributeKey
			       errNo: errno];
#endif
}

- (void)of_setPOSIXPermissions: (OFNumber *)permissions
		   ofItemAtIRI: (OFIRI *)IRI
		    attributes: (OFFileAttributes)attributes OF_DIRECT
{
#ifdef OF_FILE_MANAGER_SUPPORTS_PERMISSIONS
	mode_t mode = (mode_t)permissions.unsignedLongValue;
	OFString *path = IRI.fileSystemRepresentation;
	int status;

# ifdef OF_WINDOWS
	if ([OFSystemInfo isWindowsNT])
		status = _wchmod(path.UTF16String, mode);
	else
# endif
		status = chmod(
		    [path cStringWithEncoding: [OFLocale encoding]], mode);

	if (status != 0)
		@throw [OFSetItemAttributesFailedException
		    exceptionWithIRI: IRI
			  attributes: attributes
		     failedAttribute: OFFilePOSIXPermissions
			       errNo: errno];
#else
	OF_UNRECOGNIZED_SELECTOR
#endif
}

- (void)of_setOwnerAccountName: (OFString *)owner
      andGroupOwnerAccountName: (OFString *)group
		   ofItemAtIRI: (OFIRI *)IRI
		  attributeKey: (OFFileAttributeKey)attributeKey
		    attributes: (OFFileAttributes)attributes OF_DIRECT
{
#ifdef OF_FILE_MANAGER_SUPPORTS_OWNER
	OFString *path = IRI.fileSystemRepresentation;
	uid_t uid = -1;
	gid_t gid = -1;
	OFStringEncoding encoding;

	if (owner == nil && group == nil)
		@throw [OFInvalidArgumentException exception];

	encoding = [OFLocale encoding];

# ifdef OF_HAVE_THREADS
	[passwdMutex lock];
	@try {
# endif
		if (owner != nil) {
			struct passwd *passwd;

			if ((passwd = getpwnam([owner
			    cStringWithEncoding: encoding])) == NULL)
				@throw [OFSetItemAttributesFailedException
				    exceptionWithIRI: IRI
					  attributes: attributes
				     failedAttribute: attributeKey
					       errNo: errno];

			uid = passwd->pw_uid;
		}

		if (group != nil) {
			struct group *group_;

			if ((group_ = getgrnam([group
			    cStringWithEncoding: encoding])) == NULL)
				@throw [OFSetItemAttributesFailedException
				    exceptionWithIRI: IRI
					  attributes: attributes
				     failedAttribute: attributeKey
					       errNo: errno];

			gid = group_->gr_gid;
		}
# ifdef OF_HAVE_THREADS
	} @finally {
		[passwdMutex unlock];
	}
# endif

	if (chown([path cStringWithEncoding: encoding], uid, gid) != 0)
		@throw [OFSetItemAttributesFailedException
		    exceptionWithIRI: IRI
			  attributes: attributes
		     failedAttribute: attributeKey
			       errNo: errno];
#else
	OF_UNRECOGNIZED_SELECTOR
#endif
}

- (void)setAttributes: (OFFileAttributes)attributes ofItemAtIRI: (OFIRI *)IRI
{
	void *pool = objc_autoreleasePoolPush();
	OFEnumerator OF_GENERIC(OFFileAttributeKey) *keyEnumerator;
	OFEnumerator *objectEnumerator;
	OFFileAttributeKey key;
	id object;
	OFDate *lastAccessDate, *modificationDate;

	if (IRI == nil)
		@throw [OFInvalidArgumentException exception];

	if (![IRI.scheme isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	keyEnumerator = [attributes keyEnumerator];
	objectEnumerator = [attributes objectEnumerator];

	while ((key = [keyEnumerator nextObject]) != nil &&
	    (object = [objectEnumerator nextObject]) != nil) {
		if ([key isEqual: OFFileModificationDate] ||
		    [key isEqual: OFFileLastAccessDate])
			continue;
		else if ([key isEqual: OFFilePOSIXPermissions])
			[self of_setPOSIXPermissions: object
					 ofItemAtIRI: IRI
					  attributes: attributes];
		else if ([key isEqual: OFFileOwnerAccountName])
			[self of_setOwnerAccountName: object
			    andGroupOwnerAccountName: nil
					 ofItemAtIRI: IRI
					attributeKey: key
					  attributes: attributes];
		else if ([key isEqual: OFFileGroupOwnerAccountName])
			[self of_setOwnerAccountName: nil
			    andGroupOwnerAccountName: object
					 ofItemAtIRI: IRI
					attributeKey: key
					  attributes: attributes];
		else
			@throw [OFNotImplementedException
			    exceptionWithSelector: _cmd
					   object: self];
	}

	lastAccessDate = [attributes objectForKey: OFFileLastAccessDate];
	modificationDate = [attributes objectForKey: OFFileModificationDate];

	if (lastAccessDate != nil || modificationDate != nil)
		[self of_setLastAccessDate: lastAccessDate
		       andModificationDate: modificationDate
			       ofItemAtIRI: IRI
				attributes: attributes];

	objc_autoreleasePoolPop(pool);
}

- (bool)fileExistsAtIRI: (OFIRI *)IRI
{
	void *pool = objc_autoreleasePoolPush();
	Stat s;
	bool ret;

	if (IRI == nil)
		@throw [OFInvalidArgumentException exception];

	if (![IRI.scheme isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	ret = (statWrapper(IRI.fileSystemRepresentation, &s) == 0);

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (bool)directoryExistsAtIRI: (OFIRI *)IRI
{
	void *pool = objc_autoreleasePoolPush();
	Stat s;
	bool ret;

	if (IRI == nil)
		@throw [OFInvalidArgumentException exception];

	if (![IRI.scheme isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	if (statWrapper(IRI.fileSystemRepresentation, &s) != 0) {
		objc_autoreleasePoolPop(pool);
		return false;
	}

	ret = S_ISDIR(s.st_mode);

	objc_autoreleasePoolPop(pool);

	return ret;
}

- (void)createDirectoryAtIRI: (OFIRI *)IRI
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path;

	if (IRI == nil)
		@throw [OFInvalidArgumentException exception];

	if (![IRI.scheme isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	path = IRI.fileSystemRepresentation;

#if defined(OF_WINDOWS)
	int status;

	if ([OFSystemInfo isWindowsNT])
		status = _wmkdir(path.UTF16String);
	else
		status = _mkdir(
		    [path cStringWithEncoding: [OFLocale encoding]]);

	if (status != 0)
		@throw [OFCreateDirectoryFailedException
		    exceptionWithIRI: IRI
			       errNo: errno];
#elif defined(OF_AMIGAOS)
	BPTR lock;

	if ((lock = CreateDir(
	    [path cStringWithEncoding: [OFLocale encoding]])) == 0)
		@throw [OFCreateDirectoryFailedException
		    exceptionWithIRI: IRI
			       errNo: lastError()];

	UnLock(lock);
#else
	if (mkdir([path cStringWithEncoding: [OFLocale encoding]], 0777) != 0)
		@throw [OFCreateDirectoryFailedException
		    exceptionWithIRI: IRI
			       errNo: errno];
#endif

	objc_autoreleasePoolPop(pool);
}

- (OFArray OF_GENERIC(OFIRI *) *)contentsOfDirectoryAtIRI: (OFIRI *)IRI
{
	OFMutableArray *IRIs = [OFMutableArray array];
	void *pool = objc_autoreleasePoolPush();
	OFString *path;

	if (IRI == nil)
		@throw [OFInvalidArgumentException exception];

	if (![IRI.scheme isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	path = IRI.fileSystemRepresentation;

#if defined(OF_WINDOWS)
	HANDLE handle;

	path = [path stringByAppendingString: @"\\*"];

	if ([OFSystemInfo isWindowsNT]) {
		WIN32_FIND_DATAW fd;

		if ((handle = FindFirstFileW(path.UTF16String,
		    &fd)) == INVALID_HANDLE_VALUE)
			@throw [OFOpenItemFailedException
			    exceptionWithIRI: IRI
					mode: nil
				       errNo: lastError()];

		@try {
			do {
				OFString *file;

				if (wcscmp(fd.cFileName, L".") == 0 ||
				    wcscmp(fd.cFileName, L"..") == 0)
					continue;

				file = [[OFString alloc]
				    initWithUTF16String: fd.cFileName];
				@try {
					[IRIs addObject: [IRI
					    IRIByAppendingPathComponent: file]];
				} @finally {
					[file release];
				}
			} while (FindNextFileW(handle, &fd));

			if (GetLastError() != ERROR_NO_MORE_FILES)
				@throw [OFReadFailedException
				    exceptionWithObject: self
					requestedLength: 0
						  errNo: lastError()];
		} @finally {
			FindClose(handle);
		}
	} else {
		OFStringEncoding encoding = [OFLocale encoding];
		WIN32_FIND_DATA fd;

		if ((handle = FindFirstFileA(
		    [path cStringWithEncoding: encoding], &fd)) ==
		    INVALID_HANDLE_VALUE)
			@throw [OFOpenItemFailedException
			    exceptionWithIRI: IRI
					mode: nil
				       errNo: lastError()];

		@try {
			do {
				OFString *file;

				if (strcmp(fd.cFileName, ".") == 0 ||
				    strcmp(fd.cFileName, "..") == 0)
					continue;

				file = [[OFString alloc]
				    initWithCString: fd.cFileName
					   encoding: encoding];
				@try {
					[IRIs addObject: [IRI
					    IRIByAppendingPathComponent: file]];
				} @finally {
					[file release];
				}
			} while (FindNextFileA(handle, &fd));

			if (GetLastError() != ERROR_NO_MORE_FILES)
				@throw [OFReadFailedException
				    exceptionWithObject: self
					requestedLength: 0
						  errNo: lastError()];
		} @finally {
			FindClose(handle);
		}
	}
#elif defined(OF_AMIGAOS)
	OFStringEncoding encoding = [OFLocale encoding];
	BPTR lock;

	if ((lock = Lock([path cStringWithEncoding: encoding],
	    SHARED_LOCK)) == 0)
		@throw [OFOpenItemFailedException
		    exceptionWithIRI: IRI
				mode: nil
			       errNo: lastError()];

	@try {
# ifdef OF_AMIGAOS4
		struct ExamineData *ed;
		APTR context;

		if ((context = ObtainDirContextTags(EX_FileLockInput, lock,
		    EX_DoCurrentDir, TRUE, EX_DataFields, EXF_NAME,
		    TAG_END)) == NULL)
			@throw [OFOpenItemFailedException
			    exceptionWithIRI: IRI
					mode: nil
				       errNo: lastError()];

		@try {
			while ((ed = ExamineDir(context)) != NULL) {
				OFString *file = [[OFString alloc]
				    initWithCString: ed->Name
					   encoding: encoding];

				@try {
					[IRIs addObject: [IRI
					    IRIByAppendingPathComponent: file]];
				} @finally {
					[file release];
				}
			}
		} @finally {
			ReleaseDirContext(context);
		}
# else
		struct FileInfoBlock fib;

		if (!Examine(lock, &fib))
			@throw [OFOpenItemFailedException
			    exceptionWithIRI: IRI
					mode: nil
				       errNo: lastError()];

		while (ExNext(lock, &fib)) {
			OFString *file = [[OFString alloc]
			    initWithCString: fib.fib_FileName
				   encoding: encoding];
			@try {
				[IRIs addObject:
				    [IRI IRIByAppendingPathComponent: file]];
			} @finally {
				[file release];
			}
		}
# endif

		if (IoErr() != ERROR_NO_MORE_ENTRIES)
			@throw [OFReadFailedException
			    exceptionWithObject: self
				requestedLength: 0
					  errNo: lastError()];
	} @finally {
		UnLock(lock);
	}
#else
	OFStringEncoding encoding = [OFLocale encoding];
	DIR *dir;
	if ((dir = opendir([path cStringWithEncoding: encoding])) == NULL)
		@throw [OFOpenItemFailedException exceptionWithIRI: IRI
							      mode: nil
							     errNo: errno];

# if !defined(HAVE_READDIR_R) && defined(OF_HAVE_THREADS)
	@try {
		[readdirMutex lock];
	} @catch (id e) {
		closedir(dir);
		@throw e;
	}
# endif

	@try {
		for (;;) {
			struct dirent *dirent;
# ifdef HAVE_READDIR_R
			struct dirent buffer;
# endif
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
			errno = 0;
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

			file = [[OFString alloc] initWithCString: dirent->d_name
							encoding: encoding];
			@try {
				[IRIs addObject:
				    [IRI IRIByAppendingPathComponent: file]];
			} @finally {
				[file release];
			}
		}
	} @finally {
		closedir(dir);
# if !defined(HAVE_READDIR_R) && defined(OF_HAVE_THREADS)
		[readdirMutex unlock];
# endif
	}
#endif

	[IRIs makeImmutable];

	objc_autoreleasePoolPop(pool);

	return IRIs;
}

- (void)removeItemAtIRI: (OFIRI *)IRI
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path;
	int error;
	Stat s;

	if (IRI == nil)
		@throw [OFInvalidArgumentException exception];

	if (![IRI.scheme isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	path = IRI.fileSystemRepresentation;

	if ((error = lstatWrapper(path, &s)) != 0)
		@throw [OFRemoveItemFailedException exceptionWithIRI: IRI
							       errNo: error];

	if (S_ISDIR(s.st_mode)) {
		OFArray OF_GENERIC(OFIRI *) *contents;

		@try {
			contents = [self contentsOfDirectoryAtIRI: IRI];
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
				    exceptionWithIRI: IRI
					       errNo: [e errNo]];

			@throw e;
		}

		for (OFIRI *item in contents) {
			void *pool2 = objc_autoreleasePoolPush();

			[self removeItemAtIRI: item];

			objc_autoreleasePoolPop(pool2);
		}

#ifndef OF_AMIGAOS
		int status;

# ifdef OF_WINDOWS
		if ([OFSystemInfo isWindowsNT])
			status = _wrmdir(path.UTF16String);
		else
# endif
			status = rmdir(
			    [path cStringWithEncoding: [OFLocale encoding]]);

		if (status != 0)
			@throw [OFRemoveItemFailedException
				exceptionWithIRI: IRI
					   errNo: errno];
	} else {
		int status;

# ifdef OF_WINDOWS
		if ([OFSystemInfo isWindowsNT])
			status = _wunlink(path.UTF16String);
		else
# endif
			status = unlink(
			    [path cStringWithEncoding: [OFLocale encoding]]);

		if (status != 0)
			@throw [OFRemoveItemFailedException
			    exceptionWithIRI: IRI
				       errNo: errno];
#endif
	}

#ifdef OF_AMIGAOS
	if (!DeleteFile([path cStringWithEncoding: [OFLocale encoding]]))
		@throw [OFRemoveItemFailedException
		    exceptionWithIRI: IRI
			       errNo: lastError()];
#endif

	objc_autoreleasePoolPop(pool);
}

#ifdef OF_FILE_MANAGER_SUPPORTS_LINKS
- (void)linkItemAtIRI: (OFIRI *)source toIRI: (OFIRI *)destination
{
	void *pool = objc_autoreleasePoolPush();
	OFString *sourcePath, *destinationPath;

	if (source == nil || destination == nil)
		@throw [OFInvalidArgumentException exception];

	if (![source.scheme isEqual: _scheme] ||
	    ![destination.scheme isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	sourcePath = source.fileSystemRepresentation;
	destinationPath = destination.fileSystemRepresentation;

# ifndef OF_WINDOWS
	OFStringEncoding encoding = [OFLocale encoding];

	if (link([sourcePath cStringWithEncoding: encoding],
	    [destinationPath cStringWithEncoding: encoding]) != 0)
		@throw [OFLinkItemFailedException
		    exceptionWithSourceIRI: source
			    destinationIRI: destination
				     errNo: errno];
# else
	if (createHardLinkWFuncPtr == NULL)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	if (!createHardLinkWFuncPtr(destinationPath.UTF16String,
	    sourcePath.UTF16String, NULL))
		@throw [OFLinkItemFailedException
		    exceptionWithSourceIRI: source
			    destinationIRI: destination
				     errNo: lastError()];
# endif

	objc_autoreleasePoolPop(pool);
}
#endif

#ifdef OF_FILE_MANAGER_SUPPORTS_SYMLINKS
- (void)createSymbolicLinkAtIRI: (OFIRI *)IRI
	    withDestinationPath: (OFString *)target
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path;

	if (IRI == nil || target == nil)
		@throw [OFInvalidArgumentException exception];

	if (![IRI.scheme isEqual: _scheme])
		@throw [OFInvalidArgumentException exception];

	path = IRI.fileSystemRepresentation;

# ifndef OF_WINDOWS
	OFStringEncoding encoding = [OFLocale encoding];

	if (symlink([target cStringWithEncoding: encoding],
	    [path cStringWithEncoding: encoding]) != 0)
		@throw [OFCreateSymbolicLinkFailedException
		    exceptionWithIRI: IRI
			      target: target
			       errNo: errno];
# else
	if (createSymbolicLinkWFuncPtr == NULL)
		@throw [OFNotImplementedException exceptionWithSelector: _cmd
								 object: self];

	if (!createSymbolicLinkWFuncPtr(path.UTF16String, target.UTF16String,
	    0))
		@throw [OFCreateSymbolicLinkFailedException
		    exceptionWithIRI: IRI
			      target: target
			       errNo: lastError()];
# endif

	objc_autoreleasePoolPop(pool);
}
#endif

- (bool)moveItemAtIRI: (OFIRI *)source toIRI: (OFIRI *)destination
{
	void *pool;

	if (![source.scheme isEqual: _scheme] ||
	    ![destination.scheme isEqual: _scheme])
		return false;

	if ([self fileExistsAtIRI: destination])
		@throw [OFMoveItemFailedException
		    exceptionWithSourceIRI: source
			    destinationIRI: destination
				     errNo: EEXIST];

	pool = objc_autoreleasePoolPush();

#ifdef OF_AMIGAOS
	OFStringEncoding encoding = [OFLocale encoding];

	if (!Rename([source.fileSystemRepresentation
	    cStringWithEncoding: encoding],
	    [destination.fileSystemRepresentation
	    cStringWithEncoding: encoding]))
		@throw [OFMoveItemFailedException
		    exceptionWithSourceIRI: source
			    destinationIRI: destination
				     errNo: lastError()];
#else
	int status;

# ifdef OF_WINDOWS
	if ([OFSystemInfo isWindowsNT])
		status = _wrename(source.fileSystemRepresentation.UTF16String,
		    destination.fileSystemRepresentation.UTF16String);
	else {
# endif
		OFStringEncoding encoding = [OFLocale encoding];

		status = rename([source.fileSystemRepresentation
		    cStringWithEncoding: encoding],
		    [destination.fileSystemRepresentation
		    cStringWithEncoding: encoding]);
# ifdef OF_WINDOWS
	}
# endif

	if (status != 0)
		@throw [OFMoveItemFailedException
		    exceptionWithSourceIRI: source
			    destinationIRI: destination
				     errNo: errno];
#endif

	objc_autoreleasePoolPop(pool);

	return true;
}

#ifdef OF_FILE_MANAGER_SUPPORTS_EXTENDED_ATTRIBUTES
- (OFData *)extendedAttributeDataForName: (OFString *)name
			     ofItemAtIRI: (OFIRI *)IRI
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path = IRI.fileSystemRepresentation;
	OFStringEncoding encoding = [OFLocale encoding];
	const char *cPath = [path cStringWithEncoding: encoding];
	const char *cName = [name cStringWithEncoding: encoding];
# if defined(OF_LINUX)
	ssize_t size = lgetxattr(cPath, cName, NULL, 0);
# elif defined(OF_MACOS)
	ssize_t size = getxattr(cPath, cName, NULL, 0, 0, XATTR_NOFOLLOW);
# endif
	void *value;
	OFData *data;

	if (size < 0)
		@throw [OFGetItemAttributesFailedException
		    exceptionWithIRI: IRI
			       errNo: errno];

	value = OFAllocMemory(1, size);
	@try {
# if defined(OF_LINUX)
		if ((size = lgetxattr(cPath, cName, value, size)) < 0)
# elif defined(OF_MACOS)
		if ((size = getxattr(cPath, cName, value, size, 0,
		    XATTR_NOFOLLOW)) < 0)
# endif
			@throw [OFGetItemAttributesFailedException
			    exceptionWithIRI: IRI
				       errNo: errno];

		data = [OFData dataWithItems: value count: size];
	} @finally {
		OFFreeMemory(value);
	}

	[data retain];

	objc_autoreleasePoolPop(pool);

	return [data autorelease];
}

- (void)setExtendedAttributeData: (OFData *)data
			 forName: (OFString *)name
		     ofItemAtIRI: (OFIRI *)IRI
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path = IRI.fileSystemRepresentation;
	OFStringEncoding encoding = [OFLocale encoding];

# if defined(OF_LINUX)
	if (lsetxattr([path cStringWithEncoding: encoding],
	    [name cStringWithEncoding: encoding], data.items,
	    data.count * data.itemSize, 0) != 0) {
# elif defined(OF_MACOS)
	if (setxattr([path cStringWithEncoding: encoding],
	    [name cStringWithEncoding: encoding], data.items,
	    data.count * data.itemSize, 0, XATTR_NOFOLLOW) != 0) {
# endif
		int errNo = errno;

		/* TODO: Add an attribute (prefix?) for extended attributes? */
		@throw [OFSetItemAttributesFailedException
		    exceptionWithIRI: IRI
			  attributes: [OFDictionary dictionary]
		     failedAttribute: @""
			       errNo: errNo];
	}

	objc_autoreleasePoolPop(pool);
}

- (void)removeExtendedAttributeForName: (OFString *)name
			   ofItemAtIRI: (OFIRI *)IRI
{
	void *pool = objc_autoreleasePoolPush();
	OFString *path = IRI.fileSystemRepresentation;
	OFStringEncoding encoding = [OFLocale encoding];

# if defined(OF_LINUX)
	if (lremovexattr([path cStringWithEncoding: encoding],
	    [name cStringWithEncoding: encoding]) != 0) {
# elif defined(OF_MACOS)
	if (removexattr([path cStringWithEncoding: encoding],
	    [name cStringWithEncoding: encoding], XATTR_NOFOLLOW) != 0) {
# endif
		int errNo = errno;

		/* TODO: Add an attribute (prefix?) for extended attributes? */
		@throw [OFSetItemAttributesFailedException
		    exceptionWithIRI: IRI
			  attributes: [OFDictionary dictionary]
		     failedAttribute: @""
			       errNo: errNo];
	}

	objc_autoreleasePoolPop(pool);
}
#endif
@end
