/*
 * Copyright (c) 2008, 2009, 2010, 2011
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

#include <string.h>

#if defined(OF_APPLE_RUNTIME) || defined(OF_GNU_RUNTIME)
# import <objc/runtime.h>
#endif

#ifdef OF_OLD_GNU_RUNTIME
# import <objc/objc-api.h>
# define sel_getName(x) sel_get_name(x)
#endif

#ifndef _WIN32
# include <errno.h>
# define GET_ERRNO	errno
# ifndef HAVE_THREADSAFE_GETADDRINFO
#  define GET_AT_ERRNO	h_errno
# else
#  define GET_AT_ERRNO	errno
# endif
# define GET_SOCK_ERRNO	errno
# define ERRFMT		"Error string was: %s"
# define ERRPARAM	strerror(errNo)
# if !defined(HAVE_THREADSAFE_GETADDRINFO) && !defined(_PSP)
#  define AT_ERRPARAM	hstrerror(errNo)
# else
#  define AT_ERRPARAM	strerror(errNo)
# endif
#else
# include <windows.h>
# define GET_ERRNO	GetLastError()
# define GET_AT_ERRNO	WSAGetLastError()
# define GET_SOCK_ERRNO	WSAGetLastError()
# define ERRFMT		"Error code was: %d"
# define ERRPARAM	errNo
# define AT_ERRPARAM	errNo
#endif
